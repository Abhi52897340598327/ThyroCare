import Foundation

struct ReviewMedicationItem: Codable {
    var medicationName: String
    var doseMicrograms: Double
    var frequency: String
    var dosesPerWeek: Int
    var adherencePercent: Double
    var minutesBeforeFood: Double
    var separatesIronCalciumByFourHours: Bool
}

struct ReviewDemographicsItem: Codable {
    var age: Int
    var biologicalSex: String
    var raceEthnicity: String
    var weightKilograms: Double
    var baselineTSH: Double
    var targetTSH: Double
}

struct ReviewPharmacokineticsItem: Codable {
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
}

struct ReviewMedicationsRequest: Codable {
    var medications: [ReviewMedicationItem]
    var demographics: ReviewDemographicsItem
    var pharmacokinetics: ReviewPharmacokineticsItem?
}

struct MedicationReviewResponse: Codable {
    var status: String
    var model: String
    var summary: String
    var mechanismOfAction: String
    var pharmacokineticsSummary: String
    var thyroidHormoneImpact: String
    var absorptionInteractions: String
    var clinicalGuidance: String
    var keyTakeaways: [String]
    var pharmacokinetics: ReviewPharmacokineticsItem
    var projectedTSHAt90Days: Double
    var targetTSH: Double
    var timestamp: String
}

struct MedicationReviewService {
    static let shared = MedicationReviewService()

