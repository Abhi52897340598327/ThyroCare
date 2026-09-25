import Foundation
import Vapor

// MARK: - In-Memory Datastore Engine
public final class DataStoreEngine: @unchecked Sendable {
    public static let shared = DataStoreEngine()

    private var users: [String: UserProfile] = [:]
    private var labResults: [String: [LabResultRecord]] = [:]
    private var foodLogs: [String: [FoodLogRecord]] = [:]
    private var medications: [String: [MedicationRecord]] = [:]
    private var reviewEvents: [String: [ClinicalReviewEvent]] = [:]
    private var consents: [String: [ClinicianConsentRecord]] = [:]
    private var familyLinks: [String: [FamilyLinkRecord]] = [:]
    private var reports: [String: GeneratedReportRecord] = [:]
    private let lock = NSLock()

    public init() {
        seedSampleData()
    }

    private func seedSampleData() {
        lock.lock()
        defer { lock.unlock() }

        let p1 = UserProfile(id: "P-1001", email: "abhiraam@thyrocare.com", name: "Abhiraam Venigalla", role: .patient)
        let p2 = UserProfile(id: "P-1002", email: "mother@thyrocare.com", name: "Mother Venigalla", role: .patient)
        let c1 = UserProfile(id: "C-2001", email: "dr.smith@thyrocare.com", name: "Dr. Jane Smith, MD", role: .clinician)

        users[p1.id] = p1
        users[p2.id] = p2
        users[c1.id] = c1

        let labsP1 = [
            LabResultRecord(patientId: p1.id, testDate: "2026-05-10", labName: "Quest Diagnostics", tsh: 2.10, freeT4: 1.35, freeT3: 3.10),
            LabResultRecord(patientId: p1.id, testDate: "2026-07-15", labName: "Quest Diagnostics", tsh: 2.45, freeT4: 1.28, freeT3: 3.05),
            LabResultRecord(patientId: p1.id, testDate: "2026-09-12", labName: "Quest Diagnostics", tsh: 2.80, freeT4: 1.22, freeT3: 2.95)
        ]

        let labsP2 = [
            LabResultRecord(patientId: p2.id, testDate: "2026-05-01", labName: "LabCorp", tsh: 3.40, freeT4: 1.10, freeT3: 2.80),
            LabResultRecord(patientId: p2.id, testDate: "2026-07-10", labName: "LabCorp", tsh: 4.80, freeT4: 0.95, freeT3: 2.60),
            LabResultRecord(patientId: p2.id, testDate: "2026-09-18", labName: "LabCorp", tsh: 7.10, freeT4: 0.82, freeT3: 2.30)
        ]

        labResults[p1.id] = labsP1
        labResults[p2.id] = labsP2

        medications[p1.id] = [
            MedicationRecord(patientId: p1.id, name: "Levothyroxine", genericName: "Levothyroxine Sodium", dose: "75", unit: "mcg", frequency: "Daily", startDate: "2025-01-01")
        ]
        medications[p2.id] = [
            MedicationRecord(patientId: p2.id, name: "Synthroid", genericName: "Levothyroxine Sodium", dose: "50", unit: "mcg", frequency: "Daily", startDate: "2024-06-01")
        ]

        let eventP2 = ClinicalReviewEvent(
            patientId: p2.id,
            eventType: "TSH_RAPID_INCREASE",
            previousValue: 4.80,
            newValue: 7.10,
            daysBetween: 70,
            severity: "review_recommended",
            status: "pending",
            requestedLabs: "Repeat TSH & Free T4",
            recommendedAppointment: "Follow-up within 2 weeks"
        )
        reviewEvents[p2.id] = [eventP2]

        consents[p1.id] = [ClinicianConsentRecord(patientId: p1.id, clinicianId: c1.id, clinicianName: c1.name, permissionLevel: .fullClinicalView)]
        consents[p2.id] = [ClinicianConsentRecord(patientId: p2.id, clinicianId: c1.id, clinicianName: c1.name, permissionLevel: .summaryOnly)]

        familyLinks[p1.id] = [
            FamilyLinkRecord(ownerUserId: p1.id, linkedUserId: p2.id, linkedUserName: p2.name, relationship: "Mother", permissionLevel: .viewSummary)
        ]
    }

    public func getLabs(patientId: String) -> [LabResultRecord] {
        lock.lock()
        defer { lock.unlock() }
        return labResults[patientId] ?? []
    }

