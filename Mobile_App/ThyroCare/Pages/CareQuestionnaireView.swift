import SwiftUI

struct CareQuestionnaireView: View {
    let store: CareStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var fields: [String: String] = [:]
    @State private var initialized = false
    @State private var saving = false
    private let steps = ["About you", "Lab reports", "Medicines and supplements", "Symptoms and context", "Review"]

    private func value(_ key: String) -> Binding<String> {
        Binding(get: { fields[key] ?? "" }, set: { fields[key] = $0 })
    }

    var body: some View {
        Form {
            Section {
                Text("Step \(step + 1) of \(steps.count)").font(.subheadline).foregroundStyle(.secondary)
                Text(steps[step]).font(.title2.bold())
                Text("Add what you know. You can skip any section and return from Today or Track. Save each record before returning here.")
                ProgressView(value: Double(step + 1), total: Double(steps.count))
            }
            switch step {
            case 0:
                Section("Your context · optional") {
                    Text("This helps your care team understand your records. It does not establish a diagnosis.")
                    TextField("Condition, if known", text: value("condition"), axis: .vertical)
                    Picker("Condition source", selection: value("conditionSource")) {
                        Text("Unknown / skip").tag("")
                        Text("Clinician diagnosed").tag("clinician-diagnosed")
                        Text("Patient reported").tag("patient-reported")
                    }
                    TextField("Surgery, treatment or pregnancy context you wish to share", text: value("context"), axis: .vertical)
                    NavigationLink("Add weight, height or a vital") { CareEntryView(store: store, kind: "vitals") }
                }
            case 1:
                Section("Tests actually measured") {
                    Text("Keep free and total hormones separate. Collection dates, received dates and report intervals can remain unknown.")
                    NavigationLink("Add a lab result") { CareEntryView(store: store, kind: "labs") }
                    Text("\(store.entries("labs").count) lab results saved")
                    ForEach(store.entries("labs")) { record in CareRecordRow(record: record) }
                }
            case 2:
                Section("Medicines and supplements") {
                    Picker("Do you take an iron supplement?", selection: value("ironSupplement")) {
                        Text("Not sure / skip").tag("")
                        Text("Yes").tag("yes")
                        Text("No").tag("no")
                    }
                    Text("Record iron, calcium and biotin separately. Exact, estimated-range and unknown doses are supported.")
                    NavigationLink("Add a medicine or supplement") { CareEntryView(store: store, kind: "medications") }
                    Text("\(store.entries("medications").count) medicine or supplement records saved")
                }
            case 3:
                Section("Symptoms and eating pattern") {
                    NavigationLink("Add a daily symptom check-in") { CareEntryView(store: store, kind: "symptoms") }
                    TextField("Diet or eating pattern, if you know it", text: value("diet"), axis: .vertical)
                    TextField("Questions for your care team", text: value("questions"), axis: .vertical)
                    Text("No answer is required. A symptom diary is separate from measured laboratory results.")
                }
            default:
                Section("Review your entries") {
                    Text("Condition: \(fields["condition"].flatMap { $0.isEmpty ? nil : $0 } ?? "Not recorded")")
                    Text("\(store.entries("labs").count) lab results · \(store.entries("medications").count) medicines · \(store.entries("symptoms").count) daily entries")
                    Text("Skipped questions remain unknown. Finishing does not imply clinical review.")
                    NavigationLink("Explore simulated records") { CareSampleDataView() }
                }
            }
            Section {
                CareSyncView(store: store)
                if step > 0 {
                    Button("Back") { Task { await save(next: step - 1, finish: false) } }.disabled(saving)
                }
                Button(step == 4 ? "Finish questionnaire" : "Save and continue") {
                    Task { await save(next: min(step + 1, 4), finish: step == 4) }
                }.disabled(saving)
                Button("Save and finish later") { Task { await save(next: step, finish: false, close: true) } }.disabled(saving)
            }
        }
        .navigationTitle("Questionnaire")
        .interactiveDismissDisabled()
        .task {
            guard !initialized else { return }
            initialized = true
            fields = store.questionnaireRecord?.fields ?? [:]
            step = min(max(Int(fields["step"] ?? "") ?? 0, 0), 4)
        }
    }

    private func save(next: Int, finish: Bool, close: Bool = false) async {
        saving = true
        fields["step"] = String(next)
        fields["status"] = finish ? "complete" : "in-progress"
        fields["source"] = "Patient-reported questionnaire"
        let saved = await store.save(kind: "questionnaire", fields: fields, correcting: store.questionnaireRecord)
        saving = false
        if saved {
            step = next
            if finish || close { dismiss() }
        }
    }
}
