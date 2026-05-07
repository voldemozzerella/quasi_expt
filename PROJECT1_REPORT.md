# Project 1: Matching as Design

## Project Summary

In this project, we study whether daily smokers have higher homocysteine levels than comparable nonsmokers in NHANES 2005-2006. Because this is an observational dataset rather than a randomized experiment, we use matching to create fairer treatment-control comparisons. We compare five matching designs and evaluate them based on sample retention, covariate balance, and the estimated treatment effect.

## Dataset Required

> We use the NHANES 2005-2006 `DEMO_D`, `SMQ_D`, `HCY_D`, and `COT_D` files to study the effect of smoking on homocysteine. `DEMO_D` provides the adjustment covariates, `SMQ_D` defines smoking status, `HCY_D` contains the outcome, and `COT_D` provides a biomarker check on exposure.

## Research Question

We estimate the effect of smoking on homocysteine level using several matched observational designs built from NHANES 2005-2006, then compare how the estimated effect changes across methods.

## Variable Choices

Exposure:

- Daily smoker: `SMQ020 == 1` and `SMQ040 == 1`
- Nonsmoker: `SMQ020 == 2`

Outcome:

- Homocysteine: `LBXHCY`

Covariates used to address confounding:

- Age: `RIDAGEYR`
- Sex: `RIAGENDR`
- Race/ethnicity: `RIDRETH1`
- Education: `DMDEDUC2`

Biomarker check:

- Cotinine: `LBXCOT`

Reasoning:

- Age, sex, race/ethnicity, and education are plausible common causes of both smoking behavior and homocysteine level.
- Cotinine should not be matched on because it is a direct biomarker of smoking exposure rather than a pre-treatment confounder.

## Analytic Sample

Inclusion criteria:

- Age 20 or older
- Classified as either daily smoker or nonsmoker
- Non-missing cotinine
- Non-missing homocysteine
- Non-missing education with valid adult education code (`DMDEDUC2 <= 5`)

Resulting sample:

- 3,168 adults
- 821 daily smokers
- 2,347 nonsmokers

## Matching Design

Our goal is to compare several standard observational designs from the syllabus and see how the estimated smoking effect changes when the design changes.

Designs compared:

- Exact matching on age group, sex, race/ethnicity, and education
- `1:2` matching within age group, sex, and race strata using a propensity score distance
- `1:1` propensity score matching without exact strata
- `1:1` Mahalanobis distance matching
- Full matching using propensity score distance

The common confounder set is age, sex, race/ethnicity, and education. Cotinine is not used for matching because it is a biomarker of smoking exposure, not a pre-treatment covariate.

## Main Results

Unmatched means:

- Smokers: 9.294 umol/L
- Nonsmokers: 7.935 umol/L
- Raw difference: 1.359 umol/L

The full comparison table is in [outputs/method_comparison_summary.csv](/Users/pustijesrani/quasi_expt/outputs/method_comparison_summary.csv), and the detailed balance table is in [outputs/method_balance.csv](/Users/pustijesrani/quasi_expt/outputs/method_balance.csv).

### Exact matching

Observed outcome:

- 797 smokers retained
- 2,044 controls used
- Estimated ATT: 1.076 umol/L
- 95% CI: 0.600 to 1.552
- Age SMD: -0.008
- Maximum education SMD: essentially 0

What it is doing:

- It only compares smokers and nonsmokers who are exactly identical on age group, sex, race/ethnicity, and education.

Pros observed in this study:

- Best balance on the covariates we chose as confounders
- Keeps most smokers in the analysis
- Very easy to explain in class because the comparison is transparent

Cons observed in this study:

- Drops 24 smokers who do not have comparable exact matches
- Can become too restrictive if more covariates are added

### `1:2` matching

Observed outcome:

- 566 smokers retained
- 1,106 controls used
- Estimated ATT: 0.900 umol/L
- 95% CI: 0.457 to 1.343
- Age SMD: -0.039
- Maximum education SMD: 0.134

What it is doing:

- It tries to give each smoker up to two comparable nonsmokers, using propensity score distance within age group, sex, and race strata.

Pros observed in this study:

- Uses more than one control per treated person
- Produces a smaller estimated effect than the unmatched comparison
- Good compromise if the goal is to stabilize estimates with multiple controls

Cons observed in this study:

- Keeps far fewer smokers than the other main designs
- Leaves the most education imbalance among the matched methods
- Not as strong as exact matching in this dataset

