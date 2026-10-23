import SwiftUI
import Charts

struct CareSymptomTrends: View {
    let store: CareStore
    @State private var symptom = "fatigue"

    var observed: [PatientRecord] {
        store.entries("symptoms").filter { record in
            guard let rating = record.fields[symptom], let number = Int(rating) else { return false }
            return (0...4).contains(number)
        }
    }

    private var points: [SymptomChartPoint] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return observed.compactMap { record in
            guard let date = formatter.date(from: record.fields["observedDate"] ?? ""), let rating = Int(record.fields[symptom] ?? "") else { return nil }
            return SymptomChartPoint(id: record.id, date: date, rating: rating)
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Symptom", selection: $symptom) {
                    ForEach(CareField.symptoms, id: \.self) { key in Text(CareField.label(key)).tag(key) }
                }
                Text("Custom tracking scale: 0 None, 1 Mild, 2 Moderate, 3 Severe, 4 Very severe. Not a diagnostic score.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Daily observations") {
                if points.isEmpty { Text("No assessed ratings for this symptom.") }
                else {
                    Chart(points) { point in
                        PointMark(x: .value("Observation date", point.date), y: .value("Rating", point.rating))
                            .accessibilityLabel(point.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue("\(point.rating) out of 4")
                    }
                    .chartYScale(domain: 0...4)
                    .frame(height: 240)
                }
                Text("Missing days remain gaps. Each point is a reported observation; weekly recollections are separate.")
                    .font(.footnote)
                ForEach(observed) { record in
                    NavigationLink {
                        CareRecordDetail(store: store, record: record)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("\(record.fields["observedDate"] ?? "") · \(record.fields[symptom] ?? "") / 4")
                            Text(record.fields["timezone"] ?? "").font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("Weekly recollections") {
                ForEach(store.entries("weekly-checkins")) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(record.fields["recallStart"] ?? "") – \(record.fields["recallEnd"] ?? "")").font(.headline)
                        Text(record.fields["body"] ?? "")
                    }
                }
            }
        }
        .navigationTitle("Symptom trends")
    }
}

private struct SymptomChartPoint: Identifiable {
    let id: String
    let date: Date
    let rating: Int
}
