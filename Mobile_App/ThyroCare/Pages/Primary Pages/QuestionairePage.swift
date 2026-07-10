import SwiftUI

struct QuestionairePage: View {
    @State private var agreedToTerms = false
    @State private var confirmedAge = false
    @State private var age = 18
    @State private var sex = "Female"
    @State private var tsh = ""
    @State private var t3 = ""
    @State private var t4 = ""
    @State private var hadTreatment = false
    @State private var pregnant = "No"
    @State private var lithium = "No"
    @State private var lithiumDose = ""
    @State private var tumor = "No"
    @State private var onMedication = false
    @State private var medicationDose = ""
    @State private var frequency = "Daily"
    @State private var protein = 24.0
    @State private var carbs = 38.0
    @State private var vitaminA = 8.0
    @State private var vitaminB = 7.0
    @State private var vitaminD = 8.0
    @State private var fruits = 7.0
    @State private var vegetables = 8.0
    @State private var waitHours = ""
    @State private var takesIronCalcium = false
    @State private var shouldShowPrediction = false
    @State private var submittedResult = ThyroSeverityResult.baseline

    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0
    @AppStorage("tshDecrease") private var storedTSHDecrease = 0
    @AppStorage("t3Improvement") private var storedT3Improvement = 0
    @AppStorage("t4Improvement") private var storedT4Improvement = 0
    @AppStorage("mealHistoryData") private var mealHistoryData = Data()

    private enum Nutrient: CaseIterable {
        case protein
        case carbs
        case vitaminA
        case vitaminB
        case vitaminD
        case fruits
        case vegetables
    }

    private let yesNo = ["Yes", "No"]
    private let sexes = ["Female", "Male", "Intersex", "Prefer not to say"]
    private let frequencies = ["Daily", "Weekly", "Biweekly", "Monthly"]

