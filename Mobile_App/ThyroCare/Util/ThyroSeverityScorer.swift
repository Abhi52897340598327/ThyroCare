import Foundation

struct ThyroPatientProfile {
    let age: Int
    let sex: String
    let tsh: Double
    let t3: Double
    let t4: Double
    let hadTreatment: Bool
    let isPregnant: Bool
    let takesLithium: Bool
    let lithiumDose: Double
    let hasTumor: Bool
    let onMedication: Bool
    let medicationDose: Double
    let frequency: String
    let protein: Double
    let carbs: Double
    let vitaminA: Double
    let vitaminB: Double
    let vitaminD: Double
    let fruits: Double
    let vegetables: Double
    let waitHours: Double
    let takesIronCalcium: Bool
}

struct ThyroSeverityResult {
    let score: Int
    let percentile: Int
    let tshDecrease: Int
    let t3Improvement: Int
    let t4Improvement: Int
    let currentRiskSummary: String
    let futureRiskSummary: String

    var normalizedScore: Double {
        Double(score) / 100.0
    }

    static let baseline = ThyroSeverityResult(
        score: 0,
        percentile: 0,
        tshDecrease: 0,
        t3Improvement: 0,
        t4Improvement: 0,
        currentRiskSummary: "Submit the questionnaire to generate a deterministic thyroid risk score.",
        futureRiskSummary: "Your projected thyroid trend will appear here after scoring."
    )
}

enum ThyroSeverityScorer {
    static func score(profile: ThyroPatientProfile) -> ThyroSeverityResult {
        let coordinates = weightedCoordinates(for: profile)
        let perfectHealth = coordinates.map { _ in 0.0 }
        let clinicalFailure = coordinates.map { $0.weight }

        let userPoint = coordinates.map(\.value)
        let distanceToPerfect = euclideanDistance(from: userPoint, to: perfectHealth)
        let distanceToFailure = euclideanDistance(from: userPoint, to: clinicalFailure)
        let severity = distanceToPerfect / max(distanceToPerfect + distanceToFailure, 0.001)
        let score = clampInt(Int((severity * 100).rounded()), lower: 0, upper: 100)

        let percentile = clampInt(Int((Double(score) * 1.06).rounded()), lower: 1, upper: 99)
        let tshDecrease = clampInt(Int((12.0 + Double(score) * 0.22).rounded()), lower: 8, upper: 38)
        let t3Improvement = clampInt(Int((6.0 + Double(score) * 0.13).rounded()), lower: 4, upper: 24)
        let t4Improvement = clampInt(Int((7.0 + Double(score) * 0.15).rounded()), lower: 5, upper: 28)

        return ThyroSeverityResult(
            score: score,
            percentile: percentile,
            tshDecrease: tshDecrease,
            t3Improvement: t3Improvement,
            t4Improvement: t4Improvement,
            currentRiskSummary: currentRiskSummary(for: score),
            futureRiskSummary: futureRiskSummary(for: score)
        )
    }

