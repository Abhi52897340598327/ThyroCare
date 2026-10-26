import SwiftUI
import Charts

enum CarePalette {
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let action = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(red: 0.35, green: 0.83, blue: 0.81, alpha: 1) : UIColor(red: 0.03, green: 0.45, blue: 0.46, alpha: 1)
    })
}

struct CareSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CarePalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.secondary.opacity(0.18)))
    }
}

struct CareRootView: View {
    @State private var store = CareStore.shared
    @StateObject private var presentationIdentity = AuthManager()
    var body: some View {
        Group {
            if store.isRestoring {
                ProgressView("Restoring your account…")
            } else if store.session != nil {
                MainTabView(store: store)
            } else {
                LandingPage(store: store)
                    .environmentObject(presentationIdentity)
            }
        }
        .task { await store.restore() }
    }
}

struct CareAccountView: View {
    let store: CareStore
    @State private var register = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Your thyroid care, together.").font(.largeTitle.bold())
                    Text("Keep records. Understand measured patterns. Communicate with your care team.")
                        .foregroundStyle(.secondary)
                }
                Section(register ? "Create your account" : "Sign in") {
                    if register {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name").font(.caption).foregroundStyle(.secondary)
                            TextField("Your name", text: $name).textContentType(.name)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(.caption).foregroundStyle(.secondary)
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress).textContentType(.username)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password").font(.caption).foregroundStyle(.secondary)
                        SecureField("Password", text: $password)
                            .textContentType(register ? .newPassword : .password)
                    }
                    if register { Text("Use at least 12 characters.").font(.footnote) }
                    Button(register ? "Create account" : "Sign in") {
                        Task { await store.authenticate(email: email, password: password, name: name, register: register) }
                    }
                    .disabled(store.isWorking || email.isEmpty || password.isEmpty || (register && name.isEmpty))
                    if store.isWorking { ProgressView("Connecting securely") }
                    Button(register ? "I already have an account" : "Create an account") { register.toggle() }
                }
                if let error = store.errorMessage { Section { Text(error).foregroundStyle(.red) } }
                Section {
                    #if DEBUG && targetEnvironment(simulator)
                    Text("Simulator: connected to the local backend on your Mac. Accounts and records stay in its persistent local database.")
                    #else
                    Text("Cloud records are associated with your verified server session. Care-team access is granted separately through an invitation.")
                    #endif
                    Text("Account recovery and email verification are not available in this development build.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("ThyroCare")
        }
    }
}

