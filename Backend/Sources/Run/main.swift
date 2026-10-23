import Vapor
import App

@main
struct ThyroCareBackend {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)
        defer { Task { try? await app.asyncShutdown() } }

        try configure(app)
        if Environment.get("CARE_PROVISION_CLINICIAN") == "1" {
            try await provisionCareClinician(app)
        } else {
            try await app.execute()
        }
    }
}