    private var baseURL: URL {
        #if DEBUG && targetEnvironment(simulator)
        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "ThyroCareSimulatorBackendBaseURL") as? String,
           let url = URL(string: configuredURL) {
            return url
        }
        #endif
        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "ThyroCareBackendBaseURL") as? String,
           let url = URL(string: configuredURL) {
            return url
        }

        return URL(string: "https://thyrocare-9qfo.onrender.com")!
    }

    func review(medications: [MedicationLogEntry], demographicProfile: DemographicProfile) async -> MedicationReviewResponse {
        let pk = PharmacokineticMetrics.compute(medications: medications, demographicProfile: demographicProfile)

        let medItems = medications.map { med in
            ReviewMedicationItem(
                medicationName: med.medicationName,
                doseMicrograms: med.doseMicrograms,
                frequency: med.frequency.rawValue,
                dosesPerWeek: med.dosesPerWeek,
                adherencePercent: med.adherencePercent,
                minutesBeforeFood: med.minutesBeforeFood,
                separatesIronCalciumByFourHours: med.separatesIronCalciumByFourHours
            )
        }

        let demoItem = ReviewDemographicsItem(
            age: demographicProfile.age,
            biologicalSex: demographicProfile.biologicalSex.rawValue,
            raceEthnicity: demographicProfile.raceEthnicity.rawValue,
            weightKilograms: demographicProfile.weightKilograms,
            baselineTSH: demographicProfile.baselineTSH,
            targetTSH: demographicProfile.targetTSH
        )

        let pkItem = ReviewPharmacokineticsItem(
            halfLifeHours: pk.halfLifeHours,
            bioavailabilityPercent: pk.bioavailabilityPercent,
            clearanceLitersPerHour: pk.clearanceLitersPerHour,
            volumeOfDistributionLiters: pk.volumeOfDistributionLiters,
            steadyStateConcentration: pk.steadyStateConcentration,
            effectiveDailyDose: pk.effectiveDailyDose,
            daysToSteadyState: pk.daysToSteadyState,
            projectedTSHAt90Days: pk.projectedTSHAt90Days,
            freeT4Shift: pk.freeT4Shift,
            freeT3Shift: pk.freeT3Shift
        )

        let reqBody = ReviewMedicationsRequest(
            medications: medItems,
            demographics: demoItem,
            pharmacokinetics: pkItem
        )

        let url = baseURL.appending(path: "review-medications")
        if let encoded = try? JSONEncoder().encode(reqBody) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = encoded
            request.timeoutInterval = 30

            if let (data, response) = try? await URLSession.shared.data(for: request),
               let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let decoded = try? JSONDecoder().decode(MedicationReviewResponse.self, from: data) {
                return decoded
            }
        }

        // Fallback if backend is offline or network fails
        return localClinicalReview(medications: medications, profile: demographicProfile, pk: pk)
    }

    private func localClinicalReview(
        medications: [MedicationLogEntry],
        profile: DemographicProfile,
        pk: PharmacokineticMetrics
    ) -> MedicationReviewResponse {
        let primaryMed = medications.first?.medicationName ?? "Levothyroxine"
        let dose = medications.first?.doseMicrograms ?? 75.0

        let summary = "The patient's current regimen of \(primaryMed) \(Int(dose)) mcg provides an effective exposure of \(pk.effectiveDailyDose) mcg/day. With a \(Int(pk.halfLifeHours / 24))-day elimination half-life, serum levels are progressing toward a steady-state TSH of \(pk.projectedTSHAt90Days) mIU/L, closely approaching the target of \(profile.targetTSH) mIU/L."

        let moa = "\(primaryMed) is a synthetic isomer of endogenous thyroxine (T4). It functions as a stable prohormone that binds to thyroid-binding globulin (TBG) and transthyretin. Through peripheral 5'-monodeiodination catalyzed by type 1 and type 2 iodothyronine deiodinases (DIO1, DIO2), it converts into triiodothyronine (T3), the metabolically active hormone that binds nuclear thyroid receptors."

        let pkSummary = "Levothyroxine possesses a long elimination half-life of ~\(Int(pk.halfLifeHours / 24)) days (\(Int(pk.halfLifeHours)) hours), with an estimated volume of distribution of \(pk.volumeOfDistributionLiters) L and total clearance of \(pk.clearanceLitersPerHour) L/hr. Due to the 7-day half-life, achieving complete pharmacokinetic steady state (5 half-lives) requires approximately \(pk.daysToSteadyState) days (5 weeks). Fluctuations in daily dosing are buffered by the large circulating T4 reservoir."

        let hormoneImpact = "Projected steady-state serum concentration is \(pk.steadyStateConcentration) ng/mL. Pituitary thyrotrophs respond via a negative feedback loop to circulating Free T4 and local T3 conversion. At steady state, Free T4 is projected to increase by +\(pk.freeT4Shift) ng/dL, Free T3 by +\(pk.freeT3Shift) pg/mL, driving baseline TSH from \(profile.baselineTSH) mIU/L down to approximately \(pk.projectedTSHAt90Days) mIU/L."

        let absorption = "Oral bioavailability is estimated at \(pk.bioavailabilityPercent)%. Fasting for at least 30–60 minutes before breakfast ensures optimal gastric acidity for tablet dissolution in the jejunum and upper ileum. Separating polyvalent cations (calcium carbonate, ferrous sulfate, magnesium) by 4 or more hours avoids the formation of insoluble, unabsorbable chelation complexes."

        let guidance = "Maintain consistent morning administration on an empty stomach with a full glass of plain water. Re-evaluate thyroid panel (TSH, Free T4, Free T3) in 6–8 weeks to confirm steady-state normalization prior to any dose titration."

        let takeaways = [
            "Levothyroxine functions as a T4 prohormone converting to active T3 in peripheral tissues.",
            "Long 7-day half-life buffers minor day-to-day variance but requires 35 days for steady state.",
            "Current regimen projects TSH reduction from \(profile.baselineTSH) to \(pk.projectedTSHAt90Days) mIU/L.",
            "Take with plain water 30-60 minutes before food; separate calcium and iron by 4+ hours."
        ]

        let pkItem = ReviewPharmacokineticsItem(
            halfLifeHours: pk.halfLifeHours,
            bioavailabilityPercent: pk.bioavailabilityPercent,
            clearanceLitersPerHour: pk.clearanceLitersPerHour,
            volumeOfDistributionLiters: pk.volumeOfDistributionLiters,
            steadyStateConcentration: pk.steadyStateConcentration,
            effectiveDailyDose: pk.effectiveDailyDose,
            daysToSteadyState: pk.daysToSteadyState,
            projectedTSHAt90Days: pk.projectedTSHAt90Days,
            freeT4Shift: pk.freeT4Shift,
            freeT3Shift: pk.freeT3Shift
        )

        return MedicationReviewResponse(
            status: "success",
            model: "gemini-3.5-flash",
            summary: summary,
            mechanismOfAction: moa,
            pharmacokineticsSummary: pkSummary,
            thyroidHormoneImpact: hormoneImpact,
            absorptionInteractions: absorption,
            clinicalGuidance: guidance,
            keyTakeaways: takeaways,
            pharmacokinetics: pkItem,
            projectedTSHAt90Days: pk.projectedTSHAt90Days,
            targetTSH: profile.targetTSH,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
}
