library(foreign)
library(optmatch)

read_nhanes <- function() {
  demo <- read.xport("DEMO_D.XPT")[, c("SEQN", "RIDAGEYR", "RIAGENDR", "RIDRETH1", "DMDEDUC2")]
  smq <- read.xport("SMQ_D.XPT")[, c("SEQN", "SMQ020", "SMQ040", "SMD070")]
  cot <- read.xport("COT_D.XPT")
  hcy <- read.xport("HCY_D.XPT")

  names(cot) <- c("SEQN", "Cot")
  names(hcy) <- c("SEQN", "Hcy")

  Reduce(function(x, y) merge(x, y, by = "SEQN", all.x = TRUE), list(demo, smq, cot, hcy))
}

prepare_analysis_data <- function(df) {
  df$smoker <- df$SMQ020 == 1 & df$SMQ040 == 1
  df$nonsmoker <- df$SMQ020 == 2

  keep <- with(
    df,
    RIDAGEYR >= 20 &
      (smoker | nonsmoker) &
      !is.na(Cot) &
      !is.na(Hcy) &
      !is.na(DMDEDUC2) &
      DMDEDUC2 <= 5
  )

  out <- df[keep, ]
  out$treat <- as.integer(out$smoker)
  out$smoking_status <- ifelse(out$treat == 1, "Daily smoker", "Nonsmoker")
  out$Agegp <- cut(
    out$RIDAGEYR,
    breaks = c(20, 30, 40, 50, 60, 70, 80, Inf),
    right = FALSE,
    labels = c("20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80+")
  )
  out$Sexn <- factor(out$RIAGENDR, levels = c(1, 2), labels = c("Male", "Female"))
  out$Racegp <- factor(
    ifelse(
      out$RIDRETH1 %in% c(1, 2), "Hispanic",
      ifelse(out$RIDRETH1 == 4, "Black", "White.Other")
    ),
    levels = c("White.Other", "Hispanic", "Black")
  )
  out$Edugp <- factor(
    out$DMDEDUC2,
    levels = 1:5,
    labels = c("LessThan9th", "9thTo11th", "HSorGED", "SomeCollege", "CollegeGrad")
  )
  out
}

weighted_mean <- function(x, w) {
  sum(x * w) / sum(w)
}

weighted_var <- function(x, w) {
  mu <- weighted_mean(x, w)
  sum(w * (x - mu)^2) / sum(w)
}

smd_continuous_weighted <- function(x_t, w_t, x_c, w_c) {
  (weighted_mean(x_t, w_t) - weighted_mean(x_c, w_c)) /
    sqrt((weighted_var(x_t, w_t) + weighted_var(x_c, w_c)) / 2)
}

smd_binary_weighted <- function(x_t, w_t, x_c, w_c) {
  p_t <- weighted_mean(as.numeric(x_t), w_t)
  p_c <- weighted_mean(as.numeric(x_c), w_c)
  denom <- sqrt((p_t * (1 - p_t) + p_c * (1 - p_c)) / 2)
  if (denom == 0 || is.na(denom)) {
    return(0)
  }
  (p_t - p_c) / denom
}

build_balance_table <- function(treated, control, method_name) {
  rows <- list(
    data.frame(
      method = method_name,
      variable = "Age",
      level = "mean",
      smd = smd_continuous_weighted(treated$RIDAGEYR, treated$weight, control$RIDAGEYR, control$weight)
    ),
    data.frame(
      method = method_name,
      variable = "Cotinine",
      level = "mean",
      smd = smd_continuous_weighted(treated$Cot, treated$weight, control$Cot, control$weight)
    )
  )

  for (var in c("Agegp", "Sexn", "Racegp", "Edugp")) {
    for (lev in levels(treated[[var]])) {
      rows[[length(rows) + 1]] <- data.frame(
        method = method_name,
        variable = var,
        level = lev,
        smd = smd_binary_weighted(treated[[var]] == lev, treated$weight, control[[var]] == lev, control$weight)
      )
    }
  }

  do.call(rbind, rows)
}

