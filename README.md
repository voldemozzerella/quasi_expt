# Quasi Experiment Project

This repository contains a group project for a causal inference course using NHANES 2005-2006 data. The project studies the effect of daily smoking on homocysteine using several matching-based observational designs.

## Main Files

- [PROJECT1_REPORT.md](/Users/pustijesrani/quasi_expt/PROJECT1_REPORT.md:1): final project report
- [CONTRIBUTIONS.md](/Users/pustijesrani/quasi_expt/CONTRIBUTIONS.md:1): team contribution statement
- [project1_matching_analysis.R](/Users/pustijesrani/quasi_expt/project1_matching_analysis.R:1): reproducible analysis script
- [project1_NHANES_data_preparation.R](/Users/pustijesrani/quasi_expt/project1_NHANES_data_preparation.R:1): original template provided for data preparation

## Data Files

The raw NHANES files used in the project are:

- `DEMO_D.XPT`: demographics and confounders
- `SMQ_D.XPT`: smoking questionnaire data
- `HCY_D.XPT`: homocysteine outcome
- `COT_D.XPT`: cotinine biomarker

## Matching Methods Compared

The report and script compare:

- exact matching
- `1:2` matching
- propensity score matching
- Mahalanobis matching
- full matching

## Generated Outputs

The analysis script writes outputs to [outputs](/Users/pustijesrani/quasi_expt/outputs):

- [outputs/analytic_dataset.csv](/Users/pustijesrani/quasi_expt/outputs/analytic_dataset.csv): cleaned analytic dataset
- [outputs/method_comparison_summary.csv](/Users/pustijesrani/quasi_expt/outputs/method_comparison_summary.csv): main comparison table across matching methods
- [outputs/method_balance.csv](/Users/pustijesrani/quasi_expt/outputs/method_balance.csv): covariate balance table
- [outputs/method_pairs.csv](/Users/pustijesrani/quasi_expt/outputs/method_pairs.csv): matched units by method

Some older output files remain in `outputs/` from earlier intermediate versions of the analysis, but the main project uses the method-level files listed above.

## How To Rerun

From the repository root, run:

```bash
Rscript project1_matching_analysis.R
```

This will rebuild the main output tables in `outputs/`.

## Submission-Ready Files

For submission, the key files are:

- `PROJECT1_REPORT.md`
- `CONTRIBUTIONS.md`
- `project1_matching_analysis.R`
- `outputs/method_comparison_summary.csv`
- `outputs/method_balance.csv`
