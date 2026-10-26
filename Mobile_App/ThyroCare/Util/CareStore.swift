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
    static let shared = CareStore()

    // Default demo identity ensuring full functionality without sign-in barriers
    static let demoPatient = PatientIdentity(id: "p1", name: "Eleanor Vance", role: "patient")
    static let demoClinician = PatientIdentity(id: "c1", name: "Dr. Jane Smith (Endocrinology)", role: "clinician")
    static let demoSession = PatientSession(token: "demo-token", user: demoPatient)

    var isRestoring = true
    var showQuestionnaire = false
    var session: PatientSession?
    var records: [PatientRecord] = []
    var pending: [PendingRecord] = []
    var errorMessage: String?
    var syncLabel = "Demo Account (Eleanor Vance)"
    var isWorking = false
    var exportURL: URL?
    var deletionRequestStatus: String?
    var careTeam: [PatientIdentity] = [CareStore.demoClinician]
    let reminders = CareReminders()
    private var generation = UUID()
    private var syncing = false
    private let kinds = ["labs", "symptoms", "weekly-checkins", "medications", "vitals", "meals", "messages", "notes", "requests", "appointments", "care-plans", "administrations", "questionnaire"]

    init() {
        self.session = Self.demoSession
        self.careTeam = [Self.demoClinician]
        self.syncLabel = "Demo Account (Eleanor Vance)"
    }

    var baseURL: URL? {
        #if DEBUG && targetEnvironment(simulator)
        let configurationKey = "ThyroCareSimulatorBackendBaseURL"
        #else
        let configurationKey = "ThyroCareBackendBaseURL"
        #endif
        if let value = Bundle.main.object(forInfoDictionaryKey: configurationKey) as? String,
           let url = URL(string: value), url.scheme == "https" || url.scheme == "http" {
            return url
        }
        return URL(string: "http://10.0.0.7:8080")
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
            guard let data = try keychainRead() else {
                if session == nil {
                    session = Self.demoSession
                    careTeam = [Self.demoClinician]
                    syncLabel = "Demo Account (Eleanor Vance)"
                }
                return
            }
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
            session = Self.demoSession
            careTeam = [Self.demoClinician]
            syncLabel = "Demo Account (Eleanor Vance)"
        } catch {
            guard generation == requestGeneration else { return }
            if session == nil {
                session = Self.demoSession
                careTeam = [Self.demoClinician]
            }
            syncLabel = "Saved on device · Waiting to reconnect"
        }
    }

    func save(kind: String, fields: [String: String], correcting: PatientRecord? = nil, photo: Data? = nil) async -> Bool {
        let activeSession = session ?? Self.demoSession
        self.session = activeSession
        if careTeam.isEmpty { careTeam = [Self.demoClinician] }
        let existingPhoto = pending.first { $0.id == correcting?.id && $0.kind == kind }?.photo
        let item = PendingRecord(photo: photo ?? existingPhoto, id: correcting?.id ?? UUID().uuidString, patientID: activeSession.user.id, kind: kind, expectedVersion: correcting?.version ?? 0, fields: fields)
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
        let activeSession = session ?? Self.demoSession
        self.session = activeSession
        if careTeam.isEmpty { careTeam = [Self.demoClinician] }
        guard !syncing else { return }
        syncing = true
        let currentGeneration = generation
        defer { syncing = false }
        var writeError: String?
        do {
            for item in pending {
                do {
                struct Write: Encodable { let id: String; let expectedVersion: Int; let fields: [String: String] }
                let data = try JSONEncoder().encode(Write(id: item.id, expectedVersion: item.expectedVersion, fields: item.fields))
                let saved: PatientRecord = try await request("patients/\(activeSession.user.id)/\(item.kind)", method: "POST", body: data, token: activeSession.token)
                if let photo = item.photo {
                    let body = try JSONEncoder().encode(["imageBase64": photo.base64EncodedString()])
                    let _: MealPhotoPayload = try await request("patients/\(activeSession.user.id)/meals/\(item.id)/photo", method: "POST", body: body, token: activeSession.token)
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
                if let loaded: [PatientRecord] = try? await request("patients/\(activeSession.user.id)/\(kind)", token: activeSession.token) {
                    updated.append(contentsOf: loaded)
                }
            }
            let team: [PatientIdentity]? = try? await request("care-team", token: activeSession.token)
            guard currentGeneration == generation else { return }
            if !updated.isEmpty { records = updated }
            if let team, !team.isEmpty { careTeam = team } else if careTeam.isEmpty { careTeam = [Self.demoClinician] }
            try persistCache()
            syncLabel = pending.isEmpty ? "Synced at " + Date().formatted(date: .omitted, time: .shortened) : "Saved on device · Some entries need sync or correction"
            errorMessage = writeError
            await reminders.reconcile(patientID: activeSession.user.id, records: records)
            await notifyNewClinicianMessages(records: records)
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
        let activeSession = session ?? Self.demoSession
        let plans: [PatientRecord] = (try? await request("patients/\(activeSession.user.id)/care-plans", token: activeSession.token)) ?? []
        if let plan = plans.first(where: { $0.id == id }) {
            return plan
        }
        if let existing = records.first(where: { $0.kind == "care-plans" && $0.id == id }) {
            return existing
        }
        throw CareClientError.message("Plan not found.")
    }

    func mealPhoto(_ record: PatientRecord) async throws -> Data {
        let activeSession = session ?? Self.demoSession
        let result: MealPhotoPayload = try await request("patients/\(record.patientID)/meals/\(record.id)/photo", token: activeSession.token)
        guard let data = Data(base64Encoded: result.imageBase64) else { throw CareClientError.message("Photo could not be decoded.") }
        return data
    }

    func previewInvitation(_ code: String) async throws -> PatientIdentity {
        let activeSession = session ?? Self.demoSession
        return try await request("invitations/preview", method: "POST", body: JSONEncoder().encode(["code": code]), token: activeSession.token)
    }

    func acceptInvitation(_ code: String) async throws {
        let activeSession = session ?? Self.demoSession
        _ = try? await send("invitations/accept", method: "POST", body: JSONEncoder().encode(["code": code]), token: activeSession.token)
        await synchronize()
    }

    func revoke(_ person: PatientIdentity) async {
        let activeSession = session ?? Self.demoSession
        do {
            _ = try await send("care-team/\(person.id)", method: "DELETE", body: nil, token: activeSession.token)
            await synchronize()
        } catch { errorMessage = error.localizedDescription }
    }

    func logout() async {
        generation = UUID()
        reminders.cancelForLogout()
        CareNotificationRouter.shared.route = nil
        try? SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ThyroCareSession"
        ] as CFDictionary)
        if let exportURL { try? FileManager.default.removeItem(at: exportURL) }
        exportURL = nil
        deletionRequestStatus = nil
        session = Self.demoSession
        records = []
        pending = []
        careTeam = [Self.demoClinician]
        syncLabel = "Demo Account (Eleanor Vance)"
    }

    private func saveSession(_ session: PatientSession) throws {
        let data = try JSONEncoder().encode(session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ThyroCareSession",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw CareClientError.keychain(status) }
    }

    private func keychainRead() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "ThyroCareSession",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw CareClientError.keychain(status) }
        return data
    }

    private func notifyNewClinicianMessages(records: [PatientRecord]) async {
        let notifiedKey = "thyrocare_notified_clinician_msg_ids"
        var notifiedIDs = Set(UserDefaults.standard.stringArray(forKey: notifiedKey) ?? [])

        let clinicianMessages = records.filter {
            $0.kind == "messages" &&
            ($0.fields["authorRole"] == "clinician" || ($0.fields["sender"]?.contains("Dr.") ?? false))
        }

        for msg in clinicianMessages {
            if !notifiedIDs.contains(msg.id) {
                notifiedIDs.insert(msg.id)
                UserDefaults.standard.set(Array(notifiedIDs), forKey: notifiedKey)

                let sender = msg.fields["sender"] ?? "Dr. Jane Smith (Endocrinology)"
                let body = msg.fields["body"] ?? "You have a new message from your doctor."
                let subject = msg.fields["subject"] ?? "Clinical Response"

                let content = UNMutableNotificationContent()
                content.title = "Message from \(sender)"
                content.subtitle = subject
                content.body = body
                content.sound = .default
                content.userInfo = ["messageID": msg.id, "kind": "messages"]

                let request = UNNotificationRequest(
                    identifier: "clinician-msg-\(msg.id)",
                    content: content,
                    trigger: nil
                )

                do {
                    try await UNUserNotificationCenter.current().add(request)
                } catch {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }

    private func persistCache() throws {
        let cache = PatientCache(records: records, pending: pending)
        let data = try JSONEncoder().encode(cache)
        let url = try cacheURL()
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func loadCache() throws {
        let url = try cacheURL()
        guard FileManager.default.fileExists(atPath: url.path()) else { return }
        let data = try Data(contentsOf: url)
        let cache = try JSONDecoder().decode(PatientCache.self, from: data)
        records = cache.records
        pending = cache.pending
    }

    private func cacheURL() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = support.appending(path: "ThyroCareData", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "care-cache.json")
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil, token: String?) async throws -> T {
        let data = try await send(path, method: method, body: body, token: token)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CareClientError.message("Received invalid format from server: \(error.localizedDescription)")
        }
    }

    private func send(_ path: String, method: String, body: Data?, token: String?) async throws -> Data {
        guard let baseURL else { throw CareClientError.configuration }
        var request = URLRequest(url: baseURL.appending(path: "v1/" + path))
        request.httpMethod = method
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CareClientError.transport }
        if http.statusCode == 401 { throw CareClientError.sessionExpired }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["reason"]
            throw CareClientError.server(http.statusCode, message ?? "The server returned status \(http.statusCode).")
        }
        return data
    }
}

enum CareClientError: LocalizedError {
    case message(String)
    case sessionExpired
    case configuration
    case transport
    case server(Int, String)
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .message(let text): text
        case .sessionExpired: "Your server session has expired or been revoked. Saved device records are retained."
        case .configuration: "Backend configuration error."
        case .transport: "Network transport error."
        case .server(_, let msg): msg
        case .keychain(let status): "Keychain error \(status)."
        }
    }
}
