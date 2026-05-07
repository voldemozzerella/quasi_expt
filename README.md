# Quasi Experiment Project

This repository contains a group project for a causal inference course. We use NHANES 2005-2006 data to study whether daily smokers have higher homocysteine levels than comparable nonsmokers. Since the dataset is observational rather than randomized, we use matching-based designs to create fairer treatment-control comparisons.

## Project Summary

The main goal of this project is to estimate the association between daily smoking and homocysteine levels after adjusting for observed background differences between smokers and nonsmokers.

We compare several matching designs and evaluate them based on:

- sample retention
- covariate balance
- estimated treatment effect
- interpretability of the design

The project emphasizes the course idea that observational causal conclusions depend heavily on the design used to construct comparable treated and control groups.

## Research Question

Do daily smokers have higher homocysteine levels than comparable nonsmokers in NHANES 2005-2006?

## Dataset

We use four NHANES 2005-2006 files:

- `DEMO_D.XPT`: demographics and adjustment covariates
- `SMQ_D.XPT`: smoking questionnaire data
- `HCY_D.XPT`: homocysteine outcome
- `COT_D.XPT`: cotinine biomarker

## Variables

### Exposure

Daily smoker:

- `SMQ020 == 1`
- `SMQ040 == 1`

Nonsmoker:

- `SMQ020 == 2`

### Outcome

- Homocysteine level: `LBXHCY`

### Covariates Used for Matching

- Age: `RIDAGEYR`
- Sex: `RIAGENDR`
- Race/ethnicity: `RIDRETH1`
- Education: `DMDEDUC2`

### Biomarker Check

- Cotinine: `LBXCOT`

Cotinine is used as an exposure validation check, but it is not used for matching because it is a biomarker of smoking exposure rather than a pre-treatment confounder.

## Analytic Sample

The analytic sample includes adults who meet the following criteria:

- age 20 or older
- classified as either daily smoker or nonsmoker
- non-missing homocysteine
- non-missing cotinine
- valid adult education code

Final analytic sample:

- 3,168 adults
- 821 daily smokers
- 2,347 nonsmokers

## Matching Methods Compared

The analysis compares five matching-based observational designs:

1. Exact matching on age group, sex, race/ethnicity, and education
2. `1:2` propensity score matching within age group, sex, and race strata
3. `1:1` propensity score matching
4. `1:1` Mahalanobis distance matching
5. Full matching using propensity score distance

## Main Findings

The unmatched difference in mean homocysteine was:

- Smokers: 9.294 umol/L
- Nonsmokers: 7.935 umol/L
- Raw difference: 1.359 umol/L

Across all matched designs, the estimated smoking effect was smaller than the unmatched difference. This suggests that part of the raw difference was due to imbalance in observed covariates.

The exact matching design gave the cleanest observed covariate balance while still retaining most smokers. Full matching retained the full analytic sample and served as a useful robustness check. Propensity score matching also supported the same qualitative conclusion.

Overall, the results suggest that daily smoking is associated with higher homocysteine levels among comparable adults in this NHANES sample.

## Repository Structure

```text
.
├── README.md
├── PROJECT1_REPORT.md
├── CONTRIBUTIONS.md
├── project1_matching_analysis.R
├── project1_NHANES_data_preparation.R
├── DEMO_D.XPT
├── SMQ_D.XPT
├── HCY_D.XPT
├── COT_D.XPT
└── outputs/
    ├── analytic_dataset.csv
    ├── method_comparison_summary.csv
    ├── method_balance.csv
    └── method_pairs.csv
```

## Main Files

- [PROJECT1_REPORT.md](PROJECT1_REPORT.md): final project report
- [CONTRIBUTIONS.md](CONTRIBUTIONS.md): team contribution statement
- [project1_matching_analysis.R](project1_matching_analysis.R): main reproducible analysis script
- [project1_NHANES_data_preparation.R](project1_NHANES_data_preparation.R): original data preparation template

## Generated Outputs

The main analysis outputs are stored in the [outputs](outputs) folder:

- [outputs/analytic_dataset.csv](outputs/analytic_dataset.csv): cleaned analytic dataset
- [outputs/method_comparison_summary.csv](outputs/method_comparison_summary.csv): comparison table across matching methods
- [outputs/method_balance.csv](outputs/method_balance.csv): covariate balance table
- [outputs/method_pairs.csv](outputs/method_pairs.csv): matched units by method

Some older output files may remain in the `outputs/` folder from intermediate versions of the analysis, but the main project uses the method-level files listed above.

## How to Rerun the Analysis

From the repository root, run:

```bash
Rscript project1_matching_analysis.R
```

This will rebuild the main output tables in the `outputs/` folder.

## Submission-Ready Files

The key files for submission are:

- [PROJECT1_REPORT.md](PROJECT1_REPORT.md)
- [CONTRIBUTIONS.md](CONTRIBUTIONS.md)
- [project1_matching_analysis.R](project1_matching_analysis.R)
- [outputs/method_comparison_summary.csv](outputs/method_comparison_summary.csv)
- [outputs/method_balance.csv](outputs/method_balance.csv)

## Limitations

This project is still based on observational data, so unmeasured confounding may remain even after matching. The smoking definition is strict because it compares daily smokers to nonsmokers. Different matching rules also produce somewhat different estimates, which is why comparing multiple designs is important. NHANES survey weights were not incorporated because the project is framed as a matching design exercise rather than a survey-weighted causal analysis.

## Team Contributions

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for the full team contribution statement.