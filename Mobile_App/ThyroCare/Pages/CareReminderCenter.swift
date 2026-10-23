import SwiftUI

struct CareReminderCenter: View {
    let store: CareStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("Notification status") {
                Text(store.reminders.status)
                Button("Review notification permission") {
                    Task {
                        await store.reminders.requestPermission()
                        if let id = store.session?.user.id { await store.reminders.reconcile(patientID: id, records: store.records) }
                    }
                }
                Button("Open system Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Section("Create a confirmed schedule") {
                NavigationLink("Log every meal") { CareReminderSetup(store: store, type: "meal") }
                NavigationLink("Medication reminder") { CareReminderSetup(store: store, type: "medication") }
                NavigationLink("Daily symptom reminder") { CareReminderSetup(store: store, type: "daily-symptom") }
                NavigationLink("Weekly check-in reminder") { CareReminderSetup(store: store, type: "weekly-checkin") }
            }
            Section("Your plans") {
                ForEach(store.entries("care-plans")) { plan in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.fields["planType"] ?? "Plan").font(.headline)
                        Text("\(plan.fields["status"] ?? "") · \(plan.fields["timezone"] ?? "")").font(.footnote)
                        Text("Starts \(plan.fields["startDate"] ?? "") · Ends \(plan.fields["endDate"].flatMap { $0.isEmpty ? nil : $0 } ?? "when stopped")")
                            .font(.footnote)
                        Button(plan.fields["status"] == "active" ? "Pause plan" : "Resume plan") {
                            Task {
                                var fields = plan.fields
                                fields["status"] = fields["status"] == "active" ? "paused" : "active"
                                _ = await store.save(kind: "care-plans", fields: fields, correcting: plan)
                            }
                        }
                    }
                }
            }
            Section("Next scheduled reminders on this device") {
                ForEach(store.reminders.next) { occurrence in
                    VStack(alignment: .leading) {
                        Text(occurrence.plan.fields["planType"] ?? "Care reminder")
                        Text(occurrence.date.formatted(date: .abbreviated, time: .shortened)).monospacedDigit()
                    }
                }
            }
            Section("Delivery and privacy") {
                Text("Lock-screen messages are discreet and never include a medication dose. A notification does not mark a dose taken.")
                Text("Schedules use the plan’s fixed timezone, including daylight-saving changes. Review your plan when traveling.")
                Text("Up to 60 upcoming occurrences are scheduled within 28 days. The visible horizon can be shorter when several plans are active. Reopen before the displayed date to extend it. Focus, permissions and iOS scheduling can delay or suppress delivery.")
                Text("Remote plan changes are reconciled when this app connects. An offline reminder may be stale; open the app to verify the current plan.")
            }
        }
        .navigationTitle("Reminders")
        .task {
            if let id = store.session?.user.id { await store.reminders.reconcile(patientID: id, records: store.records) }
        }
    }
}

struct CareReminderSetup: View {
    let store: CareStore
    let type: String
    @Environment(\.dismiss) private var dismiss
    @State private var breakfast = "08:00"
    @State private var lunch = "12:00"
    @State private var dinner = "18:00"
    @State private var time = "09:00"
    @State private var weekdays: Set<Int> = []
    @State private var timezone = TimeZone.current.identifier
    @State private var start = Date()
    @State private var endDate = ""
    @State private var medicationID = ""
    @State private var acknowledged = false
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        Form {
            Section("Schedule") {
                if type == "meal" {
                    Text("A meal logging plan can help your care team review patterns. Choose your anticipated meal times.")
                    TextField("Breakfast (HH:mm)", text: $breakfast)
                    TextField("Lunch (HH:mm)", text: $lunch)
                    TextField("Dinner (HH:mm)", text: $dinner)
                } else {
                    TextField("Reminder time (HH:mm)", text: $time)
                }
                if type == "medication" {
                    Picker("Confirmed medication record", selection: $medicationID) {
                        Text("Select a medication").tag("")
                        ForEach(store.entries("medications")) { medication in
                            Text(medication.fields["name"] ?? "Medication").tag(medication.id)
                        }
                    }
                    Text("Review the prescription’s actual days and time. As-needed medicines are not scheduled. Reminders contain no dose instruction; an uncertain dose remains uncertain.")
                        .font(.footnote)
                }
                if type == "medication" || type == "weekly-checkin" {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: Binding(get: { weekdays.contains(day) }, set: { enabled in
                            if enabled { weekdays.insert(day) } else { weekdays.remove(day) }
                        }))
                    }
                }
                TextField("Fixed timezone", text: $timezone)
                DatePicker("Start date", selection: $start, displayedComponents: .date)
                TextField("End date (YYYY-MM-DD; optional)", text: $endDate)
            }
            Section("Confirm") {
                Toggle("I confirm these times and want reminders for this plan", isOn: $acknowledged)
                Text("Saving activates the plan. iOS notification permission is requested separately; a denied permission leaves the plan active with notifications disabled.")
                    .font(.footnote)
                if let error { Text(error).foregroundStyle(.red) }
                Button(saving ? "Saving…" : "Save plan and review notifications") { Task { await save() } }
                    .disabled(!acknowledged || saving)
            }
        }
        .navigationTitle(type == "meal" ? "Log every meal" : "Reminder schedule")
    }

    private func save() async {
        guard let zone = TimeZone(identifier: timezone) else { error = "Select a valid IANA timezone."; return }
        let times = type == "meal" ? [breakfast, lunch, dinner] : [time]
        guard times.allSatisfy({ $0.range(of: "^(?:[01][0-9]|2[0-3]):[0-5][0-9]$", options: .regularExpression) != nil }) else { error = "Use HH:mm for each time."; return }
        if (type == "medication" || type == "weekly-checkin") && weekdays.isEmpty { error = "Select the actual scheduled weekdays."; return }
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var fields = ["planType": type, "status": "active", "acknowledged": "true", "timezone": timezone, "startDate": formatter.string(from: start), "endDate": endDate, "time": time, "breakfast": breakfast, "lunch": lunch, "dinner": dinner, "weekdays": weekdays.sorted().map(String.init).joined(separator: ","), "source": "Patient confirmed"]
        if type == "medication" {
            guard let medication = store.entries("medications").first(where: { $0.id == medicationID }) else { error = "Select a saved medication."; return }
            let schedule = (medication.fields["schedule"] ?? "").lowercased()
            guard !schedule.contains("prn") && !schedule.contains("as needed") else { error = "As-needed medicines do not receive a repeating dose reminder."; return }
            fields["regimenID"] = medication.id
            fields["regimenVersion"] = String(medication.version)
        }
        saving = true
        defer { saving = false }
        if await store.save(kind: "care-plans", fields: fields) {
            await store.reminders.requestPermission()
            if let id = store.session?.user.id { await store.reminders.reconcile(patientID: id, records: store.records) }
            dismiss()
        }
    }
}
