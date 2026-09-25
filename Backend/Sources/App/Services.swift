import Foundation
import Vapor
import Crypto

// MARK: - Thyroid Trend Engine
public enum ThyroidTrendEngine {
    public static func analyze(patientId: String, labs: [LabResultRecord]) -> ThyroidTrendAnalysis {
        guard !labs.isEmpty else {
            return ThyroidTrendAnalysis(
                patientId: patientId,
                latestTSH: 0.0,
                previousTSH: nil,
                absoluteChange: 0.0,
                percentChange: 0.0,
                rateOfChangePerMonth: 0.0,
                direction: .insufficientData,
                movingAverageTSH: 0.0,
                highestTSH: 0.0,
                lowestTSH: 0.0,
                totalLabCount: 0,
                summary: "No lab results available for analysis."
            )
        }

        let sorted = labs.sorted { $0.testDate < $1.testDate }
        let latest = sorted.last!
        let previous = sorted.count > 1 ? sorted[sorted.count - 2] : nil

        let tshValues = sorted.map { $0.tsh }
        let highest = tshValues.max() ?? latest.tsh
        let lowest = tshValues.min() ?? latest.tsh
        let movingAvg = tshValues.reduce(0.0, +) / Double(tshValues.count)

        let absoluteDiff = previous != nil ? latest.tsh - previous!.tsh : 0.0
        let percentDiff = (previous != nil && previous!.tsh > 0) ? (absoluteDiff / previous!.tsh) * 100.0 : 0.0

        let direction: TrendDirection
        if labs.count < 2 {
            direction = .insufficientData
        } else if percentDiff >= 35.0 {
            direction = .significantIncrease
        } else if percentDiff <= -35.0 {
            direction = .significantDecrease
        } else if percentDiff >= 10.0 {
            direction = .graduallyIncreasing
        } else if percentDiff <= -10.0 {
            direction = .graduallyDecreasing
        } else {
            direction = .stable
        }

        let summary = "Latest TSH is \(String(format: "%.2f", latest.tsh)) mIU/L (moving average \(String(format: "%.2f", movingAvg)) mIU/L). Direction is classified as \(direction.rawValue)."

        return ThyroidTrendAnalysis(
            patientId: patientId,
            latestTSH: latest.tsh,
            previousTSH: previous?.tsh,
            absoluteChange: (absoluteDiff * 100).rounded() / 100,
            percentChange: (percentDiff * 10).rounded() / 10,
            rateOfChangePerMonth: (absoluteDiff * 100).rounded() / 100,
            direction: direction,
            movingAverageTSH: (movingAvg * 100).rounded() / 100,
            highestTSH: highest,
            lowestTSH: lowest,
            totalLabCount: sorted.count,
            summary: summary
        )
    }
}

// MARK: - Critical Change Point Event Detector
public enum ClinicalEventDetector {
    public static func evaluateNewLab(patientId: String, newLab: LabResultRecord, history: [LabResultRecord]) -> ClinicalReviewEvent? {
        guard let previous = history.filter({ $0.id != newLab.id }).sorted(by: { $0.testDate < $1.testDate }).last else {
            return nil
        }

        let diff = newLab.tsh - previous.tsh
        let percentChange = previous.tsh > 0 ? (diff / previous.tsh) * 100.0 : 0.0

        if percentChange >= 40.0 {
            return ClinicalReviewEvent(
                patientId: patientId,
                eventType: "TSH_RAPID_INCREASE",
                previousValue: previous.tsh,
                newValue: newLab.tsh,
                daysBetween: 30,
                severity: "review_recommended",
                status: "pending",
                requestedLabs: "Repeat TSH, Free T4, TPOAb",
                recommendedAppointment: "Schedule follow-up within 2-3 weeks"
            )
        } else if percentChange <= -40.0 {
            return ClinicalReviewEvent(
                patientId: patientId,
                eventType: "TSH_RAPID_DECREASE",
                previousValue: previous.tsh,
                newValue: newLab.tsh,
                daysBetween: 30,
                severity: "review_recommended",
                status: "pending",
                requestedLabs: "Repeat TSH, Free T3/T4",
                recommendedAppointment: "Consider clinical review"
            )
        }

        return nil
    }
}

// MARK: - Vetted Knowledge Base Layer
public enum ThyroidKnowledgeBase {
    public static func inspectFood(_ foodName: String) -> (compounds: [String], interpretation: String) {
        let name = foodName.lowercased()
        if name.contains("broccoli") || name.contains("kale") || name.contains("cabbage") || name.contains("cauliflower") {
            return (
                ["glucosinolates", "goitrogens"],
                "Cruciferous vegetables contain glucosinolates. Raw intake in large amounts may alter iodine organification; cooking minimizes this effect."
            )
        } else if name.contains("soy") || name.contains("tofu") || name.contains("edamame") {
            return (
                ["isoflavones"],
                "Soy isoflavones may interfere with levothyroxine absorption if consumed close to medication dosing."
            )
        } else if name.contains("fish") || name.contains("seaweed") || name.contains("kelp") || name.contains("shrimp") {
            return (
                ["dietary iodine"],
                "Contains natural dietary iodine, an essential substrate for thyroid hormone synthesis."
            )
        } else if name.contains("nut") || name.contains("brazil nut") {
            return (
                ["selenium"],
                "Rich in dietary selenium, an essential cofactor for deiodinase enzyme conversion of T4 to T3."
            )
        }

        return (
            ["standard nutrients"],
            "General nutritional dietary entry with no major isolated thyroid absorption conflict detected."
        )
    }

