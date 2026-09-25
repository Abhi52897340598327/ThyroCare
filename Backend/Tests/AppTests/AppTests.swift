import XCTest
@testable import App

final class AppTests: XCTestCase {
    func testThyroidTrendEngineStable() {
        let labs = [
            LabResultRecord(patientId: "P-1", testDate: "2026-01-01", tsh: 2.10),
            LabResultRecord(patientId: "P-1", testDate: "2026-02-01", tsh: 2.15)
        ]
        let result = ThyroidTrendEngine.analyze(patientId: "P-1", labs: labs)
        XCTAssertEqual(result.direction, .stable)
    }

    func testThyroidTrendEngineSignificantIncrease() {
        let labs = [
            LabResultRecord(patientId: "P-1", testDate: "2026-01-01", tsh: 2.0),
            LabResultRecord(patientId: "P-1", testDate: "2026-02-01", tsh: 4.5)
        ]
        let result = ThyroidTrendEngine.analyze(patientId: "P-1", labs: labs)
        XCTAssertEqual(result.direction, .significantIncrease)
    }

    func testClinicalEventDetectorAlert() {
        let prev = LabResultRecord(patientId: "P-1", testDate: "2026-01-01", tsh: 2.0)
        let newLab = LabResultRecord(patientId: "P-1", testDate: "2026-02-01", tsh: 4.8)
        let event = ClinicalEventDetector.evaluateNewLab(patientId: "P-1", newLab: newLab, history: [prev, newLab])
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.eventType, "TSH_RAPID_INCREASE")
    }

    func testReportGeneration() {
        let labs = [LabResultRecord(patientId: "P-1", testDate: "2026-01-01", tsh: 2.1)]
        let meds = [MedicationRecord(patientId: "P-1", name: "Levothyroxine", genericName: "L-Thyroxine", dose: "75", startDate: "2026-01-01")]
        let trend = ThyroidTrendEngine.analyze(patientId: "P-1", labs: labs)
        let ai = AICinicalSummary(trendSummary: "Stable trend", majorChanges: [], possibleAssociations: [], questionsForClinician: [])

        let report = ReportGeneratorService.generate(patientId: "P-1", patientName: "Test Patient", labs: labs, meds: meds, trend: trend, aiSummary: ai)
        XCTAssertFalse(report.htmlReport.isEmpty)
        XCTAssertFalse(report.contentHash.isEmpty)
    }

    func testProviderSearch() {
        let providers = ProviderSearchService.searchEndocrinologists(query: "Jenkins")
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(providers.first?.name, "Dr. Sarah Jenkins, MD")
    }
}
