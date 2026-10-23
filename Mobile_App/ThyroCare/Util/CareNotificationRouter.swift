import SwiftUI
import Observation
import UserNotifications

struct CareNotificationRoute: Identifiable {
    let id: String
    let patientID: String
    let planID: String
    let version: String
    let slot: String
    let day: String
}

@MainActor @Observable
final class CareNotificationRouter {
    static let shared = CareNotificationRouter()
    var route: CareNotificationRoute?
}

final class CareAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let patient = info["patientID"] as? String, let plan = info["planID"] as? String,
              let version = info["version"] as? String, let slot = info["slot"] as? String,
              let day = info["day"] as? String else { return }
        let route = CareNotificationRoute(id: response.notification.request.identifier, patientID: patient, planID: plan, version: version, slot: slot, day: day)
        await MainActor.run { CareNotificationRouter.shared.route = route }
    }
}

struct CareReminderDestination: View {
    let store: CareStore
    let route: CareNotificationRoute
    @State private var plan: PatientRecord?
    @State private var error: String?
    @State private var saved = false

    var body: some View {
        NavigationStack {
            List {
                if let error { Text(error).foregroundStyle(.secondary) }
                else if let plan {
                    Text("Confirmed current plan").font(.headline)
                    Text("\(route.day) · \(plan.fields["timezone"] ?? "")")
                    if saved { Text("Saved on device. Check sync status for server acknowledgement.") }
                    else if plan.fields["planType"] == "medication" {
                        Text("Follow your confirmed prescription. This reminder does not choose or change a dose.")
                        Button("Record taken") { Task { await administration(plan, status: "taken") } }
                        Button("Record skipped") { Task { await administration(plan, status: "skipped") } }
                    } else if plan.fields["planType"] == "meal" {
                        NavigationLink("Log this meal") {
                            CareEntryView(store: store, kind: "meals", prefilled: ["observedDate": route.day, "mealType": route.slot.capitalized, "planID": plan.id])
                        }
                        Button("Skipped meal") { Task { await skippedMeal(plan, status: "Skipped meal") } }
                        Button("Not eaten / fasting") { Task { await skippedMeal(plan, status: "Not eaten / fasting") } }
                    } else if plan.fields["planType"] == "daily-symptom" {
                        NavigationLink("Open daily check-in") {
                            CareEntryView(store: store, kind: "symptoms", prefilled: ["observedDate": route.day])
                        }
                    } else {
                        NavigationLink("Open weekly check-in") {
                            CareEntryView(store: store, kind: "weekly-checkins", prefilled: ["recallEnd": route.day])
                        }
                    }
                } else { ProgressView("Checking the current care plan") }
            }
            .navigationTitle("Care reminder")
            .task {
                guard store.session?.user.id == route.patientID else {
                    error = "Sign in to the account associated with this reminder."
                    return
                }
                do {
                    let current = try await store.currentReminderPlan(id: route.planID)
                    guard String(current.version) == route.version, current.fields["status"] == "active" else {
                        error = "This reminder belongs to an older or paused plan. Open the reminder center to review the current schedule."
                        return
                    }
                    plan = current
                } catch {
                    self.error = "The current plan could not be verified. Connect to review it before using this reminder. Follow your confirmed prescription."
                }
            }
        }
    }

    private func administration(_ plan: PatientRecord, status: String) async {
        let fields = ["regimenID": plan.fields["regimenID"] ?? "", "regimenVersion": plan.fields["regimenVersion"] ?? "", "observedDate": route.day, "time": plan.fields["time"] ?? "", "status": status, "actualAt": ISO8601DateFormatter().string(from: Date()), "source": "Patient confirmed"]
        saved = await store.save(kind: "administrations", fields: fields)
    }

    private func skippedMeal(_ plan: PatientRecord, status: String) async {
        let fields = ["description": status, "observedDate": route.day, "mealTime": plan.fields[route.slot] ?? "", "mealType": route.slot.capitalized, "status": status, "planID": plan.id, "source": "Patient confirmed"]
        saved = await store.save(kind: "meals", fields: fields)
    }
}
