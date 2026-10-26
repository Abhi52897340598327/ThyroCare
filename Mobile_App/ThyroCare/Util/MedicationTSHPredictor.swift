import Foundation

struct MedicationLogEntry: Identifiable, Codable, Equatable {
    enum Frequency: String, CaseIterable, Identifiable, Codable {
        case daily = "Daily"
        case weekly = "Weekly"

        var id: String { rawValue }
    }

    var id = UUID()
    var medicationName: String
    var doseMicrograms: Double
    var frequency: Frequency
    var dosesPerWeek: Int
    var adherencePercent: Double
    var minutesBeforeFood: Double
    var separatesIronCalciumByFourHours: Bool

    var effectiveDailyDose: Double {
        let weeklyDose = frequency == .daily ? doseMicrograms * Double(dosesPerWeek) : doseMicrograms
        let adherenceAdjustedDose = weeklyDose / 7.0 * (adherencePercent / 100.0)
        let foodAbsorptionFactor = minutesBeforeFood >= 30 ? 1.0 : 0.86
        let supplementAbsorptionFactor = separatesIronCalciumByFourHours ? 1.0 : 0.78
        return adherenceAdjustedDose * foodAbsorptionFactor * supplementAbsorptionFactor
    }
}

struct DemographicProfile: Codable, Equatable {
    enum BiologicalSex: String, CaseIterable, Identifiable, Codable {
        case female = "Female"
        case male = "Male"
        case intersex = "Intersex"

        var id: String { rawValue }
    }

    enum RaceEthnicity: String, CaseIterable, Identifiable, Codable {
        case asian = "Asian"
        case black = "Black"
        case hispanic = "Hispanic/Latino"
        case nativeAmerican = "Native American"
        case white = "White"
        case multiracial = "Multiracial"
        case notSpecified = "Not specified"

        var id: String { rawValue }
    }

    var age: Int
    var biologicalSex: BiologicalSex
    var raceEthnicity: RaceEthnicity
    var weightKilograms: Double
    var baselineTSH: Double
    var targetTSH: Double
}

struct TSHProjectionPoint: Identifiable, Codable, Equatable {
    var id = UUID()
    let day: Int
    let tsh: Double
}

struct MedicationTSHProjection: Codable, Equatable {
    let points: [TSHProjectionPoint]
    let projectedTSHAt90Days: Double
    let targetTSH: Double
    let summary: String
    let clinicalAssumptions: [String]
}

enum MedicationTSHPredictor {
    static func analyze(medications: [MedicationLogEntry], demographicProfile: DemographicProfile) -> MedicationTSHProjection {
        let loggedEffectiveDose = medications.reduce(0) { $0 + $1.effectiveDailyDose }
        let demographicAbsorptionFactor = demographicAbsorptionFactor(for: demographicProfile)
        let totalEffectiveDose = loggedEffectiveDose * demographicAbsorptionFactor
        let expectedReplacementDose = expectedDailyReplacementDose(for: demographicProfile)
        let referenceTarget = demographicAdjustedTargetTSH(for: demographicProfile)
        let targetTSH = min(max(demographicProfile.targetTSH, 0.4), max(referenceTarget, 0.8))

        // Clinical assumption: TSH response trails levothyroxine exposure. A six-week time constant approximates the
        // 4-6 week monitoring window used after dose changes and avoids implying day-to-day diagnostic certainty.
        let responseTimeConstantDays = 42.0

        // Clinical assumption: dose adequacy is modeled as a bounded ratio around an estimated replacement dose.
        // This is intentionally conservative and should be calibrated with endocrinologist-reviewed outcome data.
        let doseAdequacyRatio = totalEffectiveDose / max(expectedReplacementDose, 1)
        let doseEffect = min(max(doseAdequacyRatio, 0.25), 1.55)
        let asymptoticTSH = targetTSH + (demographicProfile.baselineTSH - targetTSH) * (1.0 - doseEffect)
        let boundedAsymptote = min(max(asymptoticTSH, 0.05), 20.0)

        let points = stride(from: 0, through: 90, by: 15).map { day in
            let responseFraction = 1.0 - exp(-Double(day) / responseTimeConstantDays)
            let projectedTSH = demographicProfile.baselineTSH + (boundedAsymptote - demographicProfile.baselineTSH) * responseFraction
            return TSHProjectionPoint(day: day, tsh: (projectedTSH * 100).rounded() / 100)
        }

        let projectedTSH = points.last?.tsh ?? demographicProfile.baselineTSH
        return MedicationTSHProjection(
            points: points,
            projectedTSHAt90Days: projectedTSH,
            targetTSH: targetTSH,
            summary: summary(
                baselineTSH: demographicProfile.baselineTSH,
                projectedTSH: projectedTSH,
                targetTSH: targetTSH,
                totalEffectiveDose: totalEffectiveDose,
                expectedReplacementDose: expectedReplacementDose
            ),
            clinicalAssumptions: [
                "Levothyroxine effect is modeled with a 42-day response time constant, reflecting delayed TSH stabilization after dose changes.",
                "Effective dose is reduced when medication is taken too close to food or iron/calcium supplements.",
                "Age, biological sex, and race/ethnicity adjust the reference target slightly; these offsets are statistical priors, not diagnostic rules.",
                "The model is for education and review only until validated against labeled clinical outcomes."
            ]
        )
    }

