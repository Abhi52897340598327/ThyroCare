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
    @State private var store = CareStore()
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

struct CareTabs: View {
    let store: CareStore
    @State private var selected = "today"
    @State private var notificationRouter = CareNotificationRouter.shared
    var body: some View {
        TabView(selection: $selected) {
            Tab("Today", systemImage: "sun.max", value: "today") {
                NavigationStack { CareTodayView(store: store) }
            }
            Tab("Track", systemImage: "list.bullet.clipboard", value: "track") {
                NavigationStack { CareTrackView(store: store) }
            }
            Tab("Meals", systemImage: "fork.knife", value: "meals") {
                NavigationStack { CareRecordList(store: store, kind: "meals", title: "Meals") }
            }
            Tab("Trends", systemImage: "chart.xyaxis.line", value: "trends") {
                NavigationStack { CareTrendsView(store: store) }
            }
            Tab("Care", systemImage: "bubble.left.and.bubble.right", value: "care") {
                NavigationStack { CareCoordinationView(store: store) }
            }
        }
        .sheet(isPresented: Binding(get: { store.showQuestionnaire }, set: { store.showQuestionnaire = $0 })) {
            NavigationStack { QuestionairePage(store: store) }
        }
        .sheet(item: $notificationRouter.route) { route in
            CareReminderDestination(store: store, route: route)
        }
        .task {
            while !Task.isCancelled {
                await store.synchronize()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }
}

struct CareTodayView: View {
    let store: CareStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(Date.now.formatted(date: .complete, time: .omitted)).foregroundStyle(.secondary)
                CareSyncView(store: store)
                CareSection(title: "Your questionnaire") {
                    NavigationLink("Open questionnaire") { QuestionairePage(store: store) }
                    NavigationLink("Explore simulated records") { CareSampleDataView() }
                }
                CareSection(title: "Today’s plan") {
                    NavigationLink("Daily symptom check-in") { CareEntryView(store: store, kind: "symptoms") }
                    NavigationLink("Weekly check-in") { CareEntryView(store: store, kind: "weekly-checkins") }
                    NavigationLink("Record a meal") { CareEntryView(store: store, kind: "meals") }
                    NavigationLink("Reminder center") { CareReminderCenter(store: store) }
                    Text("Tasks are recorded only when you save an entry.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                CareSection(title: "Latest labs") {
                    if store.entries("labs").isEmpty {
                        Text("No lab results recorded.")
                        NavigationLink("Add your first lab result") { CareEntryView(store: store, kind: "labs") }
                    } else {
                        ForEach(Array(store.entries("labs").prefix(5))) { record in
                            NavigationLink { CareRecordDetail(store: store, record: record) } label: { CareRecordRow(record: record) }
                        }
                    }
                }
                CareSection(title: "Care updates") {
                    Text("\(store.entries("messages").count) saved messages · \(store.entries("notes").count) shared notes")
                    NavigationLink("View appointments") { CareRecordList(store: store, kind: "appointments", title: "Appointments") }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
        }
        .background(CarePalette.canvas)
        .navigationTitle("Today")
        .toolbar { NavigationLink { CareSettingsView(store: store) } label: { Label("Profile and settings", systemImage: "person.crop.circle") } }
        .refreshable { await store.synchronize() }
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

struct CareTrackView: View {
    let store: CareStore
    var body: some View {
        List {
            Section("Getting started") {
                NavigationLink("Questionnaire") { QuestionairePage(store: store) }
                NavigationLink("Simulated sample data") { CareSampleDataView() }
            }
            Section("Record types") {
                NavigationLink("Lab reports") { CareRecordList(store: store, kind: "labs", title: "Lab reports") }
                NavigationLink("Daily symptoms") { CareRecordList(store: store, kind: "symptoms", title: "Daily symptoms") }
                NavigationLink("Weekly check-ins") { CareRecordList(store: store, kind: "weekly-checkins", title: "Weekly check-ins") }
                NavigationLink("Medicines and supplements") { CareRecordList(store: store, kind: "medications", title: "Medicines and supplements") }
                NavigationLink("Body measurements and vitals") { CareRecordList(store: store, kind: "vitals", title: "Vitals") }
            }
            Section("Recent records") {
                ForEach(Array(store.records.sorted { $0.recordedAt > $1.recordedAt }.prefix(20))) { record in
                    NavigationLink { CareRecordDetail(store: store, record: record) } label: { CareRecordRow(record: record) }
                }
            }
        }
        .navigationTitle("Track")
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
                ContentUnavailableView("No records yet", systemImage: "tray", description: Text("Saved records will appear here with their dates and sources."))
            }
            ForEach(store.entries(kind)) { record in
                NavigationLink { CareRecordDetail(store: store, record: record) } label: { CareRecordRow(record: record) }
            }
            Section("Waiting to sync") {
                ForEach(store.pending.filter { $0.kind == kind }) { draft in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(draft.fields["analyte"] ?? draft.fields["name"] ?? draft.fields["description"] ?? draft.fields["body"] ?? "Saved entry")
                        Text("Saved on device").font(.footnote).foregroundStyle(.secondary)
                        if let server = store.records.first(where: { $0.id == draft.id && $0.version > draft.expectedVersion }) {
                            Text("A server version exists. Review it before discarding or re-entering your pending correction.")
                                .font(.footnote)
                            NavigationLink("Review server version") { CareRecordDetail(store: store, record: server) }
                        } else {
                            NavigationLink("Review or correct device entry") {
                                CareEntryView(store: store, kind: kind, correcting: PatientRecord(id: draft.id, patientID: draft.patientID, kind: draft.kind, version: draft.expectedVersion, recordedAt: "", authorID: draft.patientID, fields: draft.fields))
                            }
                        }
                    }
                    .swipeActions {
                        Button("Discard device entry", role: .destructive) { store.discardPending(draft) }
                    }
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            if !["notes", "appointments"].contains(kind) {
                NavigationLink { CareEntryView(store: store, kind: kind) } label: { Label("Add", systemImage: "plus") }
            }
        }
        .refreshable { await store.synchronize() }
    }
}

struct CareRecordDetail: View {
    let store: CareStore
    let record: PatientRecord
    @State private var analysisBusy = false
    @State private var analysisMessage: String?
    @State private var confirmAnalysis = false
    var body: some View {
        List {
            if record.kind == "meals" {
                Section("Meal analysis") {
                    Button(analysisBusy ? "Analyzing meal…" : "Analyze meal with AI") { confirmAnalysis = true }
                        .disabled(analysisBusy)
                    if let analysisMessage { Text(analysisMessage) }
                }
                .alert("Analyze this photo?", isPresented: $confirmAnalysis) {
                    Button("Cancel", role: .cancel) { }
                    Button("Share photo and analyze") {
                        Task {
                            analysisBusy = true
                            defer { analysisBusy = false }
                            do {
                                let result = try await store.analyzeMeal(record)
                                analysisMessage = result.fields["analysisStatus"] == "complete"
                                    ? (result.fields["summary"] ?? "Analysis saved.") + "\nEstimated kcal: " + (result.fields["estimatedCaloriesKcal"] ?? "Not available")
                                    : result.fields["analysisError"]
                            } catch { analysisMessage = error.localizedDescription }
                        }
                    }
                } message: {
                    Text("Your meal photo will be sent to Google Gemini to identify foods. Food search terms are sent to USDA for nutrient estimates. Your name and other health records are not included. You can cancel and log manually.")
                }
            }
            if record.kind == "meals", record.fields["hasPhoto"] == "true" {
                Section("Confirmed meal photo") { CareMealPhotoView(store: store, record: record) }
            }
            Section("Entered information") {
                ForEach(record.fields.keys.sorted(), id: \.self) { key in
                    if let value = record.fields[key], !value.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(CareField.label(key)).font(.caption).foregroundStyle(.secondary)
                            Text(value).textSelection(.enabled)
                        }
                    }
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

struct CareTrendsView: View {
    let store: CareStore
    @State private var analyte = "TSH"
    @State private var unit = "mIU/L"
    var body: some View {
        List {
            Section {
                Picker("Analyte", selection: $analyte) {
                    ForEach(CareField.analytes, id: \.self) { Text($0) }
                }
                .onChange(of: analyte) { _, value in unit = CareField.units[value]?.first ?? "" }
                Picker("Report unit", selection: $unit) {
                    ForEach(CareField.units[analyte] ?? [], id: \.self) { Text($0) }
                }
            }
            CareLabChart(records: store.entries("labs").filter { $0.fields["analyte"] == analyte && $0.fields["unit"] == unit }, unit: unit)
            Section("Symptoms") {
                NavigationLink("Daily and weekly symptom trends") { CareSymptomTrends(store: store) }
            }
            Section("Model availability") {
                Text("Individual symptom-to-hormone and meal-to-hormone forecasting is not validated. No forecast is calculated.")
                Text("Charts show measured results only. Censored results and missing collection dates remain in the data list and are not plotted as exact measurements.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Trends")
    }
}

struct CareLabChart: View {
    let records: [PatientRecord]
    let unit: String
    @State private var selectedDate: Date?
    var points: [LabPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return records.compactMap { record in
            guard let text = record.fields["result"], let value = Double(text), value.isFinite,
                  let dateText = record.fields["collectedDate"], let date = formatter.date(from: dateText) else { return nil }
            return LabPoint(id: record.id, date: date, value: value)
        }.sorted { $0.date < $1.date }
    }
    var body: some View {
        Section("Measured results · \(unit)") {
            if points.isEmpty { Text("No exact results with collection dates to plot.") }
            else {
                Chart(points) { point in
                    PointMark(x: .value("Collection date", point.date), y: .value(unit, point.value))
                        .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                        .accessibilityValue("\(point.value) \(unit)")
                }
                .chartXSelection(value: $selectedDate)
                .frame(height: 240)
                if let selectedDate, let point = points.min(by: { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }) {
                    Text("\(point.date.formatted(date: .abbreviated, time: .omitted)): \(point.value.formatted()) \(unit)")
                        .monospacedDigit()
                }
            }
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(record.fields["result"] ?? "") \(unit) · \(record.observationDate)")
                    Text("Report interval: \(record.fields["referenceLower"].flatMap { $0.isEmpty ? nil : $0 } ?? "Not supplied") – \(record.fields["referenceUpper"] ?? "")")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}
struct LabPoint: Identifiable {
    let id: String
    let date: Date
    let value: Double
}

struct CareCoordinationView: View {
    let store: CareStore
    var body: some View {
        List {
            Section("Care team") {
                if store.careTeam.isEmpty { Text("No care team connected.") }
                ForEach(store.careTeam) { person in Text(person.name) }
                NavigationLink("Connect care team") { CareConnectionView(store: store) }
            }
            Section("Communication") {
                NavigationLink("Messages") { CareRecordList(store: store, kind: "messages", title: "Messages") }
                NavigationLink("Request information from my clinician") { CareRecordList(store: store, kind: "requests", title: "Information requests") }
                Text("Messages are shared with your connected care team. Response times must be confirmed with your practice. This inbox is not an emergency service.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Your care records") {
                NavigationLink("Shared notes") { CareRecordList(store: store, kind: "notes", title: "Shared notes") }
                NavigationLink("Appointments") { CareRecordList(store: store, kind: "appointments", title: "Appointments") }
            }
        }.navigationTitle("Care")
    }
}

struct CareConnectionView: View {
    let store: CareStore
    @State private var code = ""
    @State private var clinician: PatientIdentity?
    @State private var error: String?
    var body: some View {
        Form {
            TextField("Invitation code", text: $code).textInputAutocapitalization(.never).autocorrectionDisabled()
                .onChange(of: code) { _, _ in clinician = nil }
            Button("Review invitation") {
                Task {
                    do { clinician = try await store.previewInvitation(code); error = nil }
                    catch { self.error = error.localizedDescription }
                }
            }
            if let clinician {
                Text("Connect with \(clinician.name)")
                Text("This grants access to all your care records, including meals, symptoms, messages and patient-visible notes. You can revoke access in Settings.")
                Button("Confirm connection") {
                    Task {
                        do { try await store.acceptInvitation(code); self.clinician = nil; code = "" }
                        catch { self.error = error.localizedDescription }
                    }
                }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }.navigationTitle("Connect care team")
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
