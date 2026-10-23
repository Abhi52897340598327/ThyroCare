import SwiftUI

/// Isolated, read-only fixtures. Never added to a CareStore's sync queue or patient account.
struct CareSampleDataView: View {
    private let records = Self.makeRecords()

    var body: some View {
        List {
            Section {
                Label("Simulated data", systemImage: "testtube.2").font(.headline)
                Text("Fictional examples for exploring the layout. These are not your measurements, a prescription or a treatment recommendation. They are never saved to your account or shared with your care team.")
            }
            CareLabChart(records: records.filter { $0.kind == "labs" }, unit: "mIU/L")
            Section("Example records") {
                ForEach(records) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SIMULATED").font(.caption.bold()).foregroundStyle(.secondary)
                        CareRecordRow(record: record)
                        if let value = record.fields["value"] { Text("\(value) \(record.fields["unit"] ?? "")").monospacedDigit() }
                        if record.kind == "medications" { Text("Dose unknown · fictional inventory entry").font(.footnote) }
                    }
                }
            }
        }
        .navigationTitle("Sample data")
    }

    private static func makeRecords() -> [PatientRecord] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        func record(_ id: String, _ kind: String, _ days: Int, _ fields: [String: String]) -> PatientRecord {
            let date = formatter.string(from: Date().addingTimeInterval(Double(-days) * 86_400))
            var values = fields
            values["observedDate"] = date
            values["source"] = "Simulated example — not patient data"
            values["simulated"] = "true"
            if kind == "labs" { values["collectedDate"] = date }
            return PatientRecord(id: id, patientID: "sample-only", kind: kind, version: 1, recordedAt: date, authorID: "sample-only", fields: values)
        }
        return [
            record("sample-lab-1", "labs", 90, ["analyte": "TSH", "result": "5.2", "unit": "mIU/L"]),
            record("sample-lab-2", "labs", 45, ["analyte": "TSH", "result": "3.8", "unit": "mIU/L"]),
            record("sample-lab-3", "labs", 7, ["analyte": "TSH", "result": "4.1", "unit": "mIU/L"]),
            record("sample-symptom", "symptoms", 2, ["name": "Fatigue · mild (1/4)", "fatigue": "1", "scaleVersion": "custom-0-4-v1"]),
            record("sample-vital", "vitals", 7, ["type": "Weight", "value": "72", "unit": "kg"]),
            record("sample-medication", "medications", 10, ["name": "Levothyroxine", "doseMode": "unknown"]),
            record("sample-meal", "meals", 1, ["description": "Oatmeal with berries — example meal", "mealTime": "08:00"])
        ]
    }
}
