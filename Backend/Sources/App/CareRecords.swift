import Foundation
import Vapor

/// Version 1 preserves entered strings and missingness. Server-owned metadata cannot be supplied by clients.
struct CareRecord: Content, Sendable {
    var id: String
    var patientID: String
    var kind: String
    var version: Int
    var recordedAt: String
    var authorID: String
    var fields: [String: String]
}

struct RecordWrite: Content, Sendable {
    var id: String
    var expectedVersion: Int
    var fields: [String: String]
}

struct CareIdentity: Content, Sendable {
    var id: String
    var name: String
    var role: String
}

struct CareSession: Content, Sendable {
    var token: String
    var user: CareIdentity
}

struct CareCredentials: Content {
    var email: String
    var password: String
    var name: String?
}

struct CareInvitation: Content {
    var code: String
}

/// These are capture validations, never diagnostic thresholds or treatment rules.
enum CareValidation {
    static let kinds: Set<String> = ["labs", "symptoms", "weekly-checkins", "medications", "vitals", "meals", "messages", "notes", "requests", "appointments", "care-plans", "administrations", "deletion-requests", "questionnaire"]
    static let labUnits: [String: Set<String>] = [
        "TSH": ["mIU/L", "µIU/mL"], "Free T4": ["ng/dL", "pmol/L"],
        "Free T3": ["pg/mL", "pmol/L"], "Total T4": ["µg/dL", "nmol/L"],
        "Total T3": ["ng/dL", "nmol/L"]
    ]
    static let symptoms = ["fatigue", "concentration", "mood", "sleep", "temperature", "palpitations", "tremor", "bowel", "muscle", "skinHair"]