exact_matching <- function(df) {
  working <- df
  working$strata_id <- interaction(working$Agegp, working$Sexn, working$Racegp, working$Edugp, drop = TRUE)

  strata_counts <- aggregate(
    list(treated_n = working$treat, control_n = 1 - working$treat),
    by = list(strata_id = working$strata_id),
    FUN = sum
  )
  common_strata <- strata_counts$strata_id[strata_counts$treated_n > 0 & strata_counts$control_n > 0]
  working <- working[working$strata_id %in% common_strata, ]

  treated <- working[working$treat == 1, ]
  control <- working[working$treat == 0, ]
  treated$weight <- 1

  strata_info <- strata_counts[strata_counts$strata_id %in% common_strata, ]
  rownames(strata_info) <- as.character(strata_info$strata_id)
  control$weight <- strata_info[as.character(control$strata_id), "treated_n"] /
    strata_info[as.character(control$strata_id), "control_n"]

  control_means <- tapply(control$Hcy * control$weight, control$strata_id, sum) /
    tapply(control$weight, control$strata_id, sum)
  treated$matched_control_hcy <- control_means[as.character(treated$strata_id)]
  treated$delta <- treated$Hcy - treated$matched_control_hcy

  list(
    method = "Exact matching",
    treated = treated,
    control = control,
    matched_pairs = nrow(treated),
    delta = treated$delta,
    caliper = NA
  )
}

ratio_matching <- function(df, ratio = 2) {
  working <- df
  ps_model <- glm(treat ~ Agegp + Sexn + Racegp + Edugp + RIDAGEYR, data = working, family = binomial())
  working$score <- predict(ps_model, type = "link")
  working$strata_id <- interaction(working$Agegp, working$Sexn, working$Racegp, drop = TRUE)
  caliper <- 0.2 * sd(working$score)

  treated_idx <- which(working$treat == 1)
  used_controls <- rep(FALSE, nrow(working))
  pair_rows <- list()
  k <- 0L

  for (ti in treated_idx[order(working$score[treated_idx], decreasing = TRUE)]) {
    candidates <- which(working$treat == 0 & !used_controls & working$strata_id == working$strata_id[ti])
    if (!length(candidates)) {
      next
    }

    distances <- abs(working$score[candidates] - working$score[ti])
    within <- candidates[distances <= caliper]
    if (!length(within)) {
      next
    }

    ordered <- within[order(abs(working$score[within] - working$score[ti]))]
    chosen <- head(ordered, ratio)
    used_controls[chosen] <- TRUE

    k <- k + 1L
    pair_rows[[k]] <- data.frame(
      pair_id = k,
      treated_row = ti,
      control_row = chosen
    )
  }

  matches <- do.call(rbind, pair_rows)
  treated <- working[matches$treated_row[!duplicated(matches$pair_id)], ]
  control <- working[matches$control_row, ]

  treated$pair_id <- seq_len(nrow(treated))
  treated$weight <- 1
  control$pair_id <- matches$pair_id
  control$weight <- 1

  control_means <- tapply(control$Hcy, control$pair_id, mean)
  treated$matched_control_hcy <- control_means[as.character(treated$pair_id)]
  treated$delta <- treated$Hcy - treated$matched_control_hcy

  list(
    method = "1:2 matching",
    treated = treated,
    control = control,
    matched_pairs = nrow(treated),
    delta = treated$delta,
    caliper = caliper
  )
}