    public static func inspectMedication(_ medName: String) -> String {
        let name = medName.lowercased()
        if name.contains("levo") || name.contains("synthroid") || name.contains("tirosint") {
            return "Synthetic L-thyroxine replacement. Requires taking on an empty stomach 30-60 minutes before meals and separating 4 hours from iron/calcium."
        } else if name.contains("calcium") || name.contains("iron") || name.contains("multivitamin") {
            return "Cation supplement known to bind levothyroxine in the gastrointestinal tract. Separate administration by at least 4 hours."
        } else if name.contains("omeprazole") || name.contains("pantoprazole") || name.contains("ppi") {
            return "Proton pump inhibitor. Decreased gastric acidity may reduce levothyroxine dissolution and intestinal absorption."
        } else if name.contains("lithium") || name.contains("amiodarone") {
            return "Medication with strong pharmacological effects on thyroid hormone release and organification. Monitor labs regularly."
        }

        return "Standard therapeutic medication. Consult prescribing physician regarding potential thyroid interactions."
    }
}

// MARK: - Report Generator Service
public enum ReportGeneratorService {
    public static func generate(
        patientId: String,
        patientName: String,
        labs: [LabResultRecord],
        meds: [MedicationRecord],
        trend: ThyroidTrendAnalysis,
        aiSummary: AICinicalSummary
    ) -> GeneratedReportRecord {
        let dateRange = labs.isEmpty ? "No labs recorded" : "\(labs.first?.testDate ?? "") to \(labs.last?.testDate ?? "")"

        let labRows = labs.map { lab in
            "<tr><td>\(lab.testDate)</td><td><strong>\(lab.tsh)</strong></td><td>\(lab.freeT4 ?? 0.0)</td><td>\(lab.freeT3 ?? 0.0)</td><td>\(lab.referenceRangeTSH)</td><td>\(lab.labName)</td></tr>"
        }.joined(separator: "\n")

        let medRows = meds.map { med in
            "<li><strong>\(med.name) (\(med.genericName))</strong> - \(med.dose) \(med.unit) (\(med.frequency)). Started \(med.startDate).</li>"
        }.joined(separator: "\n")

        let html = """
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>ThyroCare Thyroid Health Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 30px; color: #0f172a; line-height: 1.5; }
                .header { border-bottom: 3px solid #0f766e; padding-bottom: 12px; margin-bottom: 24px; }
                h1 { color: #0f766e; margin: 0 0 6px; }
                .disclaimer { background: #fef3c7; border: 1px solid #f59e0b; padding: 12px; border-radius: 6px; font-size: 13px; color: #92400e; margin-bottom: 24px; }
                table { width: 100%; border-collapse: collapse; margin: 16px 0; }
                th, td { border: 1px solid #cbd5e1; padding: 10px; text-align: left; font-size: 14px; }
                th { background: #f1f5f9; color: #334155; }
                .box { background: #f8fafc; border: 1px solid #e2e8f0; padding: 16px; border-radius: 8px; margin-bottom: 20px; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>ThyroCare Comprehensive Thyroid Report</h1>
                <p><strong>Patient Name:</strong> \(patientName) | <strong>Patient ID:</strong> \(patientId) | <strong>Date Range:</strong> \(dateRange)</p>
            </div>

            <div class="disclaimer">
                <strong>Medical Disclaimer:</strong> ThyroCare helps organize and summarize thyroid-related health information. It does not diagnose thyroid disease or replace laboratory testing, medication guidance, or professional clinical care.
            </div>

            <div class="box">
                <h3>Longitudinal TSH Trend Summary</h3>
                <p><strong>Status:</strong> \(trend.direction.rawValue) | <strong>Latest TSH:</strong> \(trend.latestTSH) mIU/L | <strong>Moving Average:</strong> \(trend.movingAverageTSH) mIU/L</p>
                <p>\(trend.summary)</p>
            </div>

            <h3>Laboratory History</h3>
            <table>
                <thead>
                    <tr><th>Date</th><th>TSH (mIU/L)</th><th>Free T4 (ng/dL)</th><th>Free T3 (pg/mL)</th><th>Reference Range</th><th>Laboratory</th></tr>
                </thead>
                <tbody>
                    \(labRows)
                </tbody>
            </table>

            <div class="box">
                <h3>Active Medication Timeline</h3>
                <ul>\(medRows)</ul>
            </div>

            <div class="box">
                <h3>Clinical AI Summary (Informational)</h3>
                <p>\(aiSummary.trendSummary)</p>
                <ul>
                    \(aiSummary.possibleAssociations.map { "<li>\($0)</li>" }.joined(separator: "\n"))
                </ul>
            </div>
        </body>
        </html>
        """

        let hashData = SHA256.hash(data: Data(html.utf8))
        let hashString = hashData.compactMap { String(format: "%02x", $0) }.joined()

        return GeneratedReportRecord(
            patientId: patientId,
            patientName: patientName,
            dateRange: dateRange,
            version: 1,
            contentHash: hashString,
            summaryText: aiSummary.trendSummary,
            htmlReport: html
        )
    }
}

