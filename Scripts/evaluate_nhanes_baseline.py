#!/usr/bin/env python3
"""Auditable unweighted feasibility baseline. No deployed weights or hormone-impact percentages.
Requires numpy/pandas. Population inference remains gated on survey-methods review.
"""
import hashlib
import json
import pathlib
import platform
import sys
import numpy as np
import pandas as pd

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW = ROOT / "Research/raw"
OUT = ROOT / "Research"
PLAN = json.loads((OUT / "analysis-plan.json").read_text())
NUTRIENTS = {"KCAL": "kcal", "PROT": "g", "CARB": "g", "TFAT": "g", "FIBE": "g", "SUGR": "g", "CALC": "mg", "IRON": "mg", "SODI": "mg", "ZINC": "mg", "POTA": "mg", "SELE": "µg", "VB12": "µg", "VB6": "mg", "VC": "mg"}
TARGETS = ["LBXTSH1", "LBXT3F", "LBXT4F"]

def read(family, cycle):
    frame = pd.read_sas(RAW / f"{family}_{cycle}.xpt", format="xport")
    if frame.SEQN.duplicated().any():
        raise ValueError(f"Duplicate participant: {family}_{cycle}")
    return frame

def cycle_data(cycle):
    thyroid = read("THYROD", cycle)[["SEQN"] + TARGETS]
    demo = read("DEMO", cycle)[["SEQN", "RIDAGEYR", "RIAGENDR", "WTMEC2YR", "SDMVSTRA", "SDMVPSU"]]
    bmx = read("BMX", cycle)[["SEQN", "BMXBMI"]]
    d1, d2 = read("DR1TOT", cycle), read("DR2TOT", cycle)
    # Rows are joined by participant key before averaging. Unreliable recalls remain missing.
    days = d1.merge(d2, on="SEQN", how="left", validate="one_to_one", suffixes=("_day1", "_day2"))
    diet = pd.DataFrame({"SEQN": days.SEQN, "reliable_day1": days.DR1DRSTZ.eq(1)})
    for nutrient in NUTRIENTS:
        first = days[f"DR1T{nutrient}"].where(days.DR1DRSTZ.eq(1))
        second = days[f"DR2T{nutrient}"].where(days.DR2DRSTZ.eq(1))
        diet[nutrient] = pd.concat([first, second], axis=1).mean(axis=1, skipna=True)
    frame = thyroid.merge(demo, on="SEQN", validate="one_to_one").merge(bmx, on="SEQN", how="left", validate="one_to_one").merge(diet, on="SEQN", how="left", validate="one_to_one")
    frame["participant"] = cycle + ":" + frame.SEQN.astype(int).astype(str)
    frame["cycle"] = cycle
    return frame

def fit(x, y, alpha):
    median = np.nanmedian(x, axis=0)
    if not np.isfinite(median).all():
        raise ValueError("Entire feature missing in training fold")
    filled = np.where(np.isnan(x), median, x)
    center, scale = filled.mean(axis=0), filled.std(axis=0)
    scale[scale == 0] = 1
    matrix = np.column_stack([np.ones(len(x)), (filled-center)/scale])
    penalty = np.eye(matrix.shape[1]) * alpha
    penalty[0, 0] = 0
    coefficient = np.linalg.solve(matrix.T @ matrix + penalty, matrix.T @ y)
    return median, center, scale, coefficient

def predict(model, x):
    median, center, scale, coefficient = model
    matrix = np.column_stack([np.ones(len(x)), (np.where(np.isnan(x), median, x)-center)/scale])
    return matrix @ coefficient

def metrics(y, prediction):
    return {"r2": (1 - ((y-prediction)**2).sum(axis=0)/((y-y.mean(axis=0))**2).sum(axis=0)).tolist(), "mae": np.abs(y-prediction).mean(axis=0).tolist(), "rmse": np.sqrt(((y-prediction)**2).mean(axis=0)).tolist()}

