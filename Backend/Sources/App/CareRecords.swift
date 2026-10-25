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

struct CareExport: Content, Sendable {
    var user: CareIdentity
    var records: [CareRecord]
    var exportedAt: String
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
                throw Abort(.badRequest, reason: "Missing required value.")
            }
            return value
        }
        if kind == "medications" {
            _ = try required("name")
            _ = try required("dose")
            _ = try required("unit")
            _ = try required("frequency")
        }
        if kind == "labs" {
            let analyte = try required("analyte")
            let unit = try required("unit")
            guard let allowed = labUnits[analyte], allowed.contains(unit) else {
                throw Abort(.badRequest, reason: "Unrecognized lab unit for \(analyte).")
            }
            guard let val = Double(try required("result")), val >= 0 else {
                throw Abort(.badRequest, reason: "Lab result must be non-negative.")
            }
        }
        if kind == "messages" {
            _ = try required("body")
        }
    }
}