    private static func weightedCoordinates(for profile: ThyroPatientProfile) -> [(value: Double, weight: Double)] {
        let supplementTimingPenalty = profile.takesIronCalcium && profile.waitHours < 4 ? 1.0 : 0.0
        let dietBalance = average([
            rangeRisk(profile.protein, ideal: 25, tolerance: 15, worstDeviation: 45),
            rangeRisk(profile.carbs, ideal: 35, tolerance: 18, worstDeviation: 50),
            lowValueRisk(profile.vitaminA, idealMinimum: 10, failureAt: 0),
            lowValueRisk(profile.vitaminB, idealMinimum: 10, failureAt: 0),
            lowValueRisk(profile.vitaminD, idealMinimum: 12, failureAt: 0),
            lowValueRisk(profile.fruits + profile.vegetables, idealMinimum: 45, failureAt: 5)
        ])

        return [
            (rangeRisk(Double(profile.age), ideal: 38, tolerance: 22, worstDeviation: 55), 0.72),
            (sexRisk(profile.sex), 0.28),
            (rangeRisk(profile.tsh, ideal: 2.0, tolerance: 1.8, worstDeviation: 10.0), 1.45),
            (rangeRisk(profile.t3, ideal: 120.0, tolerance: 35.0, worstDeviation: 110.0), 1.05),
            (rangeRisk(profile.t4, ideal: 8.2, tolerance: 2.0, worstDeviation: 7.0), 1.05),
            (profile.hadTreatment ? 1.0 : 0.0, 1.12),
            (profile.isPregnant ? 0.65 : 0.0, 0.76),
            (profile.takesLithium ? 0.72 + min(profile.lithiumDose / 1200.0, 0.28) : 0.0, 1.18),
            (profile.hasTumor ? 1.0 : 0.0, 1.28),
            (medicationRisk(profile), 1.16),
            (dietBalance, 0.92),
            (waitTimeRisk(profile.waitHours), 1.10),
            (supplementTimingPenalty, 0.98)
        ].map { coordinate in
            (value: coordinate.0 * coordinate.1, weight: coordinate.1)
        }
    }

    private static func medicationRisk(_ profile: ThyroPatientProfile) -> Double {
        guard profile.onMedication else {
            return profile.tsh > 4.5 ? 0.72 : 0.24
        }

        let doseRisk = rangeRisk(profile.medicationDose, ideal: 75, tolerance: 50, worstDeviation: 180)
        let frequencyRisk: Double
        switch profile.frequency {
        case "Daily": frequencyRisk = 0.0
        case "Weekly": frequencyRisk = 0.35
        case "Biweekly": frequencyRisk = 0.58
        default: frequencyRisk = 0.78
        }

        return max(doseRisk, frequencyRisk)
    }

    private static func rangeRisk(_ value: Double, ideal: Double, tolerance: Double, worstDeviation: Double) -> Double {
        guard value > 0 else { return 0.55 }
        let deviation = max(abs(value - ideal) - tolerance, 0)
        return clamp(deviation / max(worstDeviation, 0.001))
    }

    private static func lowValueRisk(_ value: Double, idealMinimum: Double, failureAt: Double) -> Double {
        guard value < idealMinimum else { return 0 }
        return clamp((idealMinimum - value) / max(idealMinimum - failureAt, 0.001))
    }

    private static func waitTimeRisk(_ hours: Double) -> Double {
        if hours >= 4 { return 0 }
        if hours >= 2 { return 0.28 }
        if hours >= 1 { return 0.62 }
        return 0.92
    }

    private static func sexRisk(_ sex: String) -> Double {
        switch sex {
        case "Female": return 0.18
        case "Male": return 0.12
        case "Intersex": return 0.20
        default: return 0.16
        }
    }

    private static func euclideanDistance(from lhs: [Double], to rhs: [Double]) -> Double {
        zip(lhs, rhs)
            .map { pow($0 - $1, 2) }
            .reduce(0, +)
            .squareRoot()
    }

    private static func average(_ values: [Double]) -> Double {
        values.reduce(0, +) / max(Double(values.count), 1)
    }

    private static func currentRiskSummary(for score: Int) -> String {
        switch score {
        case 0..<35:
            return "Your profile is closer to the healthy reference point, but timing and labs should still be monitored."
        case 35..<70:
            return "Your profile sits between the healthy and clinical-failure reference points, suggesting moderate thyroid instability risk."
        default:
            return "Your profile is geometrically closer to the clinical-failure reference point, suggesting elevated thyroid instability risk."
        }
    }

    private static func futureRiskSummary(for score: Int) -> String {
        switch score {
        case 0..<35:
            return "If your current habits continue, the model predicts your risk may remain controlled but sensitive to missed medication timing."
        case 35..<70:
            return "If your current habits continue, the model predicts your thyroid levels may drift further away from the healthy baseline."
        default:
            return "If your current habits continue, the model predicts a higher chance of worsening thyroid imbalance."
        }
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func clampInt(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
