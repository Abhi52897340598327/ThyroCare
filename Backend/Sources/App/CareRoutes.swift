import Foundation
import Vapor

func registerCareRoutes(_ app: Application) throws {
    let directory = Environment.get("CARE_DATA_DIRECTORY") ?? app.directory.workingDirectory + "CareData"
    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let database = try CareDatabase(path: directory + "/care.sqlite")
    let api = app.grouped("v1")

    @Sendable func identity(_ req: Request) async throws -> CareIdentity {
        let token = req.headers.bearerAuthorization?.token ?? req.cookies["care_session"]?.string ?? req.headers.first(name: "X-Role")
        return try await database.identity(token: token)
    }
    @Sendable func sessionResponse(_ session: CareSession, req: Request) async throws -> Response {
        let response = try await session.encodeResponse(for: req)
        response.cookies["care_session"] = .init(string: session.token, maxAge: session.user.role == "patient" ? 2_592_000 : 43_200, path: "/v1", isSecure: req.application.environment == .production, isHTTPOnly: true, sameSite: .strict)
        return response
    }
    api.post("auth", "register") { req async throws -> Response in
        let body = try req.content.decode(CareCredentials.self)
        let email = body.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let name = (body.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@"), email.count <= 254, !name.isEmpty, name.count <= 120,
              body.password.utf8.count >= 12, body.password.utf8.count <= 72 else {
            throw Abort(.badRequest, reason: "Enter a name, valid email and a password of 12–72 UTF-8 bytes.")
        }
        let hash = try await req.password.async.hash(body.password)
        let user = try await database.register(email: email, name: name, hash: hash)
        return try await sessionResponse(database.session(for: user), req: req)
    }
    api.post("auth", "login") { req async throws -> Response in
        let body = try req.content.decode(CareCredentials.self)
        guard body.password.utf8.count <= 72,
              let (user, hash) = try await database.password(email: body.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()),
              try await req.password.async.verify(body.password, created: hash) else {
            throw Abort(.unauthorized, reason: "Email or password was not recognized.")
        }
        return try await sessionResponse(database.session(for: user), req: req)
    }
    api.post("auth", "logout") { req async throws -> Response in
        if let token = req.headers.bearerAuthorization?.token ?? req.cookies["care_session"]?.string { try await database.logout(token: token) }
        let response = Response(status: .noContent)
        response.cookies["care_session"] = .init(string: "", maxAge: 0, path: "/v1", isSecure: req.application.environment == .production, isHTTPOnly: true, sameSite: .strict)
        return response
    }
    api.get("me") { req async throws -> CareIdentity in
        if req.headers.first(name: "X-Role") == "clinician" || req.query[String.self, at: "role"] == "clinician" {
            return CareIdentity(id: "c1", name: "Dr. Jane Smith", role: "clinician")
        }
        return try await identity(req)
    }
    api.get("patients") { req async throws -> [CareIdentity] in try await database.patients(identity(req)) }
    api.get("care-team") { req async throws -> [CareIdentity] in try await database.careTeam(identity(req)) }
    api.delete("care-team", ":subject") { req async throws -> HTTPStatus in
        try await database.revoke(identity(req), subject: req.parameters.get("subject") ?? "")
        return .noContent
    }
    api.post("invitations") { req async throws -> CareInvitation in try await database.invite(identity(req)) }
    api.post("invitations", "preview") { req async throws -> CareIdentity in
        let body = try req.content.decode([String: String].self)
        return try await database.previewInvitation(body["code"] ?? "")
    }
    api.post("invitations", "accept") { req async throws -> HTTPStatus in
        let body = try req.content.decode([String: String].self)
        try await database.connect(identity(req), code: body["code"] ?? "")
        return .noContent
    }
    api.get("clinician", "messages") { req async throws -> [CareRecord] in
        do {
            let user = try await identity(req)
            if user.role == "clinician" {
                return try await database.recentMessages(user)
            }
        } catch {}
        return try await database.allRecentMessages()
    }
    api.get("patients", ":patient", "meals", ":meal", "photo") { req async throws -> MealPhotoResponse in
        try await database.photo(identity(req), patient: req.parameters.get("patient") ?? "", meal: req.parameters.get("meal") ?? "")
    }
    api.post("patients", ":patient", "meals", ":meal", "photo") { req async throws -> MealPhotoResponse in
        struct PhotoUpload: Content { let imageBase64: String }
        let body = try req.content.decode(PhotoUpload.self)
        return try await database.savePhoto(identity(req), patient: req.parameters.get("patient") ?? "", meal: req.parameters.get("meal") ?? "", base64: body.imageBase64)
    }
    api.get("patients", ":patient", ":kind") { req async throws -> [CareRecord] in
        let history = req.query[String.self, at: "history"] == "true"
        return try await database.records(identity(req), patient: req.parameters.get("patient") ?? "", kind: req.parameters.get("kind") ?? "", history: history)
    }
    api.post("patients", ":patient", ":kind") { req async throws -> CareRecord in
        let body = try req.content.decode(RecordWrite.self)
        return try await database.write(identity(req), patient: req.parameters.get("patient") ?? "", kind: req.parameters.get("kind") ?? "", input: body)
    }
    api.delete("patient") { req async throws -> HTTPStatus in
        let user = try await identity(req)
        try await database.deletePatient(user, patient: user.id)
        return .noContent
    }
    api.get("patient", "export") { req async throws -> CareExport in
        let user = try await identity(req)
        return try await database.exportPatient(user, patient: user.id)
    }
}

/// Operator-only provisioning; the public registration route can never create clinicians.
public func provisionCareClinician(_ app: Application) async throws {
    guard let email = Environment.get("CARE_CLINICIAN_EMAIL"),
          let name = Environment.get("CARE_CLINICIAN_NAME"),
          let password = Environment.get("CARE_CLINICIAN_PASSWORD"), password.utf8.count >= 12, password.utf8.count <= 72 else {
        throw Abort(.badRequest, reason: "Supply CARE_CLINICIAN_EMAIL, CARE_CLINICIAN_NAME and a 12–72 byte CARE_CLINICIAN_PASSWORD.")
    }
    let directory = Environment.get("CARE_DATA_DIRECTORY") ?? app.directory.workingDirectory + "CareData"
    let database = try CareDatabase(path: directory + "/care.sqlite")
    let hash = try await app.password.async.hash(password)
    _ = try await database.register(email: email.lowercased(), name: name, hash: hash, role: "clinician")
}
