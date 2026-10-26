import SwiftUI
import Observation
import UserNotifications
import AVFoundation
import UIKit

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

@MainActor
final class CareBackgroundSyncManager: NSObject {
    static let shared = CareBackgroundSyncManager()

    private var audioPlayer: AVAudioPlayer?
    private var isRunning = false
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var pollTask: Task<Void, Never>?

    private override init() {
        super.init()
        setupAudioSession()
        setupAudioPlayer()
        setupLifecycleObservers()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startPolling()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Background audio session config: \(error)")
        }
    }

    private func setupAudioPlayer() {
        let wavData = Self.createSilentWavData()
        do {
            let player = try AVAudioPlayer(data: wavData)
            player.numberOfLoops = -1
            player.volume = 0.0 // 100% silent, completely imperceptible
            player.prepareToPlay()
            self.audioPlayer = player
        } catch {
            print("Failed to initialize background player: \(error)")
        }
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDidEnterBackground()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleWillEnterForeground()
        }
    }

    private func handleDidEnterBackground() {
        if backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ThyroCareSync") { [weak self] in
                self?.endBackgroundTask()
            }
        }
        setupAudioSession()
        audioPlayer?.play()
    }

    private func handleWillEnterForeground() {
        endBackgroundTask()
        audioPlayer?.pause()
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                await CareStore.shared.synchronize()
                try? await Task.sleep(nanoseconds: 2_500_000_000) // Poll every 2.5s
            }
        }
    }

    private static func createSilentWavData() -> Data {
        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let fileSize: UInt32 = 36 + 8000
        withUnsafeBytes(of: fileSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: UInt16 = 1 // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: UInt16 = 1
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sampleRate: UInt32 = 8000
        withUnsafeBytes(of: sampleRate.littleEndian) { data.append(contentsOf: $0) }
        let byteRate: UInt32 = 8000
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: UInt16 = 1
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: UInt16 = 8
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        let subchunk2Size: UInt32 = 8000
        withUnsafeBytes(of: subchunk2Size.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [UInt8](repeating: 128, count: 8000))
        return data
    }
}

final class CareAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await CareBackgroundSyncManager.shared.start()
        }
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound, .list]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        if let kind = info["kind"] as? String, kind == "messages" {
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("ThyroCareNavigateToMessages"), object: nil)
            }
            return
        }
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
