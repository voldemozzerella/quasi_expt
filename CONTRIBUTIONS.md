# Contributions

## Project Context

This project fits the course sequence on observational causal inference, especially:

- Week 5: historical perspective on observational studies and matching as design
- Weeks 6-7: ignorability of treatment assignment, propensity score, and covariate adjustment
- Weeks 9-10: limits of causal inference under possible unmeasured confounding

Our NHANES project studies the effect of smoking on homocysteine using a matched observational design.

## Team Division

The work is divided evenly across Anushka, Pusti, and Hyunbin. Each person took primary responsibility for one third of the project workflow: research design, data and implementation, and results interpretation and writing. All three team members also participated in reviewing the final submission.

## Individual Contributions

### Anushka

- Led the research design portion of the project.
- Framed the causal question and aligned the project to the Week 5 matching-as-design topic in the syllabus.
- Selected the treatment, outcome, and confounder structure using:
  - smoking from `SMQ_D.XPT`
  - homocysteine from `HCY_D.XPT`
  - age, sex, race/ethnicity, and education from `DEMO_D.XPT`
- Helped determine that cotinine from `COT_D.XPT` should be used as an exposure validation variable rather than as a matching covariate.

### Pusti

- Led the data preparation and implementation portion of the project.
- Built the analytic dataset by merging:
  - `DEMO_D.XPT`
  - `SMQ_D.XPT`
  - `HCY_D.XPT`
  - `COT_D.XPT`
- Applied the inclusion and exclusion criteria for the adult analytic sample.
- Implemented the matching analysis in R, including exact matching, `1:2` matching, propensity score matching, Mahalanobis matching, and full matching.
- Generated the reproducible analysis script and the output summary files used in the report.

### Hyunbin

- Led the results interpretation and writing portion of the project.
- Evaluated covariate balance across the alternative matching designs and compared their treatment effect estimates.
- Interpreted the findings using the course material on ignorability, covariate adjustment, and observational study design.
- Wrote the conclusions, limitations, and method comparison discussion, including the role of possible residual unmeasured confounding.

## Shared Final Review

All three team members contributed to the final review of:

- the matching design choices
- the interpretation of the estimated smoking effect
- the written report and submission materials

## Short Version for Submission

Anushka led project design and variable selection, Pusti led data preparation and R implementation, and Hyunbin led results interpretation and report writing. The work was divided evenly across these three parts, and all three members jointly reviewed the final submission.