    public func addLab(patientId: String, lab: LabResultRecord) {
        lock.lock()
        var current = labResults[patientId] ?? []
        current.append(lab)
        labResults[patientId] = current

        if let event = ClinicalEventDetector.evaluateNewLab(patientId: patientId, newLab: lab, history: current) {
            var events = reviewEvents[patientId] ?? []
            events.insert(event, at: 0)
            reviewEvents[patientId] = events
        }
        lock.unlock()
    }

    public func getMedications(patientId: String) -> [MedicationRecord] {
        lock.lock()
        defer { lock.unlock() }
        return medications[patientId] ?? []
    }

    public func addMedication(patientId: String, med: MedicationRecord) {
        lock.lock()
        defer { lock.unlock() }
        var current = medications[patientId] ?? []
        current.append(med)
        medications[patientId] = current
    }

    public func getFoodLogs(patientId: String) -> [FoodLogRecord] {
        lock.lock()
        defer { lock.unlock() }
        return foodLogs[patientId] ?? []
    }

    public func addFoodLog(patientId: String, food: FoodLogRecord) {
        lock.lock()
        defer { lock.unlock() }
        var current = foodLogs[patientId] ?? []
        current.append(food)
        foodLogs[patientId] = current
    }

    public func getReviewEvents(patientId: String) -> [ClinicalReviewEvent] {
        lock.lock()
        defer { lock.unlock() }
        return reviewEvents[patientId] ?? []
    }

    public func updateReviewEvent(eventId: String, status: String, privateNotes: String?, publicNotes: String?) {
        lock.lock()
        defer { lock.unlock() }
        for (pid, list) in reviewEvents {
            if let idx = list.firstIndex(where: { $0.id == eventId }) {
                var updated = list[idx]
                var newEvent = ClinicalReviewEvent(
                    id: updated.id,
                    patientId: updated.patientId,
                    eventType: updated.eventType,
                    previousValue: updated.previousValue,
                    newValue: updated.newValue,
                    daysBetween: updated.daysBetween,
                    severity: updated.severity,
                    status: status,
                    createdAt: updated.createdAt,
                    clinicianPrivateNotes: privateNotes ?? updated.clinicianPrivateNotes,
                    patientVisibleNotes: publicNotes ?? updated.patientVisibleNotes,
                    requestedLabs: updated.requestedLabs,
                    recommendedAppointment: updated.recommendedAppointment
                )
                reviewEvents[pid]?[idx] = newEvent
                break
            }
        }
    }

    public func getConsents(patientId: String) -> [ClinicianConsentRecord] {
        lock.lock()
        defer { lock.unlock() }
        return consents[patientId] ?? []
    }

    public func addConsent(patientId: String, consent: ClinicianConsentRecord) {
        lock.lock()
        defer { lock.unlock() }
        var current = consents[patientId] ?? []
        current.append(consent)
        consents[patientId] = current
    }

    public func revokeConsent(patientId: String, clinicianId: String) {
        lock.lock()
        defer { lock.unlock() }
        if var current = consents[patientId] {
            current.removeAll { $0.clinicianId == clinicianId }
            consents[patientId] = current
        }
    }

    public func getFamilyLinks(ownerId: String) -> [FamilyLinkRecord] {
        lock.lock()
        defer { lock.unlock() }
        return familyLinks[ownerId] ?? []
    }

    public func addFamilyLink(link: FamilyLinkRecord) {
        lock.lock()
        defer { lock.unlock() }
        var current = familyLinks[link.ownerUserId] ?? []
        current.append(link)
        familyLinks[link.ownerUserId] = current
    }

    public func deleteFamilyLink(linkId: String) {
        lock.lock()
        defer { lock.unlock() }
        for (ownerId, links) in familyLinks {
            familyLinks[ownerId] = links.filter { $0.id != linkId }
        }
    }

    public func getReport(reportId: String) -> GeneratedReportRecord? {
        lock.lock()
        defer { lock.unlock() }
        return reports[reportId]
    }

    public func saveReport(report: GeneratedReportRecord) {
        lock.lock()
        defer { lock.unlock() }
        reports[report.reportId] = report
        reports[report.shareToken] = report
    }

    public func getAllPatientsForClinician(clinicianId: String) -> [UserProfile] {
        lock.lock()
        defer { lock.unlock() }
        return Array(users.values).filter { $0.role == .patient }
    }

    public func getUser(id: String) -> UserProfile? {
        lock.lock()
        defer { lock.unlock() }
        return users[id]
    }
}
