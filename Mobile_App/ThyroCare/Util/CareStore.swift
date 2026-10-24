import Foundation
import Observation
import Security
import UserNotifications

struct PatientIdentity: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let role: String
}

struct PatientSession: Codable, Sendable {
    let token: String
    let user: PatientIdentity
}

struct PatientRecord: Codable, Identifiable, Sendable {
    var id: String
    var patientID: String
    var kind: String
    var version: Int
    var recordedAt: String
    var authorID: String
    var fields: [String: String]

    var title: String {
        fields["analyte"] ?? fields["name"] ?? fields["type"] ?? fields["description"] ?? kind
    }
    var observationDate: String {
        fields["collectedDate"].flatMap { $0.isEmpty ? nil : $0 } ?? fields["observedDate"] ?? fields["recallEnd"] ?? "Date not recorded"
    }
}

struct PendingRecord: Codable, Identifiable, Sendable {
    var photo: Data? = nil
    var id: String
    var patientID: String
    var kind: String
    var expectedVersion: Int
    var fields: [String: String]
}

struct MealPhotoPayload: Codable {
    let mealID: String
    let mimeType: String
    let imageBase64: String
}

private struct PatientCache: Codable {
    var records: [PatientRecord]
    var pending: [PendingRecord]
}

@MainActor @Observable
final class CareStore {
    var isRestoring = true
    var showQuestionnaire = false
    var session: PatientSession?
    var records: [PatientRecord] = []
    var pending: [PendingRecord] = []
    var errorMessage: String?
    var syncLabel = "Not connected"
    var isWorking = false
    var exportURL: URL?
    var deletionRequestStatus: String?
    var careTeam: [PatientIdentity] = []
    let reminders = CareReminders()
    private var generation = UUID()
    private var syncing = false
    private let kinds = ["labs", "symptoms", "weekly-checkins", "medications", "vitals", "meals", "messages", "notes", "requests", "appointments", "care-plans", "administrations", "questionnaire"]

    var baseURL: URL? {
        #if DEBUG && targetEnvironment(simulator)
        let configurationKey = "ThyroCareSimulatorBackendBaseURL"
        #else
        let configurationKey = "ThyroCareBackendBaseURL"
        #endif
        guard let value = Bundle.main.object(forInfoDictionaryKey: configurationKey) as? String,
              let url = URL(string: value), url.scheme == "https" || (url.scheme == "http" && url.host == "localhost") else { return nil }
        return url
    }

    var questionnaireRecord: PatientRecord? {
        if let draft = pending.last(where: { $0.kind == "questionnaire" }) {
            return PatientRecord(id: draft.id, patientID: draft.patientID, kind: draft.kind, version: draft.expectedVersion, recordedAt: "", authorID: draft.patientID, fields: draft.fields)
        }
        return records.first { $0.kind == "questionnaire" }
    }

    func entries(_ kind: String) -> [PatientRecord] {
        let filtered = records.filter { $0.kind == kind }
        if kind == "messages" { return filtered }
        return filtered.sorted { $0.observationDate == $1.observationDate ? $0.recordedAt > $1.recordedAt : $0.observationDate > $1.observationDate }
    }

