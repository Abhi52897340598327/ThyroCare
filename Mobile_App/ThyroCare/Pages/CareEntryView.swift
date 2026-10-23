import SwiftUI
import PhotosUI

enum CareField {
    static let analytes = ["TSH", "Free T4", "Free T3", "Total T4", "Total T3"]
    static let units = ["TSH": ["mIU/L", "µIU/mL"], "Free T4": ["ng/dL", "pmol/L"], "Free T3": ["pg/mL", "pmol/L"], "Total T4": ["µg/dL", "nmol/L"], "Total T3": ["ng/dL", "nmol/L"]]
    static let symptoms = ["fatigue", "concentration", "mood", "sleep", "temperature", "palpitations", "tremor", "bowel", "muscle", "skinHair"]
    static let medicines = ["Levothyroxine", "Liothyronine", "Methimazole", "Propylthiouracil", "Lithium", "Amiodarone", "Iron supplement", "Calcium supplement", "Biotin", "Other"]
    static let labels = [
        "collectedDate": "Blood collected (YYYY-MM-DD; optional)", "receivedDate": "Result received (YYYY-MM-DD; optional)",
        "referenceLower": "Report interval lower bound", "referenceUpper": "Report interval upper bound",
        "targetLower": "Clinician target lower bound", "targetUpper": "Clinician target upper bound", "targetSource": "Clinician target source",
        "observedDate": "Observation date (YYYY-MM-DD)", "recallStart": "Recall window start (YYYY-MM-DD)", "recallEnd": "Recall window end (YYYY-MM-DD)",
        "doseLower": "Exact dose or estimated lower bound", "doseUpper": "Estimated upper bound", "doseMode": "Dose certainty",
        "skinHair": "Skin or hair concerns", "temperature": "Temperature intolerance", "bowel": "Bowel changes",
        "fatigue": "Fatigue / low energy", "concentration": "Concentration difficulty", "mood": "Mood concerns", "sleep": "Sleep difficulty",
        "palpitations": "Palpitations (reported)", "tremor": "Tremor", "muscle": "Muscle symptoms",
        "mealTime": "Actual meal time (HH:mm)", "diet": "Diet or eating pattern, if you know it",
        "body": "Your entry", "source": "Source / report / context", "schedule": "Recorded schedule (days and times)",
        "interference": "Daily-life interference", "context": "Context and notes", "scaleVersion": "Scale version",
        "result": "Result (including < or > when reported)", "diastolic": "Diastolic pressure", "state": "Documentation state"
    ]
    static func label(_ key: String) -> String { labels[key] ?? key.capitalized }
}

struct CareEntryView: View {
    let store: CareStore
    let kind: String
    var correcting: PatientRecord?
    var prefilled: [String: String] = [:]
    @Environment(\.dismiss) private var dismiss
    @State private var fields: [String: String] = [:]
    @State private var saving = false
    @State private var mealPhoto: Data?
    @State private var initialized = false
    @State private var validationError: String?

    private func value(_ key: String) -> Binding<String> {
        Binding(get: { fields[key] ?? "" }, set: { fields[key] = $0 })
    }