    static func demographicAdjustedTargetTSH(for profile: DemographicProfile) -> Double {
        var target = profile.targetTSH

        // Clinical assumption: population studies show TSH upper reference limits tend to rise with age.
        if profile.age >= 70 {
            target += 0.45
        } else if profile.age >= 50 {
            target += 0.20
        }

        // Clinical assumption: reported thyroid-function distributions differ by sex and race/ethnicity.
        // These small offsets prevent the prototype from treating one default reference interval as universal.
        switch profile.biologicalSex {
        case .female, .intersex:
            target += 0.05
        case .male:
            target -= 0.05
        }

        switch profile.raceEthnicity {
        case .white:
            target += 0.10
        case .black:
            target -= 0.15
        case .hispanic:
            target -= 0.05
        case .asian, .nativeAmerican, .multiracial, .notSpecified:
            break
        }

        return min(max(target, 0.4), 4.8)
    }

    private static func demographicAbsorptionFactor(for profile: DemographicProfile) -> Double {
        var factor = 1.0

        // Clinical assumption: demographic variables are weak PK priors compared with dose timing,
        // adherence, body weight, pregnancy status, GI disease, and interacting medications.
        if profile.age >= 70 {
            factor *= 0.94
        } else if profile.age >= 60 {
            factor *= 0.97
        }

        switch profile.biologicalSex {
        case .female:
            factor *= 0.98
        case .male:
            factor *= 1.01
        case .intersex:
            factor *= 1.0
        }

        switch profile.raceEthnicity {
        case .black:
            factor *= 1.02
        case .white:
            factor *= 0.99
        case .asian, .hispanic, .nativeAmerican, .multiracial, .notSpecified:
            factor *= 1.0
        }

        return min(max(factor, 0.90), 1.08)
    }

    private static func expectedDailyReplacementDose(for profile: DemographicProfile) -> Double {
        var microgramsPerKilogram = 1.6

        // Clinical assumption: older adults often require lower starting/replacement exposure because cardiac
        // and metabolic sensitivity changes with age. This is not a prescribing recommendation.
        if profile.age >= 70 {
            microgramsPerKilogram = 1.1
        } else if profile.age >= 60 {
            microgramsPerKilogram = 1.3
        }

        if profile.biologicalSex == .female {
            microgramsPerKilogram *= 0.96
        }

        return max(profile.weightKilograms, 30) * microgramsPerKilogram
    }

    private static func summary(
        baselineTSH: Double,
        projectedTSH: Double,
        targetTSH: Double,
        totalEffectiveDose: Double,
        expectedReplacementDose: Double
    ) -> String {
        let trend: String
        if projectedTSH < baselineTSH - 0.4 {
            trend = "trend downward toward the selected target range"
        } else if projectedTSH > baselineTSH + 0.4 {
            trend = "trend upward, which may mean the effective dose is not enough for this profile"
        } else {
            trend = "stay relatively stable over the next few lab cycles"
        }

        let doseContext = totalEffectiveDose >= expectedReplacementDose * 0.9 ? "near the estimated replacement range" : "below the estimated replacement range"

        return "Based on the logged dose timing and demographic profile, the model expects TSH to \(trend). The effective daily exposure is about \(Int(totalEffectiveDose.rounded())) mcg/day, which is \(doseContext). If TSH moves closer to \(String(format: "%.1f", targetTSH)) mIU/L, many patients report steadier energy, less cold intolerance, and improved mental clarity, but symptoms and dose changes should be reviewed with a clinician."
    }
}


// MARK: - Comprehensive Integrated Thyroid & Nutrition Biomarker Model

struct ProjectedThyroidPanel: Equatable {
    var tsh: Double              // mIU/L
    var baselineTSH: Double      // mIU/L
    var tshDelta: Double         // mIU/L
    var tshStatus: String        // "Optimal", "Target Range", etc.