propensity_matching <- function(df) {
  working <- df
  ps_model <- glm(treat ~ Agegp + Sexn + Racegp + Edugp + RIDAGEYR, data = working, family = binomial())
  working$score <- predict(ps_model, type = "link")
  caliper <- 0.2 * sd(working$score)

  treated_idx <- which(working$treat == 1)
  used_controls <- rep(FALSE, nrow(working))
  pair_store <- vector("list", length(treated_idx))
  pair_count <- 0L

  for (ti in treated_idx[order(working$score[treated_idx], decreasing = TRUE)]) {
    candidates <- which(working$treat == 0 & !used_controls)
    if (!length(candidates)) {
      next
    }

    distances <- abs(working$score[candidates] - working$score[ti])
    best <- which.min(distances)
    if (distances[best] <= caliper) {
      ci <- candidates[best]
      used_controls[ci] <- TRUE
      pair_count <- pair_count + 1L
      pair_store[[pair_count]] <- c(ti, ci)
    }
  }

  matches <- do.call(rbind, pair_store[seq_len(pair_count)])
  colnames(matches) <- c("treated_row", "control_row")

  treated <- working[matches[, "treated_row"], ]
  control <- working[matches[, "control_row"], ]
  treated$pair_id <- seq_len(nrow(treated))
  control$pair_id <- seq_len(nrow(control))
  treated$weight <- 1
  control$weight <- 1
  treated$matched_control_hcy <- control$Hcy
  treated$delta <- treated$Hcy - control$Hcy

  list(
    method = "Propensity score matching",
    treated = treated,
    control = control,
    matched_pairs = nrow(treated),
    delta = treated$delta,
    caliper = caliper
  )
}

mahalanobis_matching <- function(df) {
  working <- df
  mm_data <- model.matrix(~ RIDAGEYR + Sexn + Racegp + Edugp, data = working)[, -1, drop = FALSE]
  cov_inv <- solve(stats::cov(mm_data))

  treated_idx <- which(working$treat == 1)
  control_idx <- which(working$treat == 0)
  used_controls <- rep(FALSE, length(control_idx))
  pair_store <- vector("list", length(treated_idx))
  pair_count <- 0L

  for (ti in treated_idx) {
    available <- which(!used_controls)
    if (!length(available)) {
      next
    }

    candidates <- control_idx[available]
    diffs <- sweep(mm_data[candidates, , drop = FALSE], 2, mm_data[ti, ], FUN = "-")
    distances <- rowSums((diffs %*% cov_inv) * diffs)
    best <- which.min(distances)
    ci <- candidates[best]

    used_controls[available[best]] <- TRUE
    pair_count <- pair_count + 1L
    pair_store[[pair_count]] <- c(ti, ci)
  }

  matches <- do.call(rbind, pair_store[seq_len(pair_count)])
  colnames(matches) <- c("treated_row", "control_row")

  treated <- working[matches[, "treated_row"], ]
  control <- working[matches[, "control_row"], ]
  treated$pair_id <- seq_len(nrow(treated))
  control$pair_id <- seq_len(nrow(control))
  treated$weight <- 1
  control$weight <- 1
  treated$matched_control_hcy <- control$Hcy
  treated$delta <- treated$Hcy - control$Hcy

  list(
    method = "Mahalanobis matching",
    treated = treated,
    control = control,
    matched_pairs = nrow(treated),
    delta = treated$delta,
    caliper = NA
  )
}

full_matching <- function(df) {
  working <- df
  ps <- glm(treat ~ Agegp + Sexn + Racegp + Edugp + RIDAGEYR, data = working, family = binomial())
  ps_logit <- predict(ps, type = "link")
  distance <- match_on(treat ~ ps_logit, data = working)
  matched_sets <- fullmatch(distance, data = working)

  working <- working[!is.na(matched_sets), ]
  working$set_id <- matched_sets[!is.na(matched_sets)]

  treated <- working[working$treat == 1, ]
  control <- working[working$treat == 0, ]
  treated$weight <- 1

  set_counts <- aggregate(
    list(treated_n = working$treat, control_n = 1 - working$treat),
    by = list(set_id = working$set_id),
    FUN = sum
  )
  rownames(set_counts) <- as.character(set_counts$set_id)
  control$weight <- set_counts[as.character(control$set_id), "treated_n"] /
    set_counts[as.character(control$set_id), "control_n"]

  control_means <- tapply(control$Hcy * control$weight, control$set_id, sum) /
    tapply(control$weight, control$set_id, sum)
  treated$matched_control_hcy <- control_means[as.character(treated$set_id)]
  treated$delta <- treated$Hcy - treated$matched_control_hcy

  list(
    method = "Full matching",
    treated = treated,
    control = control,
    matched_pairs = nrow(treated),
    delta = treated$delta,
    caliper = NA
  )
}

