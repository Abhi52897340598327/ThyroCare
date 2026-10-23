import Foundation
import Testing
import Vapor
@testable import App

struct CareDatabaseTests {
    func fixture() async throws -> (CareDatabase, CareIdentity, CareIdentity, CareIdentity, String) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("test.sqlite").path
        let db = try CareDatabase(path: path)
        let a = try await db.register(email: "a@example.test", name: "A", hash: "test-hash")
        let b = try await db.register(email: "b@example.test", name: "B", hash: "test-hash")
        let clinician = try await db.register(email: "c@example.test", name: "Clinician", hash: "test-hash", role: "clinician")
        return (db, a, b, clinician, path)
    }

    @Test func restartDurabilityIdempotencyAndHistory() async throws {
        let (db, a, _, _, path) = try await fixture()
        let input = RecordWrite(id: UUID().uuidString, expectedVersion: 0, fields: ["analyte": "Free T4", "result": "<0.01", "unit": "ng/dL", "receivedDate": "2026-01-02", "source": "Patient entered"])
        let first = try await db.write(a, patient: a.id, kind: "labs", input: input)
        let retry = try await db.write(a, patient: a.id, kind: "labs", input: input)
        #expect(first.id == retry.id && retry.version == 1)
        let restarted = try CareDatabase(path: path)
        let restored = try await restarted.records(a, patient: a.id, kind: "labs")
        #expect(restored.count == 1)
        #expect(restored[0].fields["result"] == "<0.01")
        #expect(restored[0].fields["collectedDate"] == nil)
        #expect(restored[0].fields["referenceLower"] == nil)
        var correction = input
        correction.expectedVersion = 1
        correction.fields["result"] = "0.8"
        _ = try await restarted.write(a, patient: a.id, kind: "labs", input: correction)
        let history = try await restarted.records(a, patient: a.id, kind: "labs", history: true)
        #expect(history.map(\.version) == [1, 2])
        await #expect(throws: Abort.self) { try await restarted.write(a, patient: a.id, kind: "labs", input: input) }
    }

    @Test func patientIsolationInvitationAndRevocation() async throws {
        let (db, a, b, c, _) = try await fixture()
        await #expect(throws: Abort.self) { try await db.records(b, patient: a.id, kind: "labs") }
        await #expect(throws: Abort.self) { try await db.records(c, patient: a.id, kind: "labs") }
        let invitation = try await db.invite(c)
        try await db.connect(a, code: invitation.code)
        #expect(try await db.patients(c).map(\.id) == [a.id])
        await #expect(throws: Abort.self) { try await db.connect(b, code: invitation.code) }
        try await db.revoke(a, subject: c.id)
        await #expect(throws: Abort.self) { try await db.records(c, patient: a.id, kind: "labs") }
    }

    @Test func messagesRemainIdenticalAfterRestart() async throws {
        let (db, a, _, c, path) = try await fixture()
        try await db.connect(a, code: db.invite(c).code)
        let input = RecordWrite(id: UUID().uuidString, expectedVersion: 0, fields: ["body": "I received my Free T4 result today"])
        _ = try await db.write(a, patient: a.id, kind: "messages", input: input)
        let reply = RecordWrite(id: UUID().uuidString, expectedVersion: 0, fields: ["body": "Please add the report and its reference interval."])
        _ = try await db.write(c, patient: a.id, kind: "messages", input: reply)
        let restarted = try CareDatabase(path: path)
        let messages = try await restarted.records(a, patient: a.id, kind: "messages")
        #expect(messages.map { $0.fields["body"] } == [input.fields["body"], reply.fields["body"]])
        #expect(try await restarted.records(c, patient: a.id, kind: "messages").map(\.id) == messages.map(\.id))
    }

    @Test func sessionsAreRevocable() async throws {
        let (db, a, _, _, _) = try await fixture()
        let session = try await db.session(for: a)
        #expect(try await db.identity(token: session.token).id == a.id)
        try await db.logout(token: session.token)
        await #expect(throws: Abort.self) { try await db.identity(token: session.token) }
        await #expect(throws: Abort.self) { try await db.identity(token: "prototype-token") }
    }

    @Test func invalidClinicalInputsAreRejected() throws {
        let id = UUID().uuidString
        #expect(throws: Abort.self) { try CareValidation.validate(RecordWrite(id: id, expectedVersion: 0, fields: ["analyte": "Free T4", "result": "1.2", "unit": "mg", "source": "test"]), kind: "labs", role: "patient") }
        #expect(throws: Abort.self) { try CareValidation.validate(RecordWrite(id: id, expectedVersion: 0, fields: ["name": "Levothyroxine", "doseMode": "range", "doseLower": "75", "doseUpper": "50", "unit": "mcg", "schedule": "Patient reported"]), kind: "medications", role: "patient") }
        #expect(throws: Abort.self) { try CareValidation.validate(RecordWrite(id: id, expectedVersion: 0, fields: ["observedDate": "2026-02-30", "timezone": "UTC", "scaleVersion": "custom-0-4-v1", "fatigue": "0"]), kind: "symptoms", role: "patient") }
        #expect(throws: Abort.self) { try CareValidation.validate(RecordWrite(id: id, expectedVersion: 0, fields: ["body": "private", "state": "draft", "visibility": "private"]), kind: "notes", role: "clinician") }
    }
    @Test func mealPhotosArePrivateDurableAndStripMetadata() async throws {
        let (db, a, b, c, path) = try await fixture()
        let original = Data(base64Encoded: "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAACAAIDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwC3RRRWZxn/2Q==") ?? Data()
        var tagged = Data(original.prefix(2))
        tagged.append(contentsOf: [0xff, 0xe1, 0x00, 0x08])
        tagged.append(Data("GPS123".utf8))
        tagged.append(original.dropFirst(2))
        let meal = try await db.write(a, patient: a.id, kind: "meals", input: RecordWrite(id: UUID().uuidString, expectedVersion: 0, fields: ["description": "Synthetic meal", "observedDate": "2026-01-02", "mealTime": "12:00", "hasPhoto": "true"]))
        let stored = try await db.savePhoto(a, patient: a.id, meal: meal.id, base64: tagged.base64EncodedString())
        #expect(stored.imageBase64 == original.base64EncodedString())
        await #expect(throws: Abort.self) { try await db.photo(b, patient: a.id, meal: meal.id) }
        try await db.connect(a, code: db.invite(c).code)
        let restarted = try CareDatabase(path: path)
        #expect(try await restarted.photo(c, patient: a.id, meal: meal.id).imageBase64 == stored.imageBase64)
        try await restarted.revoke(a, subject: c.id)
        await #expect(throws: Abort.self) { try await restarted.photo(c, patient: a.id, meal: meal.id) }
        #expect(throws: Abort.self) { try CareJPEG.sanitized(Data("<script>not a photo</script>".utf8)) }
    }

    @Test func reminderPlansRequireAcknowledgementAndValidTimes() throws {
        let input = RecordWrite(id: UUID().uuidString, expectedVersion: 0, fields: ["planType": "meal", "status": "active", "timezone": "America/New_York", "startDate": "2026-01-01", "breakfast": "08:00", "lunch": "12:00", "dinner": "18:00", "acknowledged": "true"])
        try CareValidation.validate(input, kind: "care-plans", role: "patient")
        #expect(throws: Abort.self) { try CareValidation.validate(input, kind: "care-plans", role: "clinician") }
        var invalid = input
        invalid.fields["breakfast"] = "25:00"
        #expect(throws: Abort.self) { try CareValidation.validate(invalid, kind: "care-plans", role: "patient") }
    }

}