/// Dedicated Daily Tasks screen shown when the user taps their profile or "Daily Tasks"
struct DailyTasksView: View {
    let store: CareStore
    let onBackToHome: () -> Void
    var onNavigateToTab: (AppTab.MainTab) -> Void = { _ in }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white, ThyroUI.mint.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Top Bar with clear Back to Home button
                    HStack {
                        Button(action: onBackToHome) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.bold))
                                Text("Back to Home")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(ThyroUI.teal)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: ThyroUI.navy.opacity(0.08), radius: 6, x: 0, y: 2)
                        }

                        Spacer()

                        NavigationLink {
                            CareSettingsView(store: store)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                Text("Settings")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ThyroUI.navy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Capsule())
                            .shadow(color: ThyroUI.navy.opacity(0.06), radius: 4, x: 0, y: 1)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Tasks")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(ThyroUI.navy)
                        Text(Date.now.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    CareSyncView(store: store)

                    // Today's Action Plan Card
                    ThyroCard {
                        ThyroSectionTitle("Today's Plan", subtitle: "Log daily thyroid parameters and stay on schedule.")

                        VStack(spacing: 10) {
                            NavigationLink {
                                CareEntryView(store: store, kind: "symptoms")
                            } label: {
                                DailyTaskRow(
                                    icon: "waveform.path.ecg",
                                    color: ThyroUI.teal,
                                    title: "Daily symptom check-in",
                                    subtitle: "Energy, fatigue, cold sensitivity, pulse rate"
                                )
                            }

                            Button {
                                onNavigateToTab(.picture)
                            } label: {
                                DailyTaskRow(
                                    icon: "fork.knife",
                                    color: ThyroUI.amber,
                                    title: "Record a meal & scan plate",
                                    subtitle: "AI nutrition and thyroid micronutrient analysis"
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                CareReminderCenter(store: store)
                            } label: {
                                DailyTaskRow(
                                    icon: "pills.fill",
                                    color: ThyroUI.violet,
                                    title: "Medication adherence & reminders",
                                    subtitle: "Levothyroxine timing, fasting window, alerts"
                                )
                            }

                            NavigationLink {
                                CareEntryView(store: store, kind: "weekly-checkins")
                            } label: {
                                DailyTaskRow(
                                    icon: "calendar.badge.clock",
                                    color: ThyroUI.coral,
                                    title: "Weekly check-in",
                                    subtitle: "Comprehensive 7-day retrospective"
                                )
                            }
                        }
                    }

                    // Questionnaire Card
                    ThyroCard {
                        ThyroSectionTitle("ThyroCare Questionnaire", subtitle: "Assess symptoms and compute composite clinical severity.")

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Complete Symptom Questionnaire")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThyroUI.navy)
                                Text("Calculates composite score, TSH shifts, and care summary.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                onNavigateToTab(.questionaire)
                            } label: {
                                Text("Open")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(ThyroUI.teal)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // Latest Labs Card
                    ThyroCard {
                        ThyroSectionTitle("Latest Labs", subtitle: "Tracked thyroid blood panels (TSH, Free T4, Free T3).")

                        if store.entries("labs").isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No recent lab records on device.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                NavigationLink {
                                    CareEntryView(store: store, kind: "labs")
                                } label: {
                                    Label("Add lab result", systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(ThyroUI.teal)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(Array(store.entries("labs").prefix(4))) { record in
                                    NavigationLink {
                                        CareRecordDetail(store: store, record: record)
                                    } label: {
                                        CareRecordRow(record: record)
                                    }
                                }
                            }
                        }
                    }

                    // Care Updates Card
                    ThyroCard {
                        ThyroSectionTitle("Care Updates", subtitle: "Communication with your endocrine care team.")

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(store.entries("messages").count) messages · \(store.entries("notes").count) clinical notes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThyroUI.navy)
                                Text("Direct messaging channel with your clinician.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                onNavigateToTab(.messages)
                            } label: {
                                Label("Messages", systemImage: "message.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(ThyroUI.navy)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarHidden(true)
        .refreshable { await store.synchronize() }
    }
}

struct DailyTaskRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThyroUI.navy)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary.opacity(0.7))
        }
        .padding(10)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CareSyncView: View {
    let store: CareStore
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(store.syncLabel, systemImage: store.pending.isEmpty ? "arrow.triangle.2.circlepath" : "tray.and.arrow.up")
                .font(.footnote)
            if let error = store.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
                Button("Retry sync") { Task { await store.synchronize() } }
            }
            if !store.pending.isEmpty {
                Text("\(store.pending.count) device entries waiting for server acknowledgement.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CareRecordRow: View {
    let record: PatientRecord
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(record.title).font(.headline)
            if let result = record.fields["result"] { Text("\(result) \(record.fields["unit"] ?? "")").font(.title2).monospacedDigit() }
            if let body = record.fields["body"] { Text(body).lineLimit(3) }
            Text(record.observationDate).font(.subheadline).foregroundStyle(.secondary)
            Text("\(record.fields["source"] ?? "Entered record") · Version \(record.version)")
                .font(.footnote).foregroundStyle(.secondary)
        }.foregroundStyle(.primary).padding(.vertical, 4)
    }
}