    var body: some View {
        Form {
            if correcting != nil {
                Section { Text("This correction creates a new revision. The original remains in the server history.") }
            }
            switch kind {
            case "labs":
                Section("Measured result") {
                    Picker("Analyte", selection: value("analyte")) {
                        ForEach(CareField.analytes, id: \.self) { Text($0) }
                    }
                    .onChange(of: fields["analyte"]) { _, analyte in fields["unit"] = CareField.units[analyte ?? ""]?.first }
                    TextField(CareField.label("result"), text: value("result"))
                        .keyboardType(.numbersAndPunctuation)
                    Picker("Unit from report", selection: value("unit")) {
                        ForEach(CareField.units[fields["analyte"] ?? "TSH"] ?? [], id: \.self) { Text($0) }
                    }
                    Text("Free and total hormones are separate measurements. Add only tests actually reported.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Dates and source") {
                    CareTextFields(keys: ["collectedDate", "receivedDate", "source"], fields: $fields)
                    Text("Leave unknown dates blank. Today is never inserted as the collection date.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Laboratory reference interval · optional") {
                    CareTextFields(keys: ["referenceLower", "referenceUpper"], fields: $fields)
                    Text("Use the selected result unit. Missing intervals stay unknown.").font(.footnote)
                }
                Section("Clinician target · separate and optional") {
                    CareTextFields(keys: ["targetLower", "targetUpper", "targetSource"], fields: $fields)
                }
            case "symptoms":
                Section("Daily diary") {
                    CareTextFields(keys: ["observedDate"], fields: $fields)
                    Text("Custom tracking scale: 0 None, 1 Mild, 2 Moderate, 3 Severe, 4 Very severe. This is not a validated diagnostic score.")
                        .font(.footnote).foregroundStyle(.secondary)
                    ForEach(CareField.symptoms, id: \.self) { key in
                        Picker(CareField.label(key), selection: value(key)) {
                            Text("Not assessed").tag("")
                            Text("0 · None").tag("0")
                            Text("1 · Mild").tag("1")
                            Text("2 · Moderate").tag("2")
                            Text("3 · Severe").tag("3")
                            Text("4 · Very severe").tag("4")
                        }
                    }
                    CareTextFields(keys: ["interference", "context"], fields: $fields)
                }
            case "weekly-checkins":
                Section("Separate seven-day recollection") {
                    CareTextFields(keys: ["recallStart", "recallEnd"], fields: $fields)
                    Text("Describe symptom burden, missed doses or medicine changes, side effects, illness, and questions for your care team. This custom check-in does not create daily ratings.")
                    TextField("Weekly review", text: value("body"), axis: .vertical).lineLimit(5...12)
                }
            case "medications":
                Section("Medicine or supplement") {
                    Picker("Name", selection: value("name")) {
                        Text("Select a medicine or supplement").tag("")
                        ForEach(CareField.medicines, id: \.self) { Text($0) }
                    }
                    .onChange(of: fields["name"]) { _, name in
                        fields["unit"] = ["Levothyroxine", "Liothyronine"].contains(name ?? "") ? "mcg" : "mg"
                    }
                    if fields["name"] == "Other" { TextField("Original medicine name", text: value("originalName")) }
                    TextField("Formulation / route", text: value("formulation"))
                    MedicationDoseInput(fields: $fields)
                    CareTextFields(keys: ["schedule", "source", "context"], fields: $fields)
                    Text("Do you take an iron supplement? Record it as its own entry. Calcium and biotin can be entered separately.")
                        .font(.footnote)
                    if fields["name"] == "Amiodarone" {
                        Text("Amiodarone is recorded separately from thyroid replacement. No equivalent thyroid dose or predicted hormone effect is calculated.")
                            .font(.footnote)
                    }
                }
            case "vitals":
                Section("Measured observation") {
                    Picker("Measurement", selection: value("type")) {
                        Text("Weight").tag("weight"); Text("Height").tag("height"); Text("BMI (entered)").tag("BMI")
                        Text("Blood pressure").tag("bloodPressure"); Text("Heart rate").tag("heartRate")
                    }
                    TextField(fields["type"] == "bloodPressure" ? "Systolic pressure" : "Measured value", text: value("value")).keyboardType(.decimalPad)
                    if fields["type"] == "bloodPressure" { TextField("Diastolic pressure", text: value("diastolic")).keyboardType(.decimalPad) }
                    TextField("Unit (kg, lb, cm, in, kg/m², mmHg or bpm)", text: value("unit"))
                    CareTextFields(keys: ["observedDate", "source", "context"], fields: $fields)
                }
            case "meals":
                if correcting == nil {
                    Section("Meal photo · optional") {
                        CareMealPhotoInput(photo: $mealPhoto)
                    }
                }
                Section("Meal context") {
                    TextField("Foods, portions and preparation", text: value("description"), axis: .vertical)
                    CareTextFields(keys: ["observedDate", "mealTime", "diet", "context"], fields: $fields)
                    Picker("Meal", selection: value("mealType")) {
                        ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { Text($0) }
                    }
                    Text("No nutrient quantities or hormone changes are inferred from this description. Analysis is unavailable.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            default:
                Section(kind == "messages" ? "Message to your connected care team" : "Request information") {
                    if kind == "requests" {
                        Picker("Request type", selection: value("requestType")) {
                            ForEach(["Result clarification", "Reference or target interval", "Medication confirmation", "Report copy", "Appointment question"], id: \.self) { Text($0) }
                        }
                    }
                    TextField("Write your message", text: value("body"), axis: .vertical).lineLimit(4...12)
                    TextField("Linked record ID (optional)", text: value("linkedRecordID"))
                    Text("Recipients: " + store.careTeam.map(\.name).joined(separator: ", "))
                        .font(.footnote)
                }
            }
            if let validationError { Section { Text(validationError).foregroundStyle(.red) } }
            Section {
                Button(saving ? "Saving…" : "Save record") {
                    Task {
                        guard validate() else { return }
                        saving = true
                        if mealPhoto != nil { fields["hasPhoto"] = "true" }
                        let saved = await store.save(kind: kind, fields: fields, correcting: correcting, photo: mealPhoto)
                        saving = false
                        if saved { dismiss() }
                    }
                }
                .disabled(saving || (["messages", "requests"].contains(kind) && store.careTeam.isEmpty))
                if ["messages", "requests"].contains(kind) && store.careTeam.isEmpty {
                    Text("Connect a care team before sending.").font(.footnote)
                }
            }
        }
        .navigationTitle(correcting == nil ? "Add record" : "Correct record")
        .task {
            guard !initialized else { return }
            initialized = true
            if let correcting {
                fields = correcting.fields
            } else {
                fields = ["timezone": TimeZone.current.identifier]
                switch kind {
                case "labs": fields.merge(["analyte": "TSH", "unit": "mIU/L"]) { _, new in new }
                case "medications": fields.merge(["name": "", "doseMode": "unknown", "unit": "mcg"]) { _, new in new }
                case "symptoms": fields["scaleVersion"] = "custom-0-4-v1"
                case "vitals": fields.merge(["type": "weight", "unit": "kg"]) { _, new in new }
                case "meals": fields["mealType"] = "Breakfast"
                case "requests": fields.merge(["requestType": "Result clarification", "status": "Submitted"]) { _, new in new }
                default: break
                }
                fields.merge(prefilled) { _, supplied in supplied }
            }
        }
    }

    private func validate() -> Bool {
        let required: [String]
        switch kind {
        case "labs": required = ["result", "source"]
        case "symptoms": required = ["observedDate"]
        case "weekly-checkins": required = ["recallStart", "recallEnd", "body"]
        case "medications": required = ["name", "schedule"]
        case "vitals": required = ["value", "unit", "observedDate", "source"]
        case "meals": required = ["description", "observedDate", "mealTime"]
        default: required = ["body"]
        }
        for key in required where (fields[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Please supply " + CareField.label(key).lowercased() + "."
            return false
        }
        validationError = nil
        return true
    }
}

struct CareTextFields: View {
    let keys: [String]
    @Binding var fields: [String: String]
    var body: some View {
        ForEach(keys, id: \.self) { key in
            TextField(CareField.label(key), text: Binding(get: { fields[key] ?? "" }, set: { fields[key] = $0 }))
                .textInputAutocapitalization(.sentences)
        }
    }
}

struct MedicationDoseInput: View {
    @Binding var fields: [String: String]
    var body: some View {
        Picker("Dose certainty", selection: Binding(get: { fields["doseMode"] ?? "unknown" }, set: { fields["doseMode"] = $0 })) {
            Text("Exact dose").tag("exact")
            Text("Approximate range").tag("range")
            Text("Not sure").tag("unknown")
        }
        if fields["doseMode"] != "unknown" {
            CareTextFields(keys: ["doseLower"], fields: $fields)
            if fields["doseMode"] == "range" {
                CareTextFields(keys: ["doseUpper"], fields: $fields)
                Text("Patient-estimated range — not an instruction to choose a dose.").font(.footnote)
            }
            Picker("Dose unit", selection: Binding(get: { fields["unit"] ?? "mcg" }, set: { fields["unit"] = $0 })) {
                ForEach(["mcg", "mg", "g", "mL", "tablet"], id: \.self) { Text($0) }
            }
        }
        Text("Follow the confirmed prescription. This entry does not create or change a treatment instruction.")
            .font(.footnote).foregroundStyle(.secondary)
    }
}
