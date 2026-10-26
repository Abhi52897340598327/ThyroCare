import Charts
import SwiftUI

struct MedicationLogPage: View {
    var store: CareStore?
    @State private var showingModelLimit = false
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
    @State private var isAnalyzing = false
    @State private var aiReview: MedicationReviewResponse?

    var body: some View {
        ThyroPageScaffold(title: "Medication") {
            ThyroMedicalDisclaimer()
            medicationTelemetrySection
            demographicSection
            analyzeSection

            if let aiReview {
                aiReviewSection(aiReview)
            } else if let projection {
                projectionSection(projection)
            }
        }
        .onChange(of: medicationLog) { _, _ in
            projection = nil
            aiReview = nil
        }
        .onChange(of: demographicProfile) { _, _ in
            projection = nil
            aiReview = nil
        }
    }

    private var medicationTelemetrySection: some View {
        ThyroCard {
            ThyroSectionTitle("Medication log", subtitle: "Log thyroid medication exposure before running the model.")

            if let store {
                QuestionnaireRecordFields(store: store, kind: "medications", title: "Add medication", defaults: ["doseMode": "unknown", "unit": "mcg"])
                ForEach(store.entries("medications")) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.title).font(.headline)
                        Text(record.fields["doseMode"] == "range" ? "Patient-estimated range: \(record.fields["doseLower"] ?? "")–\(record.fields["doseUpper"] ?? "") \(record.fields["unit"] ?? "")" : record.fields["doseMode"] == "exact" ? "\(record.fields["doseLower"] ?? "") \(record.fields["unit"] ?? "")" : "Dose not confirmed")
                        Text(record.fields["schedule"] ?? "Schedule unknown").font(.subheadline)
                    }
                }
                NavigationLink("Medication reminders") { CareReminderCenter(store: store) }
            }
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
        VStack(spacing: 8) {
            Button {
                guard !isAnalyzing else { return }
                isAnalyzing = true
                Task {
                    let response = await MedicationReviewService.shared.review(
                        medications: medicationLog,
                        demographicProfile: demographicProfile
                    )
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        aiReview = response
                        isAnalyzing = false
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.white)
                        Text("Analyzing with Gemini 3.5 Flash...")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "sparkles")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(ThyroUI.mint)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Review Medication Effects")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Compute PK Kinetics & Gemini 3.5 Flash Model")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.88))
                        }

                        Spacer()

                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [ThyroUI.teal, ThyroUI.navy],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: ThyroUI.teal.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isAnalyzing)
        }
    }

    private func aiReviewSection(_ review: MedicationReviewResponse) -> some View {
        VStack(spacing: 16) {
            ThyroCard {
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(ThyroUI.teal)
                            Text("Gemini 3.5 Flash Clinical Review")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }

                        Spacer()

                        Text(review.model)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ThyroUI.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ThyroUI.mint)
                            .clipShape(Capsule())
                    }

                    // Summary Callout
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(ThyroUI.teal)
                            Text("Clinical Synthesis")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThyroUI.teal)
                        }
                        Text(review.summary)
                            .font(.subheadline)
                            .foregroundStyle(ThyroUI.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(ThyroUI.mint.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Pharmacokinetic Math Metrics Grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pharmacokinetic Parameters")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            PKMetricTile(
                                label: "Oral Bioavailability (F)",
                                value: "\(String(format: "%.1f", review.pharmacokinetics.bioavailabilityPercent))%",
                                subtitle: "Fasting & GI adjusted",
                                color: ThyroUI.teal
                            )
                            PKMetricTile(
                                label: "Elimination Half-Life (t½)",
                                value: "\(Int(review.pharmacokinetics.halfLifeHours / 24)) days",
                                subtitle: "\(Int(review.pharmacokinetics.halfLifeHours)) hrs standard",
                                color: ThyroUI.violet
                            )
                            PKMetricTile(
                                label: "Steady-State Exposure (Css)",
                                value: "\(String(format: "%.1f", review.pharmacokinetics.steadyStateConcentration)) ng/mL",
                                subtitle: "Avg circulating level",
                                color: ThyroUI.coral
                            )
                            PKMetricTile(
                                label: "Total Clearance (CL)",
                                value: "\(String(format: "%.3f", review.pharmacokinetics.clearanceLitersPerHour)) L/hr",
                                subtitle: "Renal & hepatic rate",
                                color: ThyroUI.amber
                            )
                            PKMetricTile(
                                label: "Time to Steady-State",
                                value: "\(review.pharmacokinetics.daysToSteadyState) days",
                                subtitle: "5 × elimination t½",
                                color: ThyroUI.teal
                            )
                            PKMetricTile(
                                label: "Effective Daily Dose",
                                value: "\(Int(review.pharmacokinetics.effectiveDailyDose.rounded())) mcg",
                                subtitle: "Adherence scaled",
                                color: ThyroUI.navy
                            )
                        }
                    }

                    Divider()

                    // Specific Medication Effects & Mechanism of Action
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "pills.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(ThyroUI.teal)
                            Text("Specific Medication Effects & Mechanism")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }
                        Text(review.mechanismOfAction)
                            .font(.footnote)
                            .foregroundStyle(ThyroUI.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Thyroid Hormone Impact
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(ThyroUI.teal)
                            Text("Impact on Thyroid Levels")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }

                        HStack(spacing: 8) {
                            HormoneShiftBadge(
                                hormone: "TSH (90d)",
                                value: String(format: "%.2f", review.projectedTSHAt90Days),
                                unit: "mIU/L",
                                baseline: String(format: "%.1f", demographicProfile.baselineTSH),
                                isReduction: review.projectedTSHAt90Days < demographicProfile.baselineTSH,
                                color: ThyroUI.teal
                            )
                            HormoneShiftBadge(
                                hormone: "Free T4 Shift",
                                value: String(format: "+%.2f", review.pharmacokinetics.freeT4Shift),
                                unit: "ng/dL",
                                baseline: "Baseline",
                                isReduction: false,
                                color: ThyroUI.violet
                            )
                            HormoneShiftBadge(
                                hormone: "Free T3 Shift",
                                value: String(format: "+%.2f", review.pharmacokinetics.freeT3Shift),
                                unit: "pg/mL",
                                baseline: "Baseline",
                                isReduction: false,
                                color: ThyroUI.amber
                            )
                        }

                        Text(review.thyroidHormoneImpact)
                            .font(.footnote)
                            .foregroundStyle(ThyroUI.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Absorption & Interactions Advisory
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(ThyroUI.amber)
                            Text("Absorption & Interactions Advisory")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }
                        Text(review.absorptionInteractions)
                            .font(.footnote)
                            .foregroundStyle(ThyroUI.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Clinical Guidance & Key Takeaways
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "cross.case.fill")
                                .font(.subheadline)
                                .foregroundStyle(ThyroUI.teal)
                            Text("Clinical Guidance & Key Takeaways")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }
                        Text(review.clinicalGuidance)
                            .font(.footnote)
                            .foregroundStyle(ThyroUI.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(review.keyTakeaways, id: \.self) { takeaway in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(ThyroUI.teal)
                                        .padding(.top, 2)
                                    Text(takeaway)
                                        .font(.caption)
                                        .foregroundStyle(ThyroUI.ink)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }

            // 90-Day Projected TSH Response Curve Chart
            ThyroCard {
                VStack(alignment: .leading, spacing: 10) {
                    ThyroSectionTitle("Projected TSH Curve", subtitle: "90-day trajectory reaching pharmacokinetic steady state")

                    let days = [0, 15, 30, 45, 60, 75, 90]
                    let pts = days.map { day -> (day: Int, tsh: Double) in
                        let frac = 1.0 - exp(-Double(day) / 42.0)
                        let v = demographicProfile.baselineTSH + (review.projectedTSHAt90Days - demographicProfile.baselineTSH) * frac
                        return (day: day, tsh: (v * 100).rounded() / 100)
                    }

                    Chart(pts, id: \.day) { pt in
                        LineMark(
                            x: .value("Day", pt.day),
                            y: .value("TSH", pt.tsh)
                        )
                        .foregroundStyle(ThyroUI.teal)
                        .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                        PointMark(
                            x: .value("Day", pt.day),
                            y: .value("TSH", pt.tsh)
                        )
                        .foregroundStyle(ThyroUI.coral)
                    }
                    .chartXAxisLabel("Days from start")
                    .chartYAxisLabel("TSH mIU/L")
                    .frame(height: 200)

                    HStack(spacing: 12) {
                        MetricBadge(title: "Steady-State TSH", value: String(format: "%.2f", review.projectedTSHAt90Days), color: ThyroUI.teal)
                        MetricBadge(title: "Target TSH", value: String(format: "%.2f", review.targetTSH), color: ThyroUI.violet)
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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


// MARK: - Pharmacokinetic UI Helper Components

struct PKMetricTile: View {
    let label: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ThyroUI.navy)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct HormoneShiftBadge: View {
    let hormone: String
    let value: String
    let unit: String
    let baseline: String
    let isReduction: Bool
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(hormone)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ThyroUI.navy)
                Text(unit)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text("from \(baseline)")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
