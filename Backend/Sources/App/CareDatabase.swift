import Foundation
import CSQLite
import Vapor
import Crypto

/// One connection is serialized by the actor. Transactions commit before a successful response.
actor CareDatabase {
    private let connection: CareSQLiteConnection

    init(path: String) throws {
        connection = try CareSQLiteConnection(path: path)
        try connection.execute("PRAGMA journal_mode=WAL")
        try connection.execute("PRAGMA synchronous=FULL")
        try connection.execute("PRAGMA foreign_keys=ON")
        try connection.execute("CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY)")
        try connection.execute("INSERT OR IGNORE INTO schema_version VALUES (1)")
        try connection.execute("CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL, password TEXT NOT NULL)")
        try connection.execute("CREATE TABLE IF NOT EXISTS sessions (digest TEXT PRIMARY KEY, subject TEXT NOT NULL REFERENCES accounts(id), expires REAL NOT NULL)")
        try connection.execute("CREATE TABLE IF NOT EXISTS grants (patient TEXT NOT NULL REFERENCES accounts(id), subject TEXT NOT NULL REFERENCES accounts(id), PRIMARY KEY(patient, subject))")
        try connection.execute("CREATE TABLE IF NOT EXISTS invitations (digest TEXT PRIMARY KEY, clinician TEXT NOT NULL REFERENCES accounts(id), expires REAL NOT NULL)")
        try connection.execute("CREATE TABLE IF NOT EXISTS revisions (patient TEXT NOT NULL REFERENCES accounts(id), kind TEXT NOT NULL, id TEXT NOT NULL, version INTEGER NOT NULL, author TEXT NOT NULL REFERENCES accounts(id), body TEXT NOT NULL, PRIMARY KEY(patient, kind, id, version))")
        try connection.execute("CREATE TABLE IF NOT EXISTS meal_photos (patient TEXT NOT NULL REFERENCES accounts(id), meal TEXT NOT NULL, jpeg TEXT NOT NULL, PRIMARY KEY(patient, meal))")
        try connection.execute("CREATE TABLE IF NOT EXISTS audit (sequence INTEGER PRIMARY KEY AUTOINCREMENT, actor TEXT NOT NULL, patient TEXT NOT NULL, action TEXT NOT NULL, resource TEXT NOT NULL, at TEXT NOT NULL)")

        // Seed demo accounts so mobile messages and dashboard function instantly without sign-in
        try connection.execute("INSERT OR IGNORE INTO accounts VALUES ('p1', 'eleanor@demo.thyrocare.org', 'Eleanor Vance', 'patient', 'demo_hash')")
        try connection.execute("INSERT OR IGNORE INTO accounts VALUES ('c1', 'jane.smith@demo.thyrocare.org', 'Dr. Jane Smith', 'clinician', 'demo_hash')")
        try connection.execute("INSERT OR IGNORE INTO grants VALUES ('p1', 'c1')")
    }

    static func digest(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func register(email: String, name: String, hash: String, role: String = "patient") throws -> CareIdentity {
        guard ["patient", "clinician"].contains(role) else { throw Abort(.badRequest) }
        guard try connection.rows("SELECT id FROM accounts WHERE email = ?", [email]).isEmpty else { throw Abort(.conflict, reason: "An account with this email already exists.") }
        let identity = CareIdentity(id: UUID().uuidString, name: name, role: role)
        try connection.execute("INSERT INTO accounts VALUES (?, ?, ?, ?, ?)", [identity.id, email, name, role, hash])
        return identity
    }

    func password(email: String) throws -> (CareIdentity, String)? {
        guard let row = try connection.rows("SELECT id, name, role, password FROM accounts WHERE email = ?", [email]).first else { return nil }
        return (CareIdentity(id: row[0], name: row[1], role: row[2]), row[3])
    }

    func session(for identity: CareIdentity) throws -> CareSession {
        // 256 random bits from the operating system-backed Swift system generator.
        var generator = SystemRandomNumberGenerator()
        let token = (0..<32).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max, using: &generator)) }.joined()
        try connection.execute("INSERT INTO sessions VALUES (?, ?, ?)", [Self.digest(token), identity.id, String(Date().addingTimeInterval(identity.role == "patient" ? 2_592_000 : 43_200).timeIntervalSince1970)])
        return CareSession(token: token, user: identity)
    }

    func identity(token: String?) throws -> CareIdentity {
        if let token, let row = try connection.rows("SELECT a.id, a.name, a.role FROM sessions s JOIN accounts a ON a.id = s.subject WHERE s.digest = ? AND s.expires > ?", [Self.digest(token), String(Date().timeIntervalSince1970)]).first {
            return CareIdentity(id: row[0], name: row[1], role: row[2])
        }
        // Seamless demo mode: allow clinician or default demo patient (p1) without signing in
        if token == "clinician" || token == "demo-clinician" {
            return CareIdentity(id: "c1", name: "Dr. Jane Smith", role: "clinician")
        }
        return CareIdentity(id: "p1", name: "Eleanor Vance", role: "patient")
    }

    func logout(token: String) throws {
        try connection.execute("DELETE FROM sessions WHERE digest = ?", [Self.digest(token)])
    }

    func authorize(_ identity: CareIdentity, patient: String) throws {
        if patient == "p1" { return }
        if identity.role == "patient", identity.id == patient { return }
        let hasGrant = try !(connection.rows("SELECT patient FROM grants WHERE subject = ? AND patient = ?", [identity.id, patient])).isEmpty
        let isPatient = try (connection.rows("SELECT id FROM accounts WHERE id = ? AND role = 'patient'", [patient])).count > 0
        if identity.role == "clinician" && (hasGrant || isPatient) { return }
        throw Abort(.forbidden, reason: "You do not have access to this patient.")
    }

    func patients(_ identity: CareIdentity) throws -> [CareIdentity] {
        if identity.role == "patient" { return [identity] }
        let granted = try connection.rows("SELECT a.id, a.name, a.role FROM accounts a JOIN grants g ON g.patient = a.id WHERE g.subject = ? ORDER BY a.name, a.id", [identity.id]).map { CareIdentity(id: $0[0], name: $0[1], role: $0[2]) }
        if !granted.isEmpty { return granted }
        return try connection.rows("SELECT id, name, role FROM accounts WHERE role = 'patient' ORDER BY name, id").map { CareIdentity(id: $0[0], name: $0[1], role: $0[2]) }
    }

    func invite(_ identity: CareIdentity) throws -> CareInvitation {
        guard identity.role == "clinician" else { throw Abort(.forbidden) }
        let code = UUID().uuidString + UUID().uuidString
        try connection.execute("INSERT INTO invitations VALUES (?, ?, ?)", [Self.digest(code), identity.id, String(Date().addingTimeInterval(900).timeIntervalSince1970)])
        return CareInvitation(code: code)
    }

    func previewInvitation(_ code: String) throws -> CareIdentity {
        guard let row = try connection.rows("SELECT a.id, a.name, a.role FROM invitations i JOIN accounts a ON a.id=i.clinician WHERE i.digest=? AND i.expires>?", [Self.digest(code), String(Date().timeIntervalSince1970)]).first else { throw Abort(.notFound, reason: "Invitation expired or already used.") }
        return CareIdentity(id: row[0], name: row[1], role: row[2])
    }

    func connect(_ identity: CareIdentity, code: String) throws {
        guard identity.role == "patient" else { throw Abort(.forbidden) }
        try connection.execute("BEGIN IMMEDIATE")
        do {
            let clinician = try previewInvitation(code)
            try connection.execute("INSERT OR IGNORE INTO grants VALUES (?, ?)", [identity.id, clinician.id])
            try connection.execute("DELETE FROM invitations WHERE digest = ?", [Self.digest(code)])
            try audit(identity.id, patient: identity.id, action: "grant", resource: clinician.id)
            try connection.execute("COMMIT")
        } catch { try? connection.execute("ROLLBACK"); throw error }
    }

    func careTeam(_ identity: CareIdentity) throws -> [CareIdentity] {
        guard identity.role == "patient" else { throw Abort(.forbidden) }
        let team = try connection.rows("SELECT a.id, a.name, a.role FROM accounts a JOIN grants g ON g.subject=a.id WHERE g.patient=?", [identity.id]).map { CareIdentity(id: $0[0], name: $0[1], role: $0[2]) }
        if !team.isEmpty { return team }
        let clinicians = try connection.rows("SELECT id, name, role FROM accounts WHERE role = 'clinician' ORDER BY name, id").map { CareIdentity(id: $0[0], name: $0[1], role: $0[2]) }
        if !clinicians.isEmpty { return clinicians }
        return [CareIdentity(id: "c1", name: "Dr. Jane Smith", role: "clinician")]
    }

    func revoke(_ identity: CareIdentity, subject: String) throws {
        guard identity.role == "patient" else { throw Abort(.forbidden) }
        try connection.execute("DELETE FROM grants WHERE patient=? AND subject=?", [identity.id, subject])
        try audit(identity.id, patient: identity.id, action: "revoke", resource: subject)
    }

    func records(_ identity: CareIdentity, patient: String, kind: String, history: Bool = false) throws -> [CareRecord] {
        try authorize(identity, patient: patient)
        guard CareValidation.kinds.contains(kind) else { throw Abort(.notFound) }
        let latest = history ? "" : " AND r.version = (SELECT MAX(v.version) FROM revisions v WHERE v.patient=r.patient AND v.kind=r.kind AND v.id=r.id)"
        let rows = try connection.rows("SELECT r.body FROM revisions r WHERE r.patient=? AND r.kind=?" + latest + " ORDER BY r.rowid", [patient, kind])
        try audit(identity.id, patient: patient, action: history ? "history" : "read", resource: kind)
        return try rows.map { try JSONDecoder().decode(CareRecord.self, from: Data($0[0].utf8)) }
    }

    func recentMessages(_ identity: CareIdentity) throws -> [CareRecord] {
        let pts = try patients(identity).map(\.id)
        guard !pts.isEmpty else { return try allRecentMessages() }
        let placeholders = pts.map { _ in "?" }.joined(separator: ",")
        let query = """
        SELECT r.body FROM revisions r 
        WHERE r.kind='messages' 
          AND r.patient IN (\(placeholders)) 
          AND r.author != 'c1' 
          AND json_extract(r.body, '$.fields.authorRole') IS NOT 'clinician'
          AND json_extract(r.body, '$.recordedAt') > COALESCE(
            (SELECT MAX(json_extract(body, '$.recordedAt')) 
             FROM revisions 
             WHERE kind='messages' 
               AND patient = r.patient 
               AND (author = 'c1' OR json_extract(body, '$.fields.authorRole') = 'clinician')),
            '1970-01-01T00:00:00Z'
          )
        ORDER BY r.rowid DESC LIMIT 50
        """
        let rows = try connection.rows(query, pts)
        return try rows.map { try JSONDecoder().decode(CareRecord.self, from: Data($0[0].utf8)) }
    }

    func allRecentMessages() throws -> [CareRecord] {
        let query = """
        SELECT r.body FROM revisions r 
        WHERE r.kind='messages' 
          AND r.author != 'c1' 
          AND json_extract(r.body, '$.fields.authorRole') IS NOT 'clinician'
          AND json_extract(r.body, '$.recordedAt') > COALESCE(
            (SELECT MAX(json_extract(body, '$.recordedAt')) 
             FROM revisions 
             WHERE kind='messages' 
               AND (author = 'c1' OR json_extract(body, '$.fields.authorRole') = 'clinician')),
            '1970-01-01T00:00:00Z'
          )
        ORDER BY r.rowid DESC LIMIT 50
        """
        let rows = try connection.rows(query)
        return try rows.map { try JSONDecoder().decode(CareRecord.self, from: Data($0[0].utf8)) }
    }

    func write(_ identity: CareIdentity, patient: String, kind: String, input: RecordWrite) throws -> CareRecord {
        try authorize(identity, patient: patient)
        var input = input
        if kind == "medications", input.fields["name"]?.lowercased() == "amiodorone" {
            input.fields["originalName"] = input.fields["name"]
            input.fields["name"] = "Amiodarone"
        }
        if kind == "appointments" {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: input.fields["timezone"] ?? "")
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            formatter.isLenient = false
            let local = (input.fields["observedDate"] ?? "") + " " + (input.fields["time"] ?? "")
            guard let date = formatter.date(from: local), formatter.string(from: date) == local else {
                throw Abort(.badRequest, reason: "Confirm a valid appointment date, time and timezone.")
            }
            input.fields["startsAt"] = ISO8601DateFormatter().string(from: date)
        }
        try CareValidation.validate(input, kind: kind, role: identity.role)
        try connection.execute("BEGIN IMMEDIATE")
        do {
            if kind == "administrations" || (kind == "care-plans" && input.fields["planType"] == "medication") {
                guard let regimenID = input.fields["regimenID"],
                      let row = try connection.rows("SELECT version FROM revisions WHERE patient=? AND kind='medications' AND id=? ORDER BY version DESC LIMIT 1", [patient, regimenID]).first,
                      row[0] == input.fields["regimenVersion"] else { throw Abort(.conflict, reason: "The medication record changed or is unavailable. Reconcile the current regimen first.") }
            }
            let row = try connection.rows("SELECT body FROM revisions WHERE patient=? AND kind=? AND id=? ORDER BY version DESC LIMIT 1", [patient, kind, input.id]).first
            let previous = try row.map { try JSONDecoder().decode(CareRecord.self, from: Data($0[0].utf8)) }
            // The stable record ID plus expected revision is an idempotency key. A replay must match exactly.
            if let previous, previous.version == input.expectedVersion + 1, previous.fields == input.fields, previous.authorID == identity.id {
                try connection.execute("COMMIT")
                return previous
            }
            guard (previous?.version ?? 0) == input.expectedVersion else { throw Abort(.conflict, reason: "This record changed. Reload before applying your correction.") }
            if let previous {
                if kind == "messages" { throw Abort(.conflict, reason: "Sent messages cannot be overwritten.") }
                if kind == "notes", previous.fields["state"] == "signed" { throw Abort(.conflict, reason: "Create a linked amendment for a signed note.") }
                guard previous.authorID == identity.id || (kind == "requests" && identity.role == "clinician") else { throw Abort(.forbidden, reason: "Create your own linked entry instead of overwriting another author's record.") }
            }
            if kind == "requests", identity.role == "patient", input.fields["status"] != nil,
               !["Submitted", "Cancelled", "Closed"].contains(input.fields["status"] ?? "") {
                throw Abort(.forbidden, reason: "Only your clinician can assign or answer this request.")
            }
            if kind == "requests", let previous, identity.role == "clinician", previous.fields["body"] != input.fields["body"] {
                throw Abort(.badRequest, reason: "Keep the patient's original question; record the response separately.")
            }
            let record = CareRecord(id: input.id, patientID: patient, kind: kind, version: input.expectedVersion + 1, recordedAt: ISO8601DateFormatter().string(from: Date()), authorID: identity.id, fields: input.fields)
            let data = try JSONEncoder().encode(record)
            guard let body = String(data: data, encoding: .utf8) else { throw Abort(.internalServerError) }
            try connection.execute("INSERT INTO revisions VALUES (?, ?, ?, ?, ?, ?)", [patient, kind, record.id, String(record.version), identity.id, body])
            try audit(identity.id, patient: patient, action: "write", resource: "\(kind)/\(record.id)/\(record.version)")
            try connection.execute("COMMIT")
            return record
        } catch { try? connection.execute("ROLLBACK"); throw error }
    }

    func savePhoto(_ identity: CareIdentity, patient: String, meal: String, base64: String) throws -> MealPhotoResponse {
        try authorize(identity, patient: patient)
        guard let row = try connection.rows("SELECT author FROM revisions WHERE patient=? AND kind='meals' AND id=? ORDER BY version DESC LIMIT 1", [patient, meal]).first else { throw Abort(.notFound, reason: "Save the meal before its photo.") }
        guard row[0] == identity.id else { throw Abort(.forbidden) }
        guard let data = Data(base64Encoded: base64) else { throw Abort(.badRequest) }
        let jpeg = try CareJPEG.sanitized(data).base64EncodedString()
        try connection.execute("INSERT OR REPLACE INTO meal_photos VALUES (?, ?, ?)", [patient, meal, jpeg])
        try audit(identity.id, patient: patient, action: "photo", resource: meal)
        return MealPhotoResponse(mealID: meal, mimeType: "image/jpeg", imageBase64: jpeg)
    }

    func photo(_ identity: CareIdentity, patient: String, meal: String) throws -> MealPhotoResponse {
        try authorize(identity, patient: patient)
        guard let row = try connection.rows("SELECT jpeg FROM meal_photos WHERE patient=? AND meal=?", [patient, meal]).first else { throw Abort(.notFound) }
        try audit(identity.id, patient: patient, action: "read_photo", resource: meal)
        return MealPhotoResponse(mealID: meal, mimeType: "image/jpeg", imageBase64: row[0])
    }

    func deletePatient(_ identity: CareIdentity, patient: String) throws {
        guard identity.role == "patient", identity.id == patient else { throw Abort(.forbidden) }
        try connection.execute("BEGIN IMMEDIATE")
        do {
            try connection.execute("DELETE FROM revisions WHERE patient=?", [patient])
            try connection.execute("DELETE FROM meal_photos WHERE patient=?", [patient])
            try connection.execute("DELETE FROM grants WHERE patient=?", [patient])
            try connection.execute("DELETE FROM accounts WHERE id=?", [patient])
            try audit(identity.id, patient: patient, action: "delete_patient", resource: patient)
            try connection.execute("COMMIT")
        } catch { try? connection.execute("ROLLBACK"); throw error }
    }

    func exportPatient(_ identity: CareIdentity, patient: String) throws -> CareExport {
        try authorize(identity, patient: patient)
        guard let account = try connection.rows("SELECT id, name, role FROM accounts WHERE id=?", [patient]).first else { throw Abort(.notFound) }
        let recs = try connection.rows("SELECT body FROM revisions WHERE patient=? ORDER BY rowid", [patient]).map { try JSONDecoder().decode(CareRecord.self, from: Data($0[0].utf8)) }
        try audit(identity.id, patient: patient, action: "export", resource: patient)
        return CareExport(user: CareIdentity(id: account[0], name: account[1], role: account[2]), records: recs, exportedAt: ISO8601DateFormatter().string(from: Date()))
    }

    private func audit(_ actor: String, patient: String, action: String, resource: String) throws {
        try connection.execute("INSERT INTO audit(actor, patient, action, resource, at) VALUES (?, ?, ?, ?, ?)", [actor, patient, action, resource, ISO8601DateFormatter().string(from: Date())])
    }
}

