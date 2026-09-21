import Charts
import SwiftUI

struct MedicationLogPage: View {
    @State private var demographicProfile = DemographicProfile(
        age: 35,
        biologicalSex: .female,
        raceEthnicity: .notSpecified,
        weightKilograms: 70,
        baselineTSH: 6.2,
        targetTSH: 2.0
    )
    @State private var medicationLog: [MedicationLogEntry] = [
        MedicationLogEntry(
            medicationName: "Levothyroxine",
            doseMicrograms: 75,
            frequency: .daily,
            dosesPerWeek: 7,
            adherencePercent: 95,
            minutesBeforeFood: 45,
            separatesIronCalciumByFourHours: true
        )
    ]
    @State private var projection: MedicationTSHProjection?

    var body: some View {
        ThyroPageScaffold(title: "Medication") {
            ThyroMedicalDisclaimer()
            medicationTelemetrySection
            demographicSection
            analyzeSection

            if let projection {
                projectionSection(projection)
            }
        }
        .onChange(of: medicationLog) { _, _ in
            projection = nil
        }
        .onChange(of: demographicProfile) { _, _ in
            projection = nil
        }
    }

    private var medicationTelemetrySection: some View {
        ThyroCard {
            ThyroSectionTitle("Medication log", subtitle: "Log thyroid medication exposure before running the model.")

            ForEach(medicationLog) { medication in
                MedicationLogRow(
                    medication: bindingForMedication(id: medication.id),
                    canDelete: medicationLog.count > 1,
                    onDelete: {
                        safelyDeleteMedication(id: medication.id)
                    }
                )
            }

            Button {
                medicationLog.append(Self.defaultMedication)
                projection = nil
            } label: {
                Label("Add medication", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ThyroUI.teal)
        }
    }

    private var demographicSection: some View {
        ThyroCard {
            ThyroSectionTitle("Demographic profile", subtitle: "Used to adjust statistical pharmacokinetic estimates, not diagnose disease.")

            HStack(spacing: 10) {
                IntegerInputField(title: "Age", value: $demographicProfile.age)
                DecimalInputField(title: "Weight kg", value: $demographicProfile.weightKilograms)
            }

            Picker("Biological sex", selection: $demographicProfile.biologicalSex) {
                ForEach(DemographicProfile.BiologicalSex.allCases) { sex in
                    Text(sex.rawValue).tag(sex)
                }
            }
            .pickerStyle(.segmented)

            Picker("Race/ethnicity", selection: $demographicProfile.raceEthnicity) {
                ForEach(DemographicProfile.RaceEthnicity.allCases) { race in
                    Text(race.rawValue).tag(race)
                }
            }

            HStack(spacing: 10) {
                DecimalInputField(title: "Current TSH", value: $demographicProfile.baselineTSH)
                DecimalInputField(title: "Target TSH", value: $demographicProfile.targetTSH)
            }
        }
    }

    private func bindingForMedication(id: MedicationLogEntry.ID) -> Binding<MedicationLogEntry> {
        Binding(
            get: {
                medicationLog.first(where: { $0.id == id }) ?? Self.defaultMedication
            },
            set: { updatedMedication in
                guard let index = medicationLog.firstIndex(where: { $0.id == id }) else {
                    return
                }

                medicationLog[index] = updatedMedication
            }
        )
    }

    private func safelyDeleteMedication(id: MedicationLogEntry.ID) {
        guard medicationLog.count > 1,
              medicationLog.contains(where: { $0.id == id }) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            medicationLog.removeAll { $0.id == id }
        }
        if medicationLog.isEmpty {
            medicationLog = [Self.defaultMedication]
        }
        projection = nil
    }

    private static var defaultMedication: MedicationLogEntry {
        MedicationLogEntry(
            medicationName: "Levothyroxine",
            doseMicrograms: 25,
            frequency: .daily,
            dosesPerWeek: 7,
            adherencePercent: 100,
            minutesBeforeFood: 30,
            separatesIronCalciumByFourHours: true
        )
    }

    private var analyzeSection: some View {
        LandingButton(title: "Analyze Effects") {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                projection = MedicationTSHPredictor.analyze(
                    medications: medicationLog,
                    demographicProfile: demographicProfile
                )
            }
        }
    }

    private func projectionSection(_ projection: MedicationTSHProjection) -> some View {
        ThyroCard {
            ThyroSectionTitle("Projected TSH", subtitle: "30-90 day medication response estimate")

            Chart(projection.points) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("TSH", point.tsh)
                )
                .foregroundStyle(ThyroUI.teal)
                .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Day", point.day),
                    y: .value("TSH", point.tsh)
                )
                .foregroundStyle(ThyroUI.coral)
            }
            .chartXAxisLabel("Days")
            .chartYAxisLabel("TSH mIU/L")
            .frame(height: 240)

            HStack(spacing: 12) {
                MetricBadge(title: "90-day TSH", value: String(format: "%.2f", projection.projectedTSHAt90Days), color: ThyroUI.teal)
                MetricBadge(title: "Target", value: String(format: "%.2f", projection.targetTSH), color: ThyroUI.violet)
            }

            Text(projection.summary)
                .font(.body)
                .foregroundStyle(ThyroUI.ink)
                .fixedSize(horizontal: false, vertical: true)

            DisclosureGroup("Clinical assumptions") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(projection.clinicalAssumptions, id: \.self) { assumption in
                        Label(assumption, systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .font(.subheadline.weight(.semibold))
        }
    }
}

private struct MedicationLogRow: View {
    @Binding var medication: MedicationLogEntry
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                TextField("Medication", text: $medication.medicationName)
                    .textFieldStyle(.roundedBorder)

                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.headline)
                            .foregroundStyle(ThyroUI.coral)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove medication")
                }
            }

            HStack(spacing: 10) {
                DecimalInputField(title: medication.frequency == .daily ? "Daily dose mcg" : "Weekly dose mcg", value: $medication.doseMicrograms)
                DecimalInputField(
                    title: "Adherence %",
                    value: $medication.adherencePercent,
                    infoMessage: "Adherence is the percent of prescribed doses you actually take. For example, 100% means every dose, while 80% means about 4 out of 5 doses."
                )
            }

            Picker("Frequency", selection: $medication.frequency) {
                ForEach(MedicationLogEntry.Frequency.allCases) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }
            .pickerStyle(.segmented)

            if medication.frequency == .daily {
                Stepper("Doses/week: \(medication.dosesPerWeek)", value: $medication.dosesPerWeek, in: 1...7)
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 10) {
                DecimalInputField(title: "Minutes before food", value: $medication.minutesBeforeFood)
                Toggle("4h iron/calcium gap", isOn: $medication.separatesIronCalciumByFourHours)
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 8)
    }
}

private struct DecimalInputField: View {
    let title: String
    @Binding var value: Double
    var infoMessage: String?

    @State private var showingInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let infoMessage {
                    Button {
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ThyroUI.teal)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("What is \(title)?")
                    .alert(title, isPresented: $showingInfo) {
                        Button("Got it", role: .cancel) {}
                    } message: {
                        Text(infoMessage)
                    }
                }
            }

            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct IntegerInputField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct MetricBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    MedicationLogPage()
}
