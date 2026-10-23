#!/usr/bin/env Rscript
# The original fitted-data coefficient export is retired, not a deployable hormone model.
# Historical source remains in Git for reproducibility of the audit.
stop(paste(
  "Retired: this script used row-position dietary averaging, mixed-unit composites,",
  "pre-split scaling and fitted-data statistics. It must not generate serving weights.",
  "Use Scripts/fetch_research_data.py and Scripts/evaluate_nhanes_baseline.py.",
  "The replacement is a locked, research-only prediction benchmark, not a clinical model."
))