### Propensity score matching

Observed outcome:

- 795 smokers retained
- 795 controls used
- Estimated ATT: 1.103 umol/L
- 95% CI: 0.595 to 1.611
- Age SMD: -0.046
- Maximum education SMD: 0.082

What it is doing:

- It summarizes the observed confounders into one propensity score and matches smokers to nonsmokers with similar estimated treatment probabilities.

Pros observed in this study:

- Keeps almost as many smokers as exact matching
- Balance is clearly better than in the unmatched data
- Standard method that fits Weeks 6-7 very well

Cons observed in this study:

- Covariate balance is weaker than exact matching
- Because there is no exact demographic structure imposed, the matched sample is less transparent

### Mahalanobis matching

Observed outcome:

- 821 smokers retained
- 821 controls used
- Estimated ATT: 0.822 umol/L
- 95% CI: 0.252 to 1.393
- Age SMD: -0.129
- Maximum education SMD: 0

What it is doing:

- It matches on overall multivariate covariate distance rather than on the propensity score.

Pros observed in this study:

- Keeps all smokers
- Matches education extremely well
- Gives one of the smaller treatment estimates

Cons observed in this study:

- Age balance is clearly worse than the other designs
- Since age is an important confounder here, that is a serious weakness
- For this project, the weaker age balance makes the method harder to defend as the primary design

### Full matching

Observed outcome:

- 821 smokers retained
- 2,347 controls used
- Estimated ATT: 1.160 umol/L
- 95% CI: 0.693 to 1.626
- Age SMD: -0.046
- Maximum education SMD: 0.060

What it is doing:

- It forms matched sets that may contain one treated with several controls or several treated with one control, instead of forcing only pairs.

Pros observed in this study:

- Uses the full analytic sample
- Balance is fairly good across the observed covariates
- Strong option when sample retention matters

Cons observed in this study:

- Harder to explain than exact matching
- Not as cleanly balanced as exact matching
- The estimate stays relatively close to the unmatched difference

### Overall comparison

- The raw unmatched difference is 1.359 umol/L
- Every matched design reduces that difference
- Exact matching gives the cleanest overall balance while still keeping 797 of 821 smokers
- Full matching is the best sample-retention design because it keeps everyone and still improves balance
- Propensity score matching is a reasonable middle-ground method
- Mahalanobis matching is not preferred here because age balance remains too weak
- `1:2` matching is also not preferred here because it drops too many smokers and leaves more education imbalance

Our main recommendation:

- Use exact matching as the primary design for the report and presentation
- Use full matching and propensity score matching as robustness checks
- Mention Mahalanobis and `1:2` matching as useful alternatives that were less convincing in this particular dataset

Exposure validation with cotinine:

- Matched smokers: 238.893 ng/mL
- Matched controls remain much lower than smokers across all matching methods

Interpretation:

- After matching comparable adults on key background characteristics, daily smokers still have higher homocysteine on average than matched nonsmokers.
- The estimated effect is smaller than the raw difference across every matching design, which is consistent with confounding in the unmatched comparison.
- The exact size of the estimated smoking effect depends on the design, which is exactly the lesson the syllabus is aiming to teach about observational causal inference.

## Conclusion

Our overall conclusion is that smoking is associated with higher homocysteine levels in this adult NHANES sample, even after constructing matched comparisons between smokers and nonsmokers. Among the designs we implemented, exact matching is the strongest primary design for this project because it gives the cleanest observed covariate balance while still retaining most smokers. Full matching and propensity score matching support the same qualitative conclusion and are useful robustness checks.

## Deliverables in This Folder

- [project1_matching_analysis.R](/Users/pustijesrani/quasi_expt/project1_matching_analysis.R)
- [outputs/analytic_dataset.csv](/Users/pustijesrani/quasi_expt/outputs/analytic_dataset.csv)
- [outputs/method_comparison_summary.csv](/Users/pustijesrani/quasi_expt/outputs/method_comparison_summary.csv)
- [outputs/method_balance.csv](/Users/pustijesrani/quasi_expt/outputs/method_balance.csv)

## Limits

- This is still an observational design, so unmeasured confounding may remain.
- The smoking definition is strict: daily smokers versus lifetime nonsmokers.
- Different matching rules can produce somewhat different estimates, which is exactly why comparing methods is useful.
- NHANES survey weights were not incorporated in this matching exercise because the project is framed as a matching design assignment rather than a survey-weighted causal analysis.
