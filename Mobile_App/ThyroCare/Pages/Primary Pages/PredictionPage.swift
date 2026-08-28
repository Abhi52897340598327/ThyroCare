import Charts
import SwiftUI

struct PredictionPage: View {
    let result: ThyroSeverityResult

    @State private var showDetails = false
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

    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0
    @AppStorage("tshDecrease") private var storedTSHDecrease = 0
    @AppStorage("t3Improvement") private var storedT3Improvement = 0
    @AppStorage("t4Improvement") private var storedT4Improvement = 0

    init(result: ThyroSeverityResult? = nil) {
        if let result {
            self.result = result
        } else {
            self.result = ThyroSeverityResult.baseline
        }
    }

    private var displayedResult: ThyroSeverityResult {
        if result.score > 0 {
            return result
        }

        guard storedSeverityScore > 0 else {
            return result
        }

        return ThyroSeverityResult(
            score: storedSeverityScore,
            percentile: storedSeverityPercentile,
            tshDecrease: storedTSHDecrease,
            t3Improvement: storedT3Improvement,
            t4Improvement: storedT4Improvement,
            currentRiskSummary: "This score was generated from your latest questionnaire using weighted geometric distance.",
            futureRiskSummary: "If your current habits continue, ThyroCare expects your thyroid trend to follow this risk band."
        )
    }

    var body: some View {
        let currentResult = displayedResult

        ThyroPageScaffold(title: "Prediction") {
            ThyroMedicalDisclaimer()
            medicationTelemetrySection
            demographicSection
            analyzeSection

            if let projection {
                projectionSection(projection)
            }

            questionnaireResultSection(currentResult)
        }
    }

    private var medicationTelemetrySection: some View {
        ThyroCard {
            ThyroSectionTitle("Medication log", subtitle: "Log thyroid medication exposure before running the model.")

            ForEach($medicationLog) { $medication in
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Medication", text: $medication.medicationName)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 10) {
                        DecimalInputField(title: "Dose mcg", value: $medication.doseMicrograms)
                        DecimalInputField(title: "Adherence %", value: $medication.adherencePercent)
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

            Button {
                medicationLog.append(
                    MedicationLogEntry(
                        medicationName: "Levothyroxine",
                        doseMicrograms: 25,
                        frequency: .daily,
                        dosesPerWeek: 7,
                        adherencePercent: 100,
                        minutesBeforeFood: 30,
                        separatesIronCalciumByFourHours: true
                    )
                )
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
            ThyroSectionTitle("Demographic profile", subtitle: "Used to adjust the statistical baseline, not to diagnose disease.")

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

    private func questionnaireResultSection(_ currentResult: ThyroSeverityResult) -> some View {
        Group {
            ThyroCard {
                ThyroSectionTitle("Questionnaire score", subtitle: currentResult.futureRiskSummary)

                HStack(alignment: .center, spacing: 18) {
                    AnimatedMetricRing(title: "Severity", value: currentResult.normalizedScore, color: ThyroUI.coral)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Severity Score (0-100)")
                            .font(.headline)
                            .foregroundStyle(ThyroUI.navy)
                        Text("\(currentResult.score)%")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(ThyroUI.coral)
                        Text("You are in the \(ordinal(currentResult.percentile)) percentile of all patients.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(currentResult.currentRiskSummary)
                    .font(.body)
                    .foregroundStyle(ThyroUI.ink)
            }

            VStack(spacing: 14) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showDetails.toggle()
                    }
                } label: {
                    Label(showDetails ? "Hide scoring logic" : "Show scoring logic", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(ThyroUI.navy)
            }

            if showDetails {
                ThyroCard {
                    ThyroSectionTitle("Scoring logic")
                    Text("The system standardizes the questionnaire inputs, applies offline clinical weights, plots your profile between perfect health and clinical failure, then converts relative distance into the 0-to-100 score.")
                        .foregroundStyle(.secondary)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func ordinal(_ number: Int) -> String {
        let suffix: String
        let ones = number % 10
        let tens = (number / 10) % 10

        if tens == 1 {
            suffix = "th"
        } else if ones == 1 {
            suffix = "st"
        } else if ones == 2 {
            suffix = "nd"
        } else if ones == 3 {
            suffix = "rd"
        } else {
            suffix = "th"
        }

        return "\(number)\(suffix)"
    }
}

private struct DecimalInputField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
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
    PredictionPage()
}