    static func validate(_ write: RecordWrite, kind: String, role: String) throws {
        guard kinds.contains(kind), UUID(uuidString: write.id) != nil,
              write.expectedVersion >= 0, write.fields.count <= 50,
              write.fields.allSatisfy({ $0.key.count <= 80 && $0.value.count <= 10_000 }) else {
            throw Abort(.badRequest, reason: "Invalid record format.")
        }
        let f = write.fields
        func required(_ key: String) throws -> String {
            guard let value = f[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw Abort(.badRequest, reason: "Please supply \(key).")
            }
            return value
        }
        func number(_ key: String, required isRequired: Bool = false) throws -> Double? {
            guard let value = f[key], !value.isEmpty else {
                if isRequired { throw Abort(.badRequest, reason: "Please supply \(key).") }
                return nil
            }
            guard let result = Double(value), result.isFinite, result >= 0 else {
                throw Abort(.badRequest, reason: "Check \(key); enter a finite, nonnegative number.")
            }
            return result
        }
        func day(_ key: String, required isRequired: Bool = false) throws -> String? {
            guard let value = f[key], !value.isEmpty else {
                if isRequired { throw Abort(.badRequest, reason: "Please confirm \(key).") }
                return nil
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.isLenient = false
            guard let date = formatter.date(from: value), formatter.string(from: date) == value else {
                throw Abort(.badRequest, reason: "Use YYYY-MM-DD for \(key).")
            }
            if kind != "appointments" && kind != "care-plans", date > Date().addingTimeInterval(86_400) {
                throw Abort(.badRequest, reason: "An observation cannot be in the future.")
            }
            return value
        }
        func bounds(_ lower: String, _ upper: String) throws {
            let lo = try number(lower), hi = try number(upper)
            if lo == nil && hi == nil { return }
            guard let lo, let hi, lo < hi else {
                throw Abort(.badRequest, reason: "Supply both interval bounds, with lower less than upper, or leave both blank.")
            }
        }
        switch kind {
        case "questionnaire":
            guard role == "patient", let step = Int(f["step"] ?? ""), (0...4).contains(step),
                  ["in-progress", "complete"].contains(f["status"] ?? "") else {
                throw Abort(.badRequest, reason: "Check the questionnaire progress and status.")
            }

        case "labs":
            let analyte = try required("analyte"), unit = try required("unit")
            guard labUnits[analyte]?.contains(unit) == true else { throw Abort(.badRequest, reason: "Unit does not match the selected analyte.") }
            let original = try required("result")
            let numeric = original.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
            guard let value = Double(numeric), value.isFinite, value >= 0,
                  original.range(of: "^[<>]?[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil else {
                throw Abort(.badRequest, reason: "Enter a decimal result, optionally starting with < or >.")
            }
            let collected = try day("collectedDate"), received = try day("receivedDate")
            if let collected, let received, collected > received { throw Abort(.badRequest, reason: "Received date precedes collection date.") }
            try bounds("referenceLower", "referenceUpper")
            try bounds("targetLower", "targetUpper")
            if !(f["targetLower"] ?? "").isEmpty { _ = try required("targetSource") }
            _ = try required("source")
        case "symptoms":
            _ = try day("observedDate", required: true)
            guard TimeZone(identifier: try required("timezone")) != nil else { throw Abort(.badRequest, reason: "Unknown timezone.") }
            guard f["scaleVersion"] == "custom-0-4-v1" else { throw Abort(.badRequest, reason: "Unknown symptom scale.") }
            guard symptoms.contains(where: { !(f[$0] ?? "").isEmpty }) else {
                throw Abort(.badRequest, reason: "Assess at least one symptom; missing ratings remain unknown.")
            }
            for key in symptoms where !(f[key] ?? "").isEmpty {
                guard let value = Int(f[key] ?? ""), (0...4).contains(value) else { throw Abort(.badRequest, reason: "Ratings must be 0–4 or not assessed.") }
            }
        case "weekly-checkins":
            let start = try day("recallStart", required: true)
            let end = try day("recallEnd", required: true)
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            guard let start, let end, let startDate = formatter.date(from: start), let endDate = formatter.date(from: end),
                  Int(endDate.timeIntervalSince(startDate)) == 6 * 86_400 else { throw Abort(.badRequest, reason: "Use an inclusive seven-day recall window.") }
            _ = try required("body")
        case "medications":
            _ = try required("name")
            let mode = try required("doseMode")
            guard ["exact", "range", "unknown"].contains(mode) else { throw Abort(.badRequest, reason: "Select a dose uncertainty mode.") }
            if mode != "unknown" {
                guard let lo = try number("doseLower", required: true), lo > 0,
                      ["mcg", "mg", "g", "mL", "tablet"].contains(try required("unit")) else { throw Abort(.badRequest, reason: "Check the dose and unit.") }
                if mode == "range" {
                    guard let hi = try number("doseUpper", required: true), hi >= lo else { throw Abort(.badRequest, reason: "Upper dose must be at least the lower dose.") }
                }
            }
            _ = try required("schedule")
        case "vitals":
            let type = try required("type")
            let units = ["weight": ["kg", "lb"], "height": ["cm", "in"], "BMI": ["kg/m²"], "bloodPressure": ["mmHg"], "heartRate": ["bpm"]]
            guard units[type]?.contains(try required("unit")) == true else { throw Abort(.badRequest, reason: "Check the measurement type and unit.") }
            _ = try number("value", required: true)
            if type == "bloodPressure" { _ = try number("diastolic", required: true) }
            _ = try day("observedDate", required: true)
            _ = try required("source")
        case "meals":
            _ = try required("description")
            _ = try day("observedDate", required: true)
            _ = try required("mealTime")
        case "appointments":
            guard role == "clinician" else { throw Abort(.forbidden, reason: "Request an appointment through Care.") }
            _ = try day("observedDate", required: true)
            _ = try required("time")
            guard TimeZone(identifier: try required("timezone")) != nil else { throw Abort(.badRequest, reason: "Unknown timezone.") }
            guard ["confirmed", "cancelled", "completed"].contains(f["status"] ?? "") else { throw Abort(.badRequest, reason: "Unknown appointment status.") }
        case "care-plans":
            guard ["meal", "medication", "daily-symptom", "weekly-checkin"].contains(f["planType"] ?? ""),
                  ["active", "paused", "stopped"].contains(f["status"] ?? ""),
                  TimeZone(identifier: f["timezone"] ?? "") != nil else { throw Abort(.badRequest, reason: "Check the reminder type, status and timezone.") }
            _ = try day("startDate", required: true)
            // Plan dates are schedules, not historical observations.
            _ = try day("endDate")
            if let end = f["endDate"], !end.isEmpty, end < (f["startDate"] ?? "") { throw Abort(.badRequest, reason: "Plan end precedes start.") }
            let times = f["planType"] == "meal" ? ["breakfast", "lunch", "dinner"] : ["time"]
            for key in times {
                let time = try required(key)
                guard time.range(of: "^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", options: .regularExpression) != nil else { throw Abort(.badRequest, reason: "Use HH:mm for reminder times.") }
            }
            if f["planType"] != "meal" && f["planType"] != "daily-symptom" {
                let components = try required("weekdays").split(separator: ",", omittingEmptySubsequences: false)
                let days = components.compactMap { Int($0) }
                guard !days.isEmpty, days.count == components.count, days.allSatisfy({ (1...7).contains($0) }) else { throw Abort(.badRequest, reason: "Select reminder weekdays.") }
            }
            if f["planType"] == "medication" { _ = try required("regimenID"); _ = try required("regimenVersion") }
            if f["acknowledged"] == "true", role != "patient" { throw Abort(.forbidden, reason: "The patient must acknowledge the reminder schedule.") }
        case "administrations":
            guard role == "patient", ["taken", "skipped"].contains(f["status"] ?? "") else { throw Abort(.badRequest) }
            _ = try required("regimenID")
            _ = try required("regimenVersion")
            _ = try day("observedDate", required: true)
            _ = try required("time")
        case "notes":
            guard role == "clinician" else { throw Abort(.forbidden) }
            _ = try required("body")
            guard ["draft", "signed", "amendment"].contains(f["state"] ?? "") else { throw Abort(.badRequest, reason: "Unknown note state.") }
            guard f["visibility"] == "patient" else { throw Abort(.badRequest, reason: "New ordinary notes are patient-visible.") }
        case "requests":
            _ = try required("body")
            let status = f["status"] ?? "Submitted"
            guard ["Submitted", "Received/Assigned", "In review", "Answered", "Closed", "Cancelled", "Clarification needed"].contains(status) else { throw Abort(.badRequest, reason: "Unknown request status.") }
            if status == "Answered" { _ = try required("response") }
        default:
            _ = try required("body")
        }
    }
}

struct CareRecordExport: Content {
    let schemaVersion: Int
    let patientID: String
    let exportedAt: String
    let records: [CareRecord]
    let photos: [MealPhotoResponse]
}
