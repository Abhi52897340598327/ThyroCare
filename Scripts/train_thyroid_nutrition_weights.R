#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(foreign))

downloads_dir <- Sys.getenv("THYROCARE_NHANES_DIR", unset = "/Users/abhiraamvenigalla/Downloads")
output_path <- Sys.getenv("THYROCARE_WEIGHT_OUTPUT", unset = "Derived/thyroid_nutrition_weights.json")

read_xpt <- function(name) {
  path <- file.path(downloads_dir, paste0(name, ".xpt"))
  if (!file.exists(path)) {
    stop("Missing XPT file: ", path)
  }
  read.xport(path)
}

safe_col <- function(data, name) {
  if (name %in% names(data)) data[[name]] else rep(NA_real_, nrow(data))
}

mean2 <- function(a, b) {
  rowMeans(cbind(a, b), na.rm = TRUE)
}

z <- function(x) {
  as.numeric(scale(x))
}

z0 <- function(x) {
  values <- z(x)
  values[!is.finite(values)] <- 0
  values
}

nutrient_average <- function(cycle) {
  day1 <- read_xpt(paste0("DR1TOT_", cycle))
  day2 <- read_xpt(paste0("DR2TOT_", cycle))

  out <- data.frame(SEQN = day1$SEQN)
  names <- c(
    "KCAL", "PROT", "CARB", "SUGR", "FIBE", "TTFAT",
    "VB1", "VB2", "NIAC", "VB6", "FOLA", "VB12", "VC", "VD",
    "CALC", "MAGN", "IRON", "ZINC", "POTA", "SELE"
  )

  for (name in names) {
    out[[name]] <- mean2(
      safe_col(day1, paste0("DR1T", name)),
      safe_col(day2, paste0("DR2T", name))
    )
  }

  out
}

build_cycle <- function(cycle) {
  thyroid <- read_xpt(paste0("THYROD_", cycle))
  demo <- read_xpt(paste0("DEMO_", cycle))
  bmx <- read_xpt(paste0("BMX_", cycle))
  vid <- read_xpt(paste0("VID_", cycle))
  uio <- read_xpt(paste0("UIO_", cycle))
  diet <- nutrient_average(cycle)

  data <- Reduce(
    function(left, right) merge(left, right, by = "SEQN", all.x = TRUE),
    list(thyroid, demo, bmx, vid, uio, diet)
  )
  data$cycle <- cycle
  data
}

rbind_fill <- function(frames) {
  all_names <- unique(unlist(lapply(frames, names)))
  aligned <- lapply(frames, function(frame) {
    missing_names <- setdiff(all_names, names(frame))
    for (name in missing_names) {
      frame[[name]] <- NA
    }
    frame[, all_names]
  })
  do.call(rbind, aligned)
}

data <- rbind_fill(lapply(c("E", "F", "G"), build_cycle))

positive <- function(x) ifelse(is.finite(x) & x > 0, x, NA_real_)
per_1000 <- function(nutrient, kcal) nutrient / pmax(kcal, 1) * 1000

data$logTSH <- log(positive(safe_col(data, "LBXTSH1")))
data$freeT3 <- positive(safe_col(data, "LBXT3F"))
data$freeT4 <- positive(safe_col(data, "LBXT4F"))
data$totalT3 <- positive(safe_col(data, "LBXTT3"))
data$totalT4 <- positive(safe_col(data, "LBXTT4"))

data$proteinDensity <- per_1000(safe_col(data, "PROT"), safe_col(data, "KCAL"))
data$carbDensity <- per_1000(safe_col(data, "CARB"), safe_col(data, "KCAL"))
data$sugarDensity <- per_1000(safe_col(data, "SUGR"), safe_col(data, "KCAL"))
data$fiberDensity <- per_1000(safe_col(data, "FIBE"), safe_col(data, "KCAL"))
data$fatDensity <- per_1000(safe_col(data, "TTFAT"), safe_col(data, "KCAL"))
data$vitaminBDensity <- per_1000(
  rowSums(data.frame(
    safe_col(data, "VB1"), safe_col(data, "VB2"), safe_col(data, "NIAC"),
    safe_col(data, "VB6"), safe_col(data, "FOLA"), safe_col(data, "VB12")
  ), na.rm = TRUE),
  safe_col(data, "KCAL")
)
data$vitaminDensity <- per_1000(
  rowSums(data.frame(
    safe_col(data, "VB1"), safe_col(data, "VB2"), safe_col(data, "NIAC"),
    safe_col(data, "VB6"), safe_col(data, "FOLA"), safe_col(data, "VB12"),
    safe_col(data, "VC"), safe_col(data, "VD"), safe_col(data, "SELE"), safe_col(data, "ZINC")
  ), na.rm = TRUE),
  safe_col(data, "KCAL")
)
data$produceDensity <- per_1000(
  rowSums(data.frame(
    safe_col(data, "FIBE"), safe_col(data, "POTA"), safe_col(data, "MAGN"), safe_col(data, "VC")
  ), na.rm = TRUE),
  safe_col(data, "KCAL")
)
data$iodineCreatinineRatio <- safe_col(data, "URXUIO") / pmax(safe_col(data, "URXUCR"), 1)