summarize_method <- function(method_fit) {
  delta_test <- t.test(method_fit$delta)
  balance <- build_balance_table(method_fit$treated, method_fit$control, method_fit$method)

  data.frame(
    method = method_fit$method,
    treated_kept = nrow(method_fit$treated),
    control_units = nrow(method_fit$control),
    mean_hcy_smokers = weighted_mean(method_fit$treated$Hcy, method_fit$treated$weight),
    mean_hcy_controls = weighted_mean(method_fit$control$Hcy, method_fit$control$weight),
    att_hcy_difference = mean(method_fit$delta),
    att_ci_lower = unname(delta_test$conf.int[1]),
    att_ci_upper = unname(delta_test$conf.int[2]),
    paired_t_pvalue = delta_test$p.value,
    age_smd = subset(balance, variable == "Age")$smd,
    education_max_abs_smd = max(abs(subset(balance, variable == "Edugp")$smd)),
    caliper = method_fit$caliper
  )
}

write_outputs <- function(df, results) {
  if (!dir.exists("outputs")) {
    dir.create("outputs")
  }

  analytic <- df[, c(
    "SEQN", "smoking_status", "treat", "RIDAGEYR", "Agegp", "Sexn",
    "Racegp", "Edugp", "Cot", "Hcy", "SMD070"
  )]
  names(analytic) <- c(
    "SEQN", "smoking_status", "treat", "age", "age_group", "sex",
    "race_group", "education_group", "cotinine", "homocysteine", "cigs_per_day"
  )
  write.csv(analytic, "outputs/analytic_dataset.csv", row.names = FALSE)

  unmatched <- data.frame(
    method = "Unmatched",
    treated_kept = sum(df$treat == 1),
    control_units = sum(df$treat == 0),
    mean_hcy_smokers = mean(df$Hcy[df$treat == 1]),
    mean_hcy_controls = mean(df$Hcy[df$treat == 0]),
    att_hcy_difference = mean(df$Hcy[df$treat == 1]) - mean(df$Hcy[df$treat == 0]),
    att_ci_lower = NA,
    att_ci_upper = NA,
    paired_t_pvalue = NA,
    age_smd = smd_continuous_weighted(df$RIDAGEYR[df$treat == 1], rep(1, sum(df$treat == 1)), df$RIDAGEYR[df$treat == 0], rep(1, sum(df$treat == 0))),
    education_max_abs_smd = {
      treated <- df[df$treat == 1, ]
      control <- df[df$treat == 0, ]
      treated$weight <- 1
      control$weight <- 1
      max(abs(subset(build_balance_table(treated, control, "Unmatched"), variable == "Edugp")$smd))
    },
    caliper = NA
  )

  summaries <- do.call(rbind, lapply(results, summarize_method))
  write.csv(rbind(unmatched, summaries), "outputs/method_comparison_summary.csv", row.names = FALSE)

  balance <- do.call(rbind, lapply(results, function(x) build_balance_table(x$treated, x$control, x$method)))
  write.csv(balance, "outputs/method_balance.csv", row.names = FALSE)
}

main <- function() {
  raw <- read_nhanes()
  analytic <- prepare_analysis_data(raw)

  results <- list(
    exact_matching(analytic),
    ratio_matching(analytic, ratio = 2),
    propensity_matching(analytic),
    mahalanobis_matching(analytic),
    full_matching(analytic)
  )

  write_outputs(analytic, results)

  comparison <- read.csv("outputs/method_comparison_summary.csv")
  cat("Analytic sample:", nrow(analytic), "\n")
  print(comparison[, c("method", "treated_kept", "control_units", "att_hcy_difference", "age_smd", "education_max_abs_smd")], row.names = FALSE)
}

main()