struct CareRecordList: View {
    let store: CareStore
    let kind: String
    let title: String
    var body: some View {
        List {
            Section { CareSyncView(store: store) }
            if kind == "meals" {
                Section { Text("Save a meal description and an optional confirmed photo. Nutrient analysis is not yet connected.") }
            }
            if store.entries(kind).isEmpty {
                Section { Text("No records saved yet.") }
            } else {
                ForEach(store.entries(kind)) { record in
                    NavigationLink { CareRecordDetail(store: store, record: record) } label: { CareRecordRow(record: record) }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            if !["messages", "notes", "questionnaire"].contains(kind) {
                NavigationLink("Add") { CareEntryView(store: store, kind: kind) }
            }
        }
    }
}

struct CareMealRecordPhoto: View {
    let store: CareStore
    let record: PatientRecord
    @State private var imageData: Data?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoading {
                ProgressView("Loading photo…")
            } else {
                Text("Photo unavailable on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            isLoading = true
            imageData = try? await store.mealPhoto(record)
            isLoading = false
        }
    }
}

struct CareRecordDetail: View {
    let store: CareStore
    let record: PatientRecord
    var body: some View {
        List {
            Section("Record") {
                LabeledContent("Kind", value: record.kind)
                LabeledContent("Observed", value: record.observationDate)
                if let collected = record.fields["collectedDate"] { LabeledContent("Collected", value: collected) }
            }
            if let body = record.fields["body"], !body.isEmpty {
                Section("Notes") { Text(body) }
            }
            if let result = record.fields["result"], !result.isEmpty {
                Section("Result") {
                    Text("\(result) \(record.fields["unit"] ?? "")").font(.title).monospacedDigit()
                    if let lower = record.fields["referenceLower"], let upper = record.fields["referenceUpper"], !upper.isEmpty {
                        Text("Reference interval: \(lower.isEmpty ? "—" : lower) to \(upper)")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            if let photo = record.fields["mealPhotoRelativePath"], !photo.isEmpty {
                Section("Meal photo") {
                    CareMealRecordPhoto(store: store, record: record)
                }
            }
            Section("Record provenance") {
                Text("Recorded: \(record.recordedAt)")
                Text("Author: \(record.authorID)")
                Text("Version \(record.version)")
                Text("Record ID: \(record.id)").font(.footnote)
            }
            if record.authorID == store.session?.user.id && !["messages", "notes", "appointments", "questionnaire"].contains(record.kind) {
                NavigationLink("Correct this record") { CareEntryView(store: store, kind: record.kind, correcting: record) }
            }
        }
        .navigationTitle(record.title)
    }
}

struct CareSettingsView: View {
    let store: CareStore
    @State private var confirmDeletion = false
    var body: some View {
        List {
            Section("Account") {
                Text(store.session?.user.name ?? "")
                CareSyncView(store: store)
                Button("Sync now") { Task { await store.synchronize() } }
                Button("Sign out", role: .destructive) { Task { await store.logout() } }
            }
            Section("Reminders") {
                NavigationLink("Reminder center") { CareReminderCenter(store: store) }
            }
            Section("Sharing") {
                ForEach(store.careTeam) { person in
                    Button("Revoke access for \(person.name)", role: .destructive) { Task { await store.revoke(person) } }
                }
            }
            Section("Your records") {
                Button("Prepare record export") { Task { await store.prepareExport() } }
                if let url = store.exportURL { ShareLink("Share or save your export", item: url) }
                Text("Export includes server-acknowledged records, revisions and uploaded photos. Sync pending device entries first.")
                    .font(.footnote)
                Button("Request account deletion review", role: .destructive) { confirmDeletion = true }
                if let status = store.deletionRequestStatus { Text(status).font(.footnote) }
            }
            Section("Development build") {
                Text("Deletion processing, verification and recovery still require implementation before release. Reminder delivery requires device validation.")
                Text("Legacy local questionnaire records have not been migrated. They are retained on this device; they are not treated as verified cloud records.")
            }
        }
        .navigationTitle("Profile and settings")
        .confirmationDialog("Request account deletion review?", isPresented: $confirmDeletion, titleVisibility: .visible) {
            Button("Submit review request", role: .destructive) { Task { await store.requestAccountDeletion() } }
        } message: {
            Text("This saves a request; it does not immediately erase your account or clinical records. Export your records first. Retention and identity review must be completed by the operator; no processing deadline is available in this development build.")
        }
    }
}