model_data <- data.frame(
  logTSH = data$logTSH,
  freeT3 = data$freeT3,
  freeT4 = data$freeT4,
  totalT3 = data$totalT3,
  totalT4 = data$totalT4,
  protein = z0(data$proteinDensity),
  carbs = z0(data$carbDensity),
  sugar = z0(data$sugarDensity),
  fiber = z0(data$fiberDensity),
  fat = z0(data$fatDensity),
  vitamins = z0(data$vitaminDensity),
  vitaminB = z0(data$vitaminBDensity),
  produce = z0(data$produceDensity),
  age = z0(safe_col(data, "RIDAGEYR")),
  sex = factor(safe_col(data, "RIAGENDR")),
  bmi = z0(safe_col(data, "BMXBMI")),
  serumVitaminD = z0(safe_col(data, "LBXVIDMS")),
  urinaryIodine = z0(log1p(data$iodineCreatinineRatio)),
  cycle = factor(data$cycle),
  weight = ifelse(is.finite(safe_col(data, "WTSA2YR")) & safe_col(data, "WTSA2YR") > 0, safe_col(data, "WTSA2YR"), 1)
)

features <- c("protein", "carbs", "sugar", "fiber", "fat", "vitamins", "vitaminB", "produce")
covariates <- c("age", "sex", "bmi", "serumVitaminD", "urinaryIodine", "cycle")

fit_outcome <- function(outcome) {
  needed <- c(outcome, features, covariates, "weight")
  df <- model_data[complete.cases(model_data[, needed]), needed]
  formula <- as.formula(paste(outcome, "~", paste(c(features, covariates), collapse = " + ")))
  fit <- lm(formula, data = df, weights = weight)
  coefs <- coef(fit)[features]
  coefs[is.na(coefs)] <- 0
  list(coefficients = coefs, n = nrow(df), r2 = summary(fit)$r.squared)
}

fits <- list(
  tsh = fit_outcome("logTSH"),
  t3 = fit_outcome(if (sum(!is.na(model_data$freeT3)) > 1000) "freeT3" else "totalT3"),
  t4 = fit_outcome(if (sum(!is.na(model_data$freeT4)) > 1000) "freeT4" else "totalT4")
)

normalize_weights <- function(coefs, invert = FALSE) {
  if (invert) coefs <- -coefs
  selected <- coefs[c("protein", "carbs", "vitamins", "produce")]
  if (all(abs(selected) < 1e-12)) selected <- c(protein = 0.25, carbs = -0.25, vitamins = 0.25, produce = 0.25)
  selected / sum(abs(selected))
}

weights <- list(
  tsh = normalize_weights(fits$tsh$coefficients, invert = FALSE),
  t3 = normalize_weights(fits$t3$coefficients, invert = FALSE),
  t4 = normalize_weights(fits$t4$coefficients, invert = FALSE)
)

format_named <- function(x) {
  paste(sprintf('"%s": %.8f', names(x), as.numeric(x)), collapse = ", ")
}

json <- paste0(
  "{\n",
  '  "source": "NHANES 2007-2012: THYROD_E/F/G joined to DR1TOT/DR2TOT, DEMO, BMX, VID, UIO",\n',
  '  "model_note": "Weighted cross-sectional association model. Coefficients are association-based, not causal short-term meal effects.",\n',
  '  "feature_note": "Nutrient densities are standardized per 1000 kcal and adjusted for age, sex, BMI, serum vitamin D, urinary iodine/creatinine, and cycle.",\n',
  '  "sample_sizes": {"tsh": ', fits$tsh$n, ', "t3": ', fits$t3$n, ', "t4": ', fits$t4$n, "},\n",
  '  "r_squared": {"tsh": ', sprintf("%.8f", fits$tsh$r2), ', "t3": ', sprintf("%.8f", fits$t3$r2), ', "t4": ', sprintf("%.8f", fits$t4$r2), "},\n",
  '  "weights": {\n',
  '    "tsh": {', format_named(weights$tsh), "},\n",
  '    "t3": {', format_named(weights$t3), "},\n",
  '    "t4": {', format_named(weights$t4), "}\n",
  "  }\n",
  "}\n"
)

dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
writeLines(json, output_path)
cat(json)