    var body: some View {
        ThyroPageScaffold(title: "Questionaire") {
            ThyroCard {
                ThyroSectionTitle("Before we start", subtitle: "Review the study terms and confirm eligibility.")

                Text("ThyroCare estimates thyroid risk from lab values, medication timing, treatment history, and diet habits. It does not replace medical advice.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Toggle("Agree with terms and conditions", isOn: $agreedToTerms)
                    .tint(ThyroUI.teal)
                Toggle("Confirm you're 13 or older", isOn: $confirmedAge)
                    .tint(ThyroUI.teal)
            }

            ThyroCard {
                ThyroSectionTitle("Labs", subtitle: "Please enter your age, biological sex, and most recent TSH, T3, and T4 levels.")

                OpenTextField(title: "Age", text: $age)

                Picker("Sex", selection: $sex) {
                    ForEach(sexes, id: \.self) { sex in
                        Text(sex)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(ThyroUI.softGray)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    OpenTextField(title: "TSH", text: $tsh)
                    OpenTextField(title: "T3", text: $t3)
                    OpenTextField(title: "T4", text: $t4)
                }
            }

            ThyroCard {
                ThyroSectionTitle("Treatment history", subtitle: "Have you undergone thyroid surgery or radioactive iodine treatment?")

                HStack {
                    Button { hadTreatment = true } label: {
                        ThyroChoicePill(title: "Yes", isSelected: hadTreatment)
                    }
                    Button { hadTreatment = false } label: {
                        ThyroChoicePill(title: "No", isSelected: !hadTreatment)
                    }
                }
                .buttonStyle(.plain)
            }

            ThyroCard {
                ThyroSectionTitle("Conditions", subtitle: "Are you pregnant, taking lithium, or diagnosed with a goiter or tumor?")

                conditionPicker(title: "Pregnant?", selection: $pregnant)
                conditionPicker(title: "Lithium?", selection: $lithium)

                if lithium == "Yes" {
                    OpenTextField(title: "Lithium dosage", text: $lithiumDose)
                }

                conditionPicker(title: "Tumor?", selection: $tumor)
            }

            ThyroCard {
                ThyroSectionTitle("Medication", subtitle: "Are you on Levothyroxine or antithyroid medication, and what is your exact dose?")

                HStack {
                    Button { onMedication = true } label: {
                        ThyroChoicePill(title: "Yes", isSelected: onMedication)
                    }
                    Button { onMedication = false } label: {
                        ThyroChoicePill(title: "No", isSelected: !onMedication)
                    }
                }
                .buttonStyle(.plain)

                if onMedication {
                    OpenTextField(title: "Dosage in mg", text: $medicationDose)

                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { frequency in
                            Text(frequency)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            ThyroCard {
                ThyroSectionTitle("Daily diet", subtitle: "Estimate your current macro and nutrient pattern.")

                HStack(alignment: .center, spacing: 18) {
                    DonutSegmentChart(
                        values: [protein, carbs, vitaminA + vitaminB + vitaminD, fruits + vegetables],
                        colors: [ThyroUI.teal, ThyroUI.amber, ThyroUI.violet, ThyroUI.coral]
                    )
                    .frame(width: 96, height: 96)

                    VStack(spacing: 8) {
                        MetricRow(title: "Protein", value: "\(Int(protein))%", color: ThyroUI.teal)
                        MetricRow(title: "Carbs", value: "\(Int(carbs))%", color: ThyroUI.amber)
                        MetricRow(title: "Vitamins", value: "\(Int(vitaminA + vitaminB + vitaminD))%", color: ThyroUI.violet)
                        MetricRow(title: "Plants", value: "\(Int(fruits + vegetables))%", color: ThyroUI.coral)
                        MetricRow(title: "Total", value: "\(Int(totalFoodPercent))%", color: ThyroUI.navy)
                    }
                }

                nutrientSlider("Protein", nutrient: .protein)
                nutrientSlider("Carbs", nutrient: .carbs)
                nutrientSlider("Vitamin A", nutrient: .vitaminA)
                nutrientSlider("Vitamin B", nutrient: .vitaminB)
                nutrientSlider("Vitamin D", nutrient: .vitaminD)
                nutrientSlider("Fruits", nutrient: .fruits)
                nutrientSlider("Vegetables", nutrient: .vegetables)
            }

            ThyroCard {
                ThyroSectionTitle("Medication timing", subtitle: "How long do you wait to eat after medication, and do you take iron or calcium?")

                OpenTextField(title: "Time in hours", text: $waitHours)
                Toggle("I take iron or calcium", isOn: $takesIronCalcium)
                    .tint(ThyroUI.teal)

                LandingButton(title: "Submit") {
                    submitQuestionaire()
                }
                .disabled(!agreedToTerms || !confirmedAge)
                .opacity(agreedToTerms && confirmedAge ? 1 : 0.55)
                .navigationDestination(isPresented: $shouldShowPrediction) {
                    PredictionPage(result: submittedResult)
                }
            }
        }
        .onAppear(perform: applyMealHistoryDietIfAvailable)
    }

    private func conditionPicker(title: String, selection: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ThyroUI.ink)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(yesNo, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(.menu)
            .tint(ThyroUI.teal)
        }
        .padding()
        .background(ThyroUI.softGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var totalFoodPercent: Double {
        protein + carbs + vitaminA + vitaminB + vitaminD + fruits + vegetables
    }

    private func nutrientSlider(_ title: String, nutrient: Nutrient) -> some View {
        let value = nutrientBinding(for: nutrient)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))%")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            Slider(value: value, in: 0...100, step: 1)
                .tint(ThyroUI.teal)
        }
    }

    private func nutrientBinding(for nutrient: Nutrient) -> Binding<Double> {
        Binding(
            get: { nutrientValue(for: nutrient) },
            set: { updateNutrient(nutrient, to: $0) }
        )
    }

    private func nutrientValue(for nutrient: Nutrient) -> Double {
        switch nutrient {
        case .protein: protein
        case .carbs: carbs
        case .vitaminA: vitaminA
        case .vitaminB: vitaminB
        case .vitaminD: vitaminD
        case .fruits: fruits
        case .vegetables: vegetables
        }
    }

    private func updateNutrient(_ nutrient: Nutrient, to newValue: Double) {
        let adjustedValue = min(max(newValue.rounded(), 0), 100)
        setNutrient(nutrient, to: adjustedValue)

        let otherNutrients = Nutrient.allCases.filter { $0 != nutrient }
        let remainingTotal = 100 - adjustedValue
        let currentOtherTotal = otherNutrients.map(nutrientValue).reduce(0, +)

        if currentOtherTotal <= 0 {
            let splitValue = (remainingTotal / Double(otherNutrients.count)).rounded()
            otherNutrients.forEach { setNutrient($0, to: splitValue) }
        } else {
            otherNutrients.forEach { other in
                let scaledValue = (nutrientValue(for: other) / currentOtherTotal * remainingTotal).rounded()
                setNutrient(other, to: scaledValue)
            }
        }

        let total = Nutrient.allCases.map(nutrientValue).reduce(0, +)
        let correction = 100 - total
        if correction != 0, let correctionTarget = otherNutrients.max(by: { nutrientValue(for: $0) < nutrientValue(for: $1) }) {
            let correctedValue = min(max(nutrientValue(for: correctionTarget) + correction, 0), 100)
            setNutrient(correctionTarget, to: correctedValue)
        }
    }

    private func setNutrient(_ nutrient: Nutrient, to value: Double) {
        switch nutrient {
        case .protein: protein = value
        case .carbs: carbs = value
        case .vitaminA: vitaminA = value
        case .vitaminB: vitaminB = value
        case .vitaminD: vitaminD = value
        case .fruits: fruits = value
        case .vegetables: vegetables = value
        }
    }

    private var severityResult: ThyroSeverityResult {
        ThyroSeverityScorer.score(profile: patientProfile)
    }

    private func applyMealHistoryDietIfAvailable() {
        guard !mealHistoryData.isEmpty,
              let scannedMeals = try? JSONDecoder().decode([MealAnalysis].self, from: mealHistoryData),
              !scannedMeals.isEmpty else {
            return
        }

        let recentMeals = Array(scannedMeals.prefix(7))
        let divisor = Double(recentMeals.count)
        let averageProtein = recentMeals.map(\.protein).reduce(0, +).asDouble / divisor
        let averageCarbs = recentMeals.map(\.carbs).reduce(0, +).asDouble / divisor
        let averageVitamins = recentMeals.map(\.vitamins).reduce(0, +).asDouble / divisor
        let averageProduce = recentMeals.map(\.produce).reduce(0, +).asDouble / divisor

        protein = averageProtein.rounded()
        carbs = averageCarbs.rounded()
        vitaminA = (averageVitamins * 0.30).rounded()
        vitaminB = (averageVitamins * 0.35).rounded()
        vitaminD = (averageVitamins * 0.35).rounded()
        fruits = (averageProduce * 0.45).rounded()
        vegetables = (averageProduce * 0.55).rounded()
    }

    private var patientProfile: ThyroPatientProfile {
        ThyroPatientProfile(
            age: age,
            sex: sex,
            tsh: tsh.numberValue,
            t3: t3.numberValue,
            t4: t4.numberValue,
            hadTreatment: hadTreatment,
            isPregnant: pregnant == "Yes",
            takesLithium: lithium == "Yes",
            lithiumDose: lithiumDose.numberValue,
            hasTumor: tumor == "Yes",
            onMedication: onMedication,
            medicationDose: medicationDose.numberValue,
            frequency: frequency,
            protein: protein,
            carbs: carbs,
            vitaminA: vitaminA,
            vitaminB: vitaminB,
            vitaminD: vitaminD,
            fruits: fruits,
            vegetables: vegetables,
            waitHours: waitHours.numberValue,
            takesIronCalcium: takesIronCalcium
        )
    }

    private func submitQuestionaire() {
        guard agreedToTerms && confirmedAge else { return }

        let result = severityResult
        submittedResult = result
        storedSeverityScore = result.score
        storedSeverityPercentile = result.percentile
        storedTSHDecrease = result.tshDecrease
        storedT3Improvement = result.t3Improvement
        storedT4Improvement = result.t4Improvement
        shouldShowPrediction = true
    }
}

private extension String {
    var numberValue: Double {
        Double(trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }
}

private extension Int {
    var asDouble: Double {
        Double(self)
    }
}

#Preview {
    NavigationStack {
        QuestionairePage()
    }
}
