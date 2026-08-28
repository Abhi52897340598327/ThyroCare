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
        let totalEffectiveDose = medications.reduce(0) { $0 + $1.effectiveDailyDose }
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