// MARK: - Provider Search Service
public enum ProviderSearchService {
    public static func searchEndocrinologists(query: String? = nil) -> [EndocrinologistProvider] {
        let mockProviders = [
            EndocrinologistProvider(
                name: "Dr. Sarah Jenkins, MD",
                specialty: "Endocrinology & Thyroid Care",
                distanceMiles: 1.4,
                rating: 4.9,
                reviewCount: 214,
                address: "450 Medical Center Blvd, Suite 300, Boston, MA",
                phone: "(615) 555-0192",
                website: "https://www.bostonthyroidcare.org",
                directionsURL: "https://maps.apple.com/?q=450+Medical+Center+Blvd+Boston+MA",
                bookingURL: "https://www.bostonthyroidcare.org/book"
            ),
            EndocrinologistProvider(
                name: "Dr. Michael Chen, MD",
                specialty: "Thyroid & Metabolic Disorders",
                distanceMiles: 3.1,
                rating: 4.8,
                reviewCount: 189,
                address: "880 Harrison Ave, Suite 102, Boston, MA",
                phone: "(615) 555-0341",
                website: "https://www.mgh.harvard.edu/endocrinology",
                directionsURL: "https://maps.apple.com/?q=880+Harrison+Ave+Boston+MA",
                bookingURL: "https://www.mgh.harvard.edu/endocrinology/appointments"
            ),
            EndocrinologistProvider(
                name: "Dr. Elena Rostova, MD, PhD",
                specialty: "Thyroid Neoplasia & Autoimmune Thyroiditis",
                distanceMiles: 4.8,
                rating: 4.7,
                reviewCount: 142,
                address: "15 Park Plaza, Suite 500, Boston, MA",
                phone: "(615) 555-0887",
                website: "https://www.brighamandwomens.org/endocrinology",
                directionsURL: "https://maps.apple.com/?q=15+Park+Plaza+Boston+MA",
                bookingURL: "https://www.brighamandwomens.org/endocrinology/schedule"
            )
        ]

        guard let q = query?.lowercased(), !q.isEmpty else {
            return mockProviders.sorted { $0.distanceMiles < $1.distanceMiles }
        }

        return mockProviders.filter { provider in
            provider.name.lowercased().contains(q) || provider.address.lowercased().contains(q) || provider.specialty.lowercased().contains(q)
        }.sorted { $0.distanceMiles < $1.distanceMiles }
    }
}

// MARK: - Audit Logger
public final class AuditLogger: @unchecked Sendable {
    public static let shared = AuditLogger()
    private var logs: [AuditLogEntry] = []
    private let lock = NSLock()

    public func log(actorUserId: String, actorRole: UserRole, patientId: String, resourceType: String, action: String, ipMetadata: String = "127.0.0.1") {
        lock.lock()
        let entry = AuditLogEntry(actorUserId: actorUserId, actorRole: actorRole, patientId: patientId, resourceType: resourceType, action: action, ipMetadata: ipMetadata)
        logs.insert(entry, at: 0)
        if logs.count > 200 { logs.removeLast(logs.count - 200) }
        lock.unlock()
    }

    public func recentLogs() -> [AuditLogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return logs
    }
}

// MARK: - AI Summarizer Service
public enum AISummarizerService {
    public static func summarize(patientName: String, labs: [LabResultRecord], meds: [MedicationRecord], foods: [FoodLogRecord]) -> AICinicalSummary {
        let trend = ThyroidTrendEngine.analyze(patientId: patientName, labs: labs)

        var changes: [String] = []
        if labs.count >= 2 {
            changes.append("TSH shifted from \(trend.previousTSH ?? 0.0) to \(trend.latestTSH) mIU/L (\(trend.percentChange)% change).")
        }
        if let lastMed = meds.last {
            changes.append("Active thyroid medication recorded: \(lastMed.name) \(lastMed.dose) \(lastMed.unit) (\(lastMed.frequency)).")
        }

        var associations: [String] = []
        if !foods.isEmpty {
            associations.append("Dietary logs contain entries with potential nutrient absorption interactions (e.g. cruciferous or calcium intake).")
        }
        associations.append("Medication dose timing relative to food intake may affect levothyroxine intestinal absorption.")

        return AICinicalSummary(
            trendSummary: "Based on longitudinal labs, TSH is classified as '\(trend.direction.rawValue)'. Moving average is \(trend.movingAverageTSH) mIU/L across \(labs.count) lab records.",
            majorChanges: changes,
            possibleAssociations: associations,
            questionsForClinician: [
                "Should repeat TSH and Free T4 labs be scheduled to confirm current trend stability?",
                "Is medication dosing timing optimal relative to breakfast and dietary supplements?"
            ],
            confidence: 0.89
        )
    }
}
