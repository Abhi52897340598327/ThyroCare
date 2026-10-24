import SwiftUI

/// Additive record controls using the original questionnaire's fields and card styling.
struct QuestionnaireRecordFields: View {
    let store: CareStore
    let kind: String
    let title: String
    let defaults: [String: String]
    @State private var fields: [String: String] = [:]
    @State private var recordID = UUID().uuidString
    @State private var busy = false
    @State private var message: String?
    @State private var initialized = false

    private func value(_ key: String) -> Binding<String> {
        Binding(get: { fields[key] ?? "" }, set: { fields[key] = $0 })
    }

    var body: some View {
        DisclosureGroup(title) {
            VStack(alignment: .leading, spacing: 12) {
                if kind == "labs" {
                    input("result", "Result (including < or >)")
                    menu("unit", "Report unit", CareField.units[defaults["analyte"] ?? "TSH"] ?? [])
                    input("collectedDate", "Blood collected · YYYY-MM-DD (optional)")
                    input("receivedDate", "Result received · YYYY-MM-DD (optional)")
                    input("source", "Laboratory / report source")
                    input("referenceLower", "Laboratory interval · lower (optional)")
                    input("referenceUpper", "Laboratory interval · upper (optional)")
                    input("targetLower", "Endocrinologist target · lower (optional)")
                    input("targetUpper", "Endocrinologist target · upper (optional)")
                    input("targetSource", "Endocrinologist / target source")
                    Text("Intervals use the selected unit. The report interval and clinician target are distinct. Unknown dates and intervals stay blank.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else if kind == "medications" {
                    if defaults["name"] == nil {
                        menu("name", "Medicine or supplement", CareField.medicines)
                    }
                    input("formulation", "Formulation / route (optional)")
                    menu("doseMode", "Dose certainty", ["unknown", "exact", "range"])
                    if fields["doseMode"] != "unknown" {
                        input("doseLower", fields["doseMode"] == "range" ? "Patient-estimated lower dose" : "Exact dose")
                        if fields["doseMode"] == "range" { input("doseUpper", "Patient-estimated upper dose") }
                        menu("unit", "Dose unit", ["mcg", "mg", "g", "mL", "tablet"])
                    }
                    input("schedule", "Prescribed days / times, or PRN")
                    input("source", "Prescription / patient-reported source")
                    input("context", "Original wording / notes")
                    Text("An estimated range records uncertainty; it never tells you to choose a dose. Unknown doses remain unknown.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if fields["name"] == "Amiodarone" {
                        Text("Amiodarone is separate from thyroid replacement and may affect thyroid function in either direction. No hormone effect or equivalent thyroid dose is calculated.")
                            .font(.footnote)
                    }
                } else {
                    input("value", defaults["type"] == "bloodPressure" ? "Systolic pressure" : "Measured value")
                    if defaults["type"] == "bloodPressure" { input("diastolic", "Diastolic pressure") }
                    menu("unit", "Unit", vitalUnits)
                    input("observedDate", "Measurement date · YYYY-MM-DD")
                    input("source", "Home / office physical / device source")
                    input("context", "Measurement time / resting or activity context")
                }
                LandingButton(title: busy ? "Saving…" : "Save " + title) { Task { await save() } }
                    .disabled(busy)
                if let message { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }
            .padding(.top, 12)
        }
        .tint(ThyroUI.teal)
        .task {
            guard !initialized else { return }
            initialized = true
            fields = defaults
            fields["timezone"] = TimeZone.current.identifier
        }
        .onChange(of: fields["name"]) { _, name in
            if defaults["name"] == nil {
                fields["unit"] = ["Levothyroxine", "Liothyronine"].contains(name ?? "") ? "mcg" : "mg"
            }
        }
    }

    private var vitalUnits: [String] {
        switch defaults["type"] {
        case "weight": ["kg", "lb"]
        case "height": ["cm", "in"]
        case "BMI": ["kg/m²"]
        case "bloodPressure": ["mmHg"]
        default: ["bpm"]
        }
    }

    private func input(_ key: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            OpenTextField(title: label, text: value(key))
        }
    }

    private func menu(_ key: String, _ label: String, _ options: [String]) -> some View {
        Picker(label, selection: value(key)) {
            Text("Select / unknown").tag("")
            ForEach(options, id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.menu).padding()
        .background(ThyroUI.softGray).clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func save() async {
        guard store.session != nil else { message = "Sign in to save this record."; return }
        busy = true
        defer { busy = false }
        let previous = store.records.first { $0.id == recordID }
        let pending = store.pending.first { $0.id == recordID }
        let revision = previous?.version ?? pending?.expectedVersion ?? 0
        let identity = store.session?.user.id ?? ""
        let correction = PatientRecord(id: recordID, patientID: identity, kind: kind, version: revision, recordedAt: "", authorID: identity, fields: fields)
        if await store.save(kind: kind, fields: fields, correcting: correction) {
            message = store.pending.contains { $0.id == recordID } ? "Saved on device; waiting for server acknowledgement. " + (store.errorMessage ?? "") : "Saved and synchronized."
        } else { message = store.errorMessage }
    }
}