def main():
    report_path = OUT / "evaluation.json"
    if report_path.exists():
        sys.exit("Locked test already evaluated. Read evaluation.json; do not optimize against it.")
    manifest = json.loads((OUT / "data-manifest.json").read_text())
    for item in manifest["files"]:
        if hashlib.sha256((RAW / item["file"]).read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError("Source checksum mismatch: " + item["file"])
    all_data = pd.concat([cycle_data(c) for c in "EFG"], ignore_index=True)
    adults = all_data[all_data.RIDAGEYR >= 18]
    reliable = adults[adults.reliable_day1.eq(True)]
    cohort = reliable[(reliable[TARGETS].notna() & reliable[TARGETS].gt(0)).all(axis=1)].sort_values("participant").reset_index(drop=True)
    if cohort.participant.duplicated().any(): raise ValueError("Participant leakage")
    features = list(NUTRIENTS) + ["RIDAGEYR", "RIAGENDR", "BMXBMI"]
    x = cohort[features].to_numpy(dtype=float)
    y = cohort[TARGETS].to_numpy(dtype=float, copy=True)
    y[:, 0] = np.log(y[:, 0])
    rng = np.random.default_rng(PLAN["seed"])
    shuffled = rng.permutation(len(cohort))
    cutoff = int(len(cohort) * PLAN["development_fraction"])
    dev, test = shuffled[:cutoff], shuffled[cutoff:]
    membership = {"development": cohort.iloc[dev].participant.tolist(), "test": cohort.iloc[test].participant.tolist()}
    serialized = json.dumps(membership, sort_keys=True)
    membership_path = OUT / "split-membership.json"
    if membership_path.exists() and membership_path.read_text().strip() != serialized:
        raise ValueError("Locked membership differs; do not silently recreate the split")
    membership_path.write_text(serialized + "\n")
    folds = np.array_split(dev, 5)
    cv = {}
    for alpha in PLAN["ridge_alpha_candidates"]:
        losses = []
        for held in folds:
            train = np.setdiff1d(dev, held)
            model = fit(x[train], y[train], alpha)
            errors = (predict(model, x[held])-y[held])/y[train].std(axis=0)
            losses.append(float(np.mean(errors**2)))
        cv[str(alpha)] = float(np.mean(losses))
    alpha = min(PLAN["ridge_alpha_candidates"], key=lambda a: cv[str(a)])
    model = fit(x[dev], y[dev], alpha)
    prediction = predict(model, x[test])
    baseline = np.tile(y[dev].mean(axis=0), (len(test), 1))
    scores = metrics(y[test], prediction)
    raw_y, raw_pred = y[test].copy(), prediction.copy()
    raw_y[:, 0], raw_pred[:, 0] = np.exp(raw_y[:, 0]), np.exp(raw_pred[:, 0])
    # Fixed bootstrap resamples quantify sampling variability, not a calibrated clinical interval.
    bootstrap = np.array([metrics(y[test][idx], prediction[idx])["r2"] for idx in [rng.integers(0,len(test),len(test)) for _ in range(500)]])
    report = {"plan": PLAN, "cohort_flow": {"thyroid_merged": len(all_data), "adults": len(adults), "reliable_day_one": len(reliable), "all_three_positive_measured_outcomes": len(cohort), "development": len(dev), "test": len(test)}, "outcome_order": ["log_TSH", "Free_T3_pg_mL", "Free_T4_ng_dL"], "missingness_fraction": cohort[features].isna().mean().to_dict(), "feature_units": NUTRIENTS | {"RIDAGEYR":"years", "RIAGENDR":"NHANES recorded sex code", "BMXBMI":"kg/m²"}, "split_sha256": hashlib.sha256(serialized.encode()).hexdigest(), "selected_alpha": alpha, "development_cv_standardized_mse": cv, "held_out": scores, "raw_units": metrics(raw_y,raw_pred), "training_mean_baseline": metrics(y[test],baseline), "r2_bootstrap_percentile_95": np.quantile(bootstrap,[.025,.975],axis=0).tolist(), "unweighted_mean_r2": float(np.mean(scores["r2"])), "ambition_met": bool(np.mean(scores["r2"]) >= .85), "versions": {"python": platform.python_version(), "numpy": np.__version__, "pandas": pd.__version__}, "limitations": ["Unweighted prediction benchmark, not survey population inference", "Cross-sectional samples, no individual food effects or symptom forecast", "No medication, pregnancy or disease subgroup clinical validation", "No external validation, prospective evaluation or calibrated patient intervals", "Survey-methods review of joint dietary/thyroid weighting required", "No runtime deployment or treatment recommendation"]}
    report_path.write_text(json.dumps(report, indent=2, allow_nan=False) + "\n")
    artifact = {"release": "research-only", "features": features, "outcomes": report["outcome_order"], "median": model[0].tolist(), "center": model[1].tolist(), "scale": model[2].tolist(), "coefficients_with_intercept": model[3].tolist(), "split_sha256": report["split_sha256"]}
    (OUT / "baseline-pipeline.json").write_text(json.dumps(artifact, indent=2) + "\n")
    print(json.dumps({"cohort":report["cohort_flow"], "scores":scores, "mean_r2":report["unweighted_mean_r2"], "ambition_met":report["ambition_met"]},indent=2))

if __name__ == "__main__": main()