    func authenticate(email: String, password: String, name: String?, register: Bool) async {
        guard !isWorking else { return }
        isWorking = true
        generation = UUID()
        let requestGeneration = generation
        errorMessage = nil
        defer { isWorking = false }
        do {
            let data = try JSONEncoder().encode(["email": email, "password": password, "name": name ?? ""])
            let result: PatientSession = try await request("auth/" + (register ? "register" : "login"), method: "POST", body: data, token: nil)
            guard generation == requestGeneration else { return }
            try saveSession(result)
            showQuestionnaire = register
            session = result
            try loadCache()
            await synchronize()
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        guard isRestoring else { return }
        defer { isRestoring = false }
        let requestGeneration = generation
        do {
            guard let data = try keychainRead() else { return }
            let stored = try JSONDecoder().decode(PatientSession.self, from: data)
            // Restore protected local continuity first; server requests still require a valid token.
            session = stored
            try loadCache()
            syncLabel = "Saved on device · Checking connection"
            isRestoring = false
            let user: PatientIdentity = try await request("me", token: stored.token)
            guard generation == requestGeneration else { return }
            session = PatientSession(token: stored.token, user: user)
            await synchronize()
        } catch CareClientError.sessionExpired {
            guard generation == requestGeneration else { return }
            session = nil
            records = []
            pending = []
            reminders.cancelForLogout()
            errorMessage = "The server has expired or revoked this login. Your saved records are retained; sign in to reconnect."
        } catch {
            guard generation == requestGeneration else { return }
            // A temporary outage must not erase a saved login or protected local records.
            syncLabel = "Saved on device · Waiting to reconnect"
            errorMessage = "Could not connect to verify cloud access. Your saved account and device records are retained."
        }
    }

    func save(kind: String, fields: [String: String], correcting: PatientRecord? = nil, photo: Data? = nil) async -> Bool {
        guard let session else { return false }
        let existingPhoto = pending.first { $0.id == correcting?.id && $0.kind == kind }?.photo
        let item = PendingRecord(photo: photo ?? existingPhoto, id: correcting?.id ?? UUID().uuidString, patientID: session.user.id, kind: kind, expectedVersion: correcting?.version ?? 0, fields: fields)
        let oldPending = pending
        pending.removeAll { $0.id == item.id && $0.kind == kind }
        pending.append(item)
        do { try persistCache() }
        catch { pending = oldPending; errorMessage = "Could not save on this device. Keep this form open and retry."; return false }
        syncLabel = "Saved on device · Waiting to sync"
        await synchronize()
        return true
    }

    func discardPending(_ item: PendingRecord) {
        let previous = pending
        pending.removeAll { $0.id == item.id && $0.kind == item.kind }
        do { try persistCache() }
        catch { pending = previous; errorMessage = "The device draft could not be removed." }
    }

    func synchronize() async {
        guard let session, !syncing else { return }
        syncing = true
        let currentGeneration = generation
        defer { syncing = false }
        var writeError: String?
        do {
            for item in pending {
                do {
                struct Write: Encodable { let id: String; let expectedVersion: Int; let fields: [String: String] }
                let data = try JSONEncoder().encode(Write(id: item.id, expectedVersion: item.expectedVersion, fields: item.fields))
                let saved: PatientRecord = try await request("patients/\(session.user.id)/\(item.kind)", method: "POST", body: data, token: session.token)
                if let photo = item.photo {
                    let body = try JSONEncoder().encode(["imageBase64": photo.base64EncodedString()])
                    let _: MealPhotoPayload = try await request("patients/\(session.user.id)/meals/\(item.id)/photo", method: "POST", body: body, token: session.token)
                }
                guard currentGeneration == generation else { return }
                records.removeAll { $0.id == saved.id && $0.kind == saved.kind }
                records.append(saved)
                if let index = pending.firstIndex(where: { $0.id == item.id && $0.kind == item.kind }) {
                    if pending[index].fields == item.fields && pending[index].photo == item.photo {
                        pending.remove(at: index)
                    } else {
                        // A device edit made during this request must not be discarded by its acknowledgement.
                        pending[index].expectedVersion = saved.version
                    }
                }
                try persistCache()
                } catch {
                    writeError = error.localizedDescription
                }
            }
            var updated: [PatientRecord] = []
            for kind in kinds {
                let loaded: [PatientRecord] = try await request("patients/\(session.user.id)/\(kind)", token: session.token)
                updated.append(contentsOf: loaded)
            }
            let team: [PatientIdentity] = try await request("care-team", token: session.token)
            guard currentGeneration == generation else { return }
            records = updated
            careTeam = team
            try persistCache()
            syncLabel = pending.isEmpty ? "Synced at " + Date().formatted(date: .omitted, time: .shortened) : "Saved on device · Some entries need sync or correction"
            errorMessage = writeError
            await reminders.reconcile(patientID: session.user.id, records: records)
        } catch {
            guard currentGeneration == generation else { return }
            syncLabel = pending.isEmpty ? "Sync failed · Showing saved records" : "Saved on device · Sync failed"
            errorMessage = error.localizedDescription
        }
    }

    func prepareExport() async {
        guard let session else { return }
        let requestGeneration = generation
        do {
            let data = try await send("patients/\(session.user.id)/export", method: "GET", body: nil, token: session.token)
            guard generation == requestGeneration else { return }
            let url = FileManager.default.temporaryDirectory.appending(path: "ThyroCare-records-\(UUID().uuidString).json")
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            if let previous = exportURL { try? FileManager.default.removeItem(at: previous) }
            exportURL = url
        } catch { errorMessage = error.localizedDescription }
    }

    func analyzeMeal(_ record: PatientRecord) async throws -> PatientRecord {
        guard let session, session.user.id == record.patientID else {
            throw CareClientError.message("Sign in as the patient to authorize analysis.")
        }
        if pending.contains(where: { $0.id == record.id && $0.kind == "meals" }) {
            await synchronize()
            guard !pending.contains(where: { $0.id == record.id && $0.kind == "meals" }) else {
                throw CareClientError.message("Your meal photo is still waiting to sync. Retry synchronization before analyzing it.")
            }
        }
        let currentGeneration = generation
        let body = try JSONEncoder().encode(["consent": true])
        let result: PatientRecord = try await request("patients/\(record.patientID)/meals/\(record.id)/analyze", method: "POST", body: body, token: session.token)
        guard generation == currentGeneration else { throw CancellationError() }
        records.removeAll { $0.id == result.id && $0.kind == "meals" }
        records.append(result)
        try persistCache()
        return result
    }

    func requestAccountDeletion() async {
        guard let session else { return }
        do {
            let body = try JSONEncoder().encode(PendingRecord(id: UUID().uuidString, patientID: session.user.id, kind: "deletion-requests", expectedVersion: 0, fields: [:]))
            let _: PatientRecord = try await request("account-deletion", method: "POST", body: body, token: session.token)
            deletionRequestStatus = "Request saved on the server. Deletion has not occurred; operator review and retention handling are still required."
        } catch { errorMessage = error.localizedDescription }
    }

    func currentReminderPlan(id: String) async throws -> PatientRecord {
        guard let session else { throw CareClientError.message("Sign in to review this plan.") }
        let plans: [PatientRecord] = try await request("patients/\(session.user.id)/care-plans", token: session.token)
        guard let plan = plans.first(where: { $0.id == id }) else { throw CareClientError.message("Plan not found.") }
        if plan.fields["planType"] == "medication" {
            let medications: [PatientRecord] = try await request("patients/\(session.user.id)/medications", token: session.token)
            guard medications.contains(where: { $0.id == plan.fields["regimenID"] && String($0.version) == plan.fields["regimenVersion"] }) else {
                throw CareClientError.message("Medication has changed; confirm the schedule again.")
            }
        }
        guard self.session?.token == session.token,
              let timezoneID = plan.fields["timezone"],
              let timezone = TimeZone(identifier: timezoneID) else {
            throw CareClientError.message("The account or plan timezone could not be verified.")
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard let start = plan.fields["startDate"], start <= today,
              (plan.fields["endDate"] ?? "").isEmpty || today <= (plan.fields["endDate"] ?? "") else {
            throw CareClientError.message("This plan is not currently within its active dates.")
        }
        return plan
    }

    func mealPhoto(_ record: PatientRecord) async throws -> Data {
        let result: MealPhotoPayload = try await request("patients/\(record.patientID)/meals/\(record.id)/photo", token: session?.token)
        guard let data = Data(base64Encoded: result.imageBase64) else { throw CareClientError.message("Photo could not be decoded.") }
        return data
    }

    func previewInvitation(_ code: String) async throws -> PatientIdentity {
        try await request("invitations/preview", method: "POST", body: JSONEncoder().encode(["code": code]), token: session?.token)
    }

    func acceptInvitation(_ code: String) async throws {
        try await requestEmpty("invitations/accept", method: "POST", body: JSONEncoder().encode(["code": code]))
        await synchronize()
    }

    func revoke(_ person: PatientIdentity) async {
        do { try await requestEmpty("care-team/\(person.id)", method: "DELETE"); await synchronize() }
        catch { errorMessage = error.localizedDescription }
    }

    func logout() async {
        // Retain protected, account-scoped pending records; clear all in-memory patient data.
        do { try await requestEmpty("auth/logout", method: "POST") }
        catch { errorMessage = "Signed out on this device. Server session revocation could not be confirmed; that session expires automatically." }
        generation = UUID()
        reminders.cancelForLogout()
        CareNotificationRouter.shared.route = nil
        SecItemDelete(keychainQuery() as CFDictionary)
        if let exportURL { try? FileManager.default.removeItem(at: exportURL) }
        exportURL = nil
        deletionRequestStatus = nil
        session = nil
        records = []
        pending = []
        careTeam = []
        syncLabel = "Not connected"
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil, token: String?) async throws -> T {
        let data = try await send(path, method: method, body: body, token: token)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func requestEmpty(_ path: String, method: String, body: Data? = nil) async throws {
        _ = try await send(path, method: method, body: body, token: session?.token)
    }

    private func send(_ path: String, method: String, body: Data?, token: String?) async throws -> Data {
        guard let baseURL else { throw CareClientError.message("Configure a secure care-record server before signing in.") }
        var request = URLRequest(url: baseURL.appending(path: "v1/" + path))
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = path.hasSuffix("/analyze") ? 120 : 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where baseURL.host == "localhost" {
            throw CareClientError.message("The local ThyroCare backend is not reachable. On your Mac, run bash Scripts/start_simulator_backend.sh and keep that terminal open, then retry. (" + error.localizedDescription + ")")
        }
        if let response = response as? HTTPURLResponse, response.statusCode == 401, token != nil {
            throw CareClientError.sessionExpired
        }
        if let response = response as? HTTPURLResponse, response.statusCode == 404, path.hasPrefix("auth/") {
            throw CareClientError.message("Account service is unavailable on the configured server. The server needs the current ThyroCare backend before you can create an account or sign in. Your account details have not been saved.")
        }
        if let response = response as? HTTPURLResponse, response.statusCode == 404, path.hasSuffix("/analyze") {
            struct AnalysisError: Decodable { let reason: String }
            let reason = (try? JSONDecoder().decode(AnalysisError.self, from: data))?.reason
            if reason == nil || reason?.lowercased() == "not found" {
                throw CareClientError.message("The meal-analysis endpoint is missing on this server. Update the ThyroCare backend at \(baseURL.host ?? "the configured address"). Your saved meal has not been deleted.")
            }
        }
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            struct ServerError: Decodable { let reason: String }
            let message = (try? JSONDecoder().decode(ServerError.self, from: data))?.reason
            throw CareClientError.message(message ?? "The server could not complete this request. Your device draft is retained.")
        }
        return data
    }

    private func cacheURL() throws -> URL {
        guard let id = session?.user.id, UUID(uuidString: id) != nil else { throw CareClientError.message("No verified account.") }
        let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: "CareRecords", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var url = folder.appending(path: id + ".json")
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        if FileManager.default.fileExists(atPath: url.path) { try url.setResourceValues(values) }
        return url
    }

    private func persistCache() throws {
        let data = try JSONEncoder().encode(PatientCache(records: records, pending: pending))
        var url = try cacheURL()
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }

    private func loadCache() throws {
        let url = try cacheURL()
        guard FileManager.default.fileExists(atPath: url.path) else { records = []; pending = []; return }
        let cache = try JSONDecoder().decode(PatientCache.self, from: Data(contentsOf: url))
        records = cache.records
        pending = cache.pending
    }

    private func keychainQuery() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "ThyroCare.CareSession", kSecAttrAccount as String: "session"]
    }

    private func saveSession(_ session: PatientSession) throws {
        let data = try JSONEncoder().encode(session)
        let query = keychainQuery()
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw CareClientError.message("Could not securely update your session. Your previous login is retained.")
        }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw CareClientError.message("Could not securely store your session.") }
    }

    private func keychainRead() throws -> Data? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw CareClientError.message("Unlock your device to access the session.") }
        return value as? Data
    }
}

enum CareClientError: LocalizedError {
    case message(String)
    case sessionExpired
    var errorDescription: String? {
        switch self {
        case .message(let text): text
        case .sessionExpired: "Your server session has expired or been revoked. Saved device records are retained."
        }
    }
}