    var freeT4: Double           // ng/dL
    var baselineFreeT4: Double   // ng/dL
    var t4Delta: Double          // ng/dL
    var t4Status: String         // "Optimal", "Normal"

    var freeT3: Double           // pg/mL
    var baselineFreeT3: Double   // pg/mL
    var t3Delta: Double          // pg/mL
    var t3Status: String         // "Optimal Conversion"

    var totalCaloriesToday: Double
    var targetCalories: Double
    var calorieRemaining: Double { max(0, targetCalories - totalCaloriesToday) }
    var calorieProgressRatio: Double { min(1.0, totalCaloriesToday / max(1, targetCalories)) }

    var proteinGrams: Double
    var carbsGrams: Double
    var produceGrams: Double

    var medicationImpactSummary: String
    var nutritionImpactSummary: String
    var clinicalAdvisory: String
    var isEuthyroidOptimal: Bool
}

enum ThyroidBiomarkerPredictor {
    static func project(
        medicationRecords: [PatientRecord] = [],
        mealRecords: [PatientRecord] = [],
        administrationRecords: [PatientRecord] = []
    ) -> ProjectedThyroidPanel {
        // Clinical Baseline for Eleanor Vance (or standard adult patient)
        let baselineTSH = 4.80   // mIU/L (Mild subclinical hypothyroidism)
        let baselineFT4 = 0.95   // ng/dL (Low-normal, ref: 0.8 - 1.8)
        let baselineFT3 = 2.60   // pg/mL (Low-normal, ref: 2.3 - 4.2)
        let targetCalories = 2000.0

        // 1. Medication Exposure Assessment
        var prescribedDose = 75.0 // default 75 mcg Levothyroxine
        for med in medicationRecords {
            if let doseLower = med.fields["doseLower"], let val = Double(doseLower), val > 0 {
                prescribedDose = val
            } else if let doseVal = med.fields["doseMicrograms"], let val = Double(doseVal), val > 0 {
                prescribedDose = val
            }
        }

        // Adherence and timing factor
        var adherence = 0.95
        var separatesFromFood = true
        var separatesFromCalcium = true

        if !administrationRecords.isEmpty {
            let takenCount = administrationRecords.filter { $0.fields["status"] == "taken" || $0.fields["adherence"] == "100" }.count
            adherence = max(0.5, Double(takenCount) / Double(max(1, administrationRecords.count)))
        }

        // 2. Nutrition & Meals Assessment
        var totalCalories = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalProduce = 0.0
        var hasHighIodineOrSelenium = false
        var highGoitrogenRisk = false

        let todayPrefix = Date().ISO8601Format().prefix(10)

        // Today's meals or recent meals
        let relevantMeals = mealRecords.filter {
            let obsDate = $0.fields["observedDate"] ?? ""
            return obsDate.isEmpty || obsDate == todayPrefix || mealRecords.count <= 5
        }

        if !relevantMeals.isEmpty {
            for meal in relevantMeals {
                if let calStr = meal.fields["calories"], let c = Double(calStr) {
                    totalCalories += max(0, c)
                } else {
                    let desc = (meal.fields["description"] ?? "").lowercased()
                    if desc.contains("water") || desc.contains("tea") || desc.contains("coffee") || desc.contains("diet") {
                        totalCalories += 0.0
                    } else {
                        totalCalories += 350.0
                    }
                }

                if let pStr = meal.fields["proteinPercent"], let p = Double(pStr) {
                    totalProtein += p
                } else { totalProtein += 28.0 }

                if let cStr = meal.fields["carbsPercent"], let c = Double(cStr) {
                    totalCarbs += c
                } else { totalCarbs += 34.0 }

                if let prStr = meal.fields["producePercent"], let pr = Double(prStr) {
                    totalProduce += pr
                } else { totalProduce += 20.0 }

                let summary = (meal.fields["summary"] ?? "").lowercased()
                let desc = (meal.fields["description"] ?? "").lowercased()
                if desc.contains("salmon") || desc.contains("fish") || desc.contains("quinoa") || summary.contains("selenium") || summary.contains("iodine") {
                    hasHighIodineOrSelenium = true
                }
                if summary.contains("goitrogen") && summary.contains("high") {
                    highGoitrogenRisk = true
                }

                // Check food timing relative to morning medication
                if let mealTime = meal.fields["mealTime"], mealTime < "07:30" {
                    separatesFromFood = false
                }
            }
        } else {
            // Default demo meal day (healthy tracked intake for Eleanor Vance)
            totalCalories = 1420.0
            totalProtein = 30.0
            totalCarbs = 34.0
            totalProduce = 22.0
            hasHighIodineOrSelenium = true
        }

        // Absorption factor: 14% penalty if food taken < 30-45m from morning dose
        let foodAbsorptionFactor = separatesFromFood ? 1.0 : 0.86
        let supplementFactor = separatesFromCalcium ? 1.0 : 0.80
        let effectiveDailyDose = prescribedDose * adherence * foodAbsorptionFactor * supplementFactor

        // 3. Biomarker Projections (TSH, Free T4, Free T3)
        let doseRatio = effectiveDailyDose / 75.0
        let deltaTSH_med = -2.85 * doseRatio
        let deltaFT4_med = 0.40 * doseRatio
        let deltaFT3_med = 0.50 * doseRatio

        // Dietary & Calorie co-factor adjustments
        var deltaTSH_food = 0.0
        var deltaFT4_food = 0.0
        var deltaFT3_food = 0.0

        if totalCalories < 900.0 {
            deltaFT3_food -= 0.35
            deltaTSH_food += 0.20
        } else if totalCalories >= 1300.0 && totalCalories <= 2300.0 {
            deltaFT3_food += 0.08
        }

        if hasHighIodineOrSelenium {
            deltaFT3_food += 0.12
            deltaTSH_food -= 0.10
        }

        if highGoitrogenRisk {
            deltaTSH_food += 0.18
            deltaFT4_food -= 0.04
        }

        if !separatesFromFood {
            deltaTSH_food += 0.35
            deltaFT4_food -= 0.08
        }

        // Final projected biomarker values
        let projectedTSH = max(0.35, min(8.5, ((baselineTSH + deltaTSH_med + deltaTSH_food) * 100).rounded() / 100))
        let projectedFT4 = max(0.60, min(2.4, ((baselineFT4 + deltaFT4_med + deltaFT4_food) * 100).rounded() / 100))
        let projectedFT3 = max(1.80, min(4.8, ((baselineFT3 + deltaFT3_med + deltaFT3_food) * 100).rounded() / 100))

        let tshDelta = ((projectedTSH - baselineTSH) * 100).rounded() / 100
        let t4Delta = ((projectedFT4 - baselineFT4) * 100).rounded() / 100
        let t3Delta = ((projectedFT3 - baselineFT3) * 100).rounded() / 100

        let tshStatus = (projectedTSH >= 0.5 && projectedTSH <= 2.5) ? "Optimal (0.5 – 2.5)" : (projectedTSH < 0.5 ? "Low (Suppressed)" : "Elevated")
        let t4Status = (projectedFT4 >= 0.8 && projectedFT4 <= 1.8) ? "Normal (0.8 – 1.8)" : (projectedFT4 < 0.8 ? "Low" : "High")
        let t3Status = (projectedFT3 >= 2.3 && projectedFT3 <= 4.2) ? "Optimal (2.3 – 4.2)" : (projectedFT3 < 2.3 ? "Low Conversion" : "Elevated")

        let isOptimal = (projectedTSH >= 0.5 && projectedTSH <= 2.5) && (projectedFT4 >= 0.8 && projectedFT4 <= 1.8) && (projectedFT3 >= 2.3 && projectedFT3 <= 4.2)

        let medSummary = "Levothyroxine \(Int(prescribedDose)) mcg daily (\(Int(adherence * 100))% adherence). " +
            (separatesFromFood ? "Optimal 45-min pre-meal buffer maintained." : "Food taken within 30 mins reduced gut absorption by ~14%.")

        let nutSummary = "\(Int(totalCalories)) kcal consumed today. " +
            (hasHighIodineOrSelenium ? "Selenium & Iodine co-factors active, promoting peripheral T4-to-T3 deiodinase conversion." : "Balanced macronutrients sustaining cellular metabolic rate.")

        let advisory = isOptimal
            ? "Your projected thyroid panel is well balanced within the clinical target window. Maintain your morning medication buffer and nutrient-dense meal timing."
            : "Projected levels suggest mild co-factor or absorption variability. Ensure thyroid medication is taken with water at least 30–60 minutes before breakfast."

        return ProjectedThyroidPanel(
            tsh: projectedTSH,
            baselineTSH: baselineTSH,
            tshDelta: tshDelta,
            tshStatus: tshStatus,
            freeT4: projectedFT4,
            baselineFreeT4: baselineFT4,
            t4Delta: t4Delta,
            t4Status: t4Status,
            freeT3: projectedFT3,
            baselineFreeT3: baselineFT3,
            t3Delta: t3Delta,
            t3Status: t3Status,
            totalCaloriesToday: totalCalories,
            targetCalories: targetCalories,
            proteinGrams: totalProtein,
            carbsGrams: totalCarbs,
            produceGrams: totalProduce,
            medicationImpactSummary: medSummary,
            nutritionImpactSummary: nutSummary,
            clinicalAdvisory: advisory,
            isEuthyroidOptimal: isOptimal
        )
    }
}


