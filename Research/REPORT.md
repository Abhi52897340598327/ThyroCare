# Exploratory NHANES feasibility report

Evaluation completed 2026-10-23. **Research only. No clinical prediction is released.**

## Sources and task

`data-manifest.json` records all 36 requested CDC XPT files, all 36 codebooks and the UCI ZIP, with source URLs, byte counts and SHA-256 checksums. These are three independent cross-sectional NHANES cycles, not repeated patients over time. UCI was downloaded but not pooled or trained; its overlap/licensing/task review remains pending.

The fixed analysis plan predicts natural-log TSH, Free T3 (pg/mL) and Free T4 (ng/dL) concurrently measured in adult NHANES participants. Features are separate dietary quantities, age, recorded sex code and measured BMI. No race correction, future observation, diagnosis derived from an outcome, serum vitamin D substitution or normalized “hormone percentage” enters the pipeline.

The original R implementation averaged dietary arrays by row position, mixed physical units, standardized before evaluation and exported normalized coefficients. It also used a nutrient-column construction that did not match total-fat column names. The old exporter is retired. The replacement joins both days by SEQN within cycle, uses reliable dietary recall flags, retains physical units, and fits imputation and scaling within development folds.

## Locked evaluation

Adults ≥18; reliable day-one dietary recall; positive available TSH, Free T3 and Free T4. No trimming to favorable hormone ranges. The cohort flow is 11,638 merged thyroid records → 10,038 adults → 9,443 reliable recalls → 8,746 participants with all three measured outcomes. A seeded patient split assigned 6,996 development and 1,750 test participants (80/20, rounded to whole participants). Membership was written before fitting and its hash recorded.

Five development folds selected among four predeclared ridge penalties using equally weighted standardized outcome MSE. Fold-local medians and scaling prevented preprocessing leakage. The selected pipeline was fitted to development participants and evaluated once on the locked test set. The script refuses to overwrite `evaluation.json`; re-reading results is not permission to tune against that set. Parsing/read-only-array fixes occurred before the split/test evaluation completed.

| Outcome | Held-out R² | MAE | RMSE |
| --- | --- | --- | --- |
| log TSH | 0.02377 | 0.52283 log units | 0.73678 log units |
| Free T3 | 0.21602 | 0.25508 pg/mL | 0.34489 pg/mL |
| Free T4 | 0.00873 | 0.11065 ng/dL | 0.15228 ng/dL |

Equally weighted mean R²: **0.08284**. The 0.85 ambition was not met. R² is not accuracy or a percentage of correctly assessed patients. `evaluation.json` additionally includes raw-unit errors, the training-mean baseline, missingness, fixed bootstrap percentile intervals, dependency versions, CV scores and cohort counts. `baseline-pipeline.json` preserves complete preprocessing, intercepts and coefficients; it is not consumed by either app or server.

## Limitations and gates

This is an **unweighted predictive feasibility benchmark**, not survey-aware population inference. The cycle thyroid codebooks specify examination-weight context; dietary recall has its own joint-sample restrictions. The correct joint dietary/thyroid weighting, strata/PSU handling and combined-cycle inference require a survey-methods review. Invalid weights are never replaced with 1 in this pipeline because no population-weighted claim is made.

The bootstrap describes unweighted test-sample variability, not a calibrated individual clinical confidence interval. Medication, pregnancy, disease, assay and site/cycle subgroup validation, learning curves, temporal/external validation, error tolerances, clinical review and prospective evaluation are missing. The cohort includes clinical contexts that have not been adjudicated; it is not an intended-use population definition.

The 2009–2010 and 2011–2012 thyroid codebooks discuss total T4 laboratory/calibration differences. Total T4 is not substituted for Free T4 here. Archived codebooks retain the exact source material for review.

No suitable longitudinal daily-symptom/weekly-check-in/lab/treatment dataset was established. A consented clinical/research cohort and appropriate permissions are still required. These data cannot validate one-meal hormone changes, personalized dose selection or symptom-derived daily hormone ground truth.

## Reproduction

Install the Python/numpy/pandas versions listed in `evaluation.json`. Run `Scripts/fetch_research_data.py`; it checks signatures and creates the source manifest. A fresh audit checkout with the frozen inputs and analysis plan can reproduce `Scripts/evaluate_nhanes_baseline.py`. Do not delete the committed evaluation simply to search for a higher score. Check the split membership hash and full pipeline before comparing results.