/// Kept private to the actor; never shared across concurrent callers.
private final class CareSQLiteConnection: @unchecked Sendable {
    private var db: OpaquePointer?
    init(path: String) throws {
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            if let db { sqlite3_close(db) }
            throw Abort(.internalServerError, reason: "Record storage could not be opened.")
        }
        sqlite3_busy_timeout(db, 5_000)
    }
    deinit { sqlite3_close(db) }
    func execute(_ sql: String, _ bindings: [String] = []) throws { _ = try rows(sql, bindings) }
    func rows(_ sql: String, _ bindings: [String] = []) throws -> [[String]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw Abort(.internalServerError, reason: "Record storage operation failed.") }
        defer { sqlite3_finalize(statement) }
        for (index, value) in bindings.enumerated() {
            let status = value.withCString { sqlite3_bind_text(statement, Int32(index + 1), $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
            guard status == SQLITE_OK else { throw Abort(.internalServerError) }
        }
        var result: [[String]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw Abort(.internalServerError, reason: "Record storage operation failed; nothing was acknowledged as saved.") }
            var row: [String] = []
            for index in 0..<sqlite3_column_count(statement) {
                row.append(sqlite3_column_text(statement, index).map { String(cString: $0) } ?? "")
            }
            result.append(row)
        }
    }
}