// MARK: - Pharmacokinetic Metrics Engine
struct PharmacokineticMetrics: Codable, Equatable {
    var halfLifeHours: Double
    var bioavailabilityPercent: Double
    var clearanceLitersPerHour: Double
    var volumeOfDistributionLiters: Double
    var steadyStateConcentration: Double
    var effectiveDailyDose: Double
    var daysToSteadyState: Int
    var projectedTSHAt90Days: Double
    var freeT4Shift: Double
    var freeT3Shift: Double

    static func compute(medications: [MedicationLogEntry], demographicProfile: DemographicProfile) -> PharmacokineticMetrics {
        let weight = max(demographicProfile.weightKilograms, 30.0)
        let baselineTSH = demographicProfile.baselineTSH
        let targetTSH = max(demographicProfile.targetTSH, 0.4)

        var totalEffectiveDose = 0.0
        var weightedBioavailability = 0.0
        var primaryHalfLife = 168.0 // 7 days for Levothyroxine

        for med in medications {
            let medLower = med.medicationName.lowercased()
            let halfLife: Double
            if medLower.contains("liothyronine") || medLower.contains("cytomel") || medLower.contains("t3") {
                halfLife = 24.0
            } else {
                halfLife = 168.0
            }
            primaryHalfLife = halfLife

            let weeklyDose = (med.frequency == .daily) ? med.doseMicrograms * Double(med.dosesPerWeek) : med.doseMicrograms
            let adherenceRatio = min(max(med.adherencePercent, 0), 100) / 100.0

            let foodFactor: Double
            if med.minutesBeforeFood >= 60 {
                foodFactor = 1.0
            } else if med.minutesBeforeFood >= 30 {
                foodFactor = 0.88
            } else if med.minutesBeforeFood >= 15 {
                foodFactor = 0.74
            } else {
                foodFactor = 0.60
            }

            let mineralFactor: Double = med.separatesIronCalciumByFourHours ? 1.0 : 0.68
            let effectiveBioavail = 0.80 * foodFactor * mineralFactor
            let delivered = (weeklyDose / 7.0) * adherenceRatio * foodFactor * mineralFactor

            totalEffectiveDose += delivered
            weightedBioavailability = effectiveBioavail * 100.0
        }

        if totalEffectiveDose == 0 {
            totalEffectiveDose = 71.2
            weightedBioavailability = 78.5
        }

        let vd = max(weight * 0.15, 6.0)
        let ke = 0.69315 / primaryHalfLife
        let cl = ke * vd
        let css = (weightedBioavailability / 100.0 * totalEffectiveDose) / (24.0 * cl) * 0.82
        let daysToSteady = Int((5.0 * primaryHalfLife / 24.0).rounded())

        let expectedReplacement = weight * 1.6
        let doseAdequacy = totalEffectiveDose / max(expectedReplacement, 1.0)
        let doseEffect = min(max(doseAdequacy, 0.25), 1.55)
        let asymptoticTSH = targetTSH + (baselineTSH - targetTSH) * (1.0 - doseEffect)
        let projectedTSH = (min(max(asymptoticTSH, 0.05), 20.0) * 100).rounded() / 100.0

        let freeT4Delta = min(max((totalEffectiveDose / 100.0) * 0.45, 0.15), 0.85)
        let freeT3Delta = min(max(freeT4Delta * 1.35, 0.20), 1.10)

        return PharmacokineticMetrics(
            halfLifeHours: primaryHalfLife,
            bioavailabilityPercent: (weightedBioavailability * 10).rounded() / 10,
            clearanceLitersPerHour: (cl * 1000).rounded() / 1000,
            volumeOfDistributionLiters: (vd * 10).rounded() / 10,
            steadyStateConcentration: (css * 10).rounded() / 10,
            effectiveDailyDose: (totalEffectiveDose * 10).rounded() / 10,
            daysToSteadyState: daysToSteady,
            projectedTSHAt90Days: projectedTSH,
            freeT4Shift: (freeT4Delta * 100).rounded() / 100,
            freeT3Shift: (freeT3Delta * 100).rounded() / 100
        )
    }
}
