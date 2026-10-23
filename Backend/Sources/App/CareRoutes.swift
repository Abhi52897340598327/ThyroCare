import Foundation
import Vapor

/// Legacy APIs contain fixtures and are intentionally unavailable through this middleware.
struct RetiredClinicalAPIs: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let path = request.url.path
        if path.hasPrefix("/v1/"), request.method != .GET, request.method != .OPTIONS,
           request.headers.bearerAuthorization == nil,
           let origin = request.headers.first(name: .origin),
           origin != Environment.get("CARE_WEB_ORIGIN") && origin != "https://" + (request.headers.first(name: .host) ?? "") && origin != "http://localhost:3000" {
            throw Abort(.forbidden, reason: "Untrusted request origin.")
        }
        let retired = ["/auth", "/patients", "/analyses", "/analyze-meal", "/debug", "/dashboard", "/reports", "/family-links", "/meal-uploads", "/providers/endocrinologists", "/clinician/review-events"]
        if retired.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) || path == "/clinician/patients" {
            throw Abort(.gone, reason: "This prototype endpoint is retired. Use authenticated /v1 records.")
        }
        let response = try await next.respond(to: request)
        if path.hasPrefix("/v1/") { response.headers.replaceOrAdd(name: .cacheControl, value: "no-store") }
        return response
    }
}

func registerCareRoutes(_ app: Application) throws {
    let directory = Environment.get("CARE_DATA_DIRECTORY") ?? app.directory.workingDirectory + "CareData"
    try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    let database = try CareDatabase(path: directory + "/care.sqlite")
    let api = app.grouped("v1")

    @Sendable func identity(_ req: Request) async throws -> CareIdentity {
        try await database.identity(token: req.headers.bearerAuthorization?.token ?? req.cookies["care_session"]?.string)
    }
    @Sendable func sessionResponse(_ session: CareSession, req: Request) async throws -> Response {
        let response = try await session.encodeResponse(for: req)
        response.cookies["care_session"] = .init(string: session.token, maxAge: 43_200, path: "/v1", isSecure: req.application.environment == .production, isHTTPOnly: true, sameSite: .strict)
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
    api.get("me") { req async throws -> CareIdentity in try await identity(req) }
    api.get("patients") { req async throws -> [CareIdentity] in try await database.patients(identity(req)) }
    api.get("care-team") { req async throws -> [CareIdentity] in try await database.careTeam(identity(req)) }
    api.delete("care-team", ":subject") { req async throws -> HTTPStatus in
        try await database.revoke(identity(req), subject: req.parameters.get("subject") ?? "")
        return .noContent
    }
    api.post("invitations") { req async throws -> CareInvitation in try await database.invite(identity(req)) }
    api.post("invitations", "preview") { req async throws -> CareIdentity in
        _ = try await identity(req)
        return try await database.previewInvitation(req.content.decode(CareInvitation.self).code)
    }
    api.post("invitations", "accept") { req async throws -> HTTPStatus in
        try await database.connect(identity(req), code: req.content.decode(CareInvitation.self).code)
        return .noContent
    }
    api.post("patients", ":patient", "meals", ":meal", "photo") { req async throws -> MealPhotoResponse in
        try await database.savePhoto(identity(req), patient: req.parameters.get("patient") ?? "", meal: req.parameters.get("meal") ?? "", base64: req.content.decode(MealPhotoUpload.self).imageBase64)
    }
    api.get("patients", ":patient", "meals", ":meal", "photo") { req async throws -> MealPhotoResponse in
        try await database.photo(identity(req), patient: req.parameters.get("patient") ?? "", meal: req.parameters.get("meal") ?? "")
    }
    api.get("patients", ":patient", "export") { req async throws -> CareRecordExport in
        let user = try await identity(req)
        let patient = req.parameters.get("patient") ?? ""
        var records: [CareRecord] = []
        for kind in CareValidation.kinds.sorted() { records += try await database.records(user, patient: patient, kind: kind, history: true) }
        var photos: [MealPhotoResponse] = []
        for meal in try await database.records(user, patient: patient, kind: "meals") where meal.fields["hasPhoto"] == "true" {
            do { photos.append(try await database.photo(user, patient: patient, meal: meal.id)) }
            catch let error as AbortError where error.status == .notFound { continue }
        }
        return CareRecordExport(schemaVersion: 1, patientID: patient, exportedAt: ISO8601DateFormatter().string(from: Date()), records: records, photos: photos)
    }
    api.post("account-deletion") { req async throws -> CareRecord in
        let user = try await identity(req)
        guard user.role == "patient" else { throw Abort(.forbidden) }
        let input = try req.content.decode(RecordWrite.self)
        return try await database.write(user, patient: user.id, kind: "deletion-requests", input: RecordWrite(id: input.id, expectedVersion: 0, fields: ["body": "Patient requested account deletion review", "status": "Submitted"]))
    }
    // Register literal collection paths: the nested meals/photo route shares this prefix.
    // A parameter-only collection route would be shadowed by the literal meals branch.
    for kind in CareValidation.kinds.sorted() {
        api.get("patients", ":patient", .constant(kind)) { req async throws -> [CareRecord] in
            try await database.records(identity(req), patient: req.parameters.get("patient") ?? "", kind: kind, history: req.query[Bool.self, at: "history"] ?? false)
        }
        api.post("patients", ":patient", .constant(kind)) { req async throws -> CareRecord in
            try await database.write(identity(req), patient: req.parameters.get("patient") ?? "", kind: kind, input: req.content.decode(RecordWrite.self))
        }
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
    let hash = try Bcrypt.hash(password)
    _ = try await database.register(email: email.lowercased(), name: name, hash: hash, role: "clinician")
}
