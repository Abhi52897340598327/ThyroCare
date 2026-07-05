import SwiftUI

struct PredictionPage: View {
    let result: ThyroSeverityResult

    @State private var showDetails = false
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

        ThyroPageScaffold(title: "Results") {
            ThyroCard {
                HStack(alignment: .center, spacing: 18) {
                    AnimatedMetricRing(title: "Severity Score", value: currentResult.normalizedScore, color: ThyroUI.coral)

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
            }

            ThyroCard {
                ThyroSectionTitle("Current risk", subtitle: currentResult.futureRiskSummary)

                Text(currentResult.currentRiskSummary)
                    .font(.body)
                    .foregroundStyle(ThyroUI.ink)

                AnimatedBarChart(
                    values: [currentResult.normalizedScore, max(currentResult.normalizedScore - 0.12, 0.05), 0.48, Double(currentResult.percentile) / 100.0],
                    labels: ["Risk", "TSH", "T4", "Pct"],
                    color: ThyroUI.coral
                )
            }

            ThyroCard {
                ThyroSectionTitle("You are not alone", subtitle: "It is ok. Many people are in the same boat as you.")

                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < similarPatientIconCount(for: currentResult.score) ? "person.fill" : "person")
                            .font(.title2)
                            .foregroundStyle(index < similarPatientIconCount(for: currentResult.score) ? ThyroUI.teal : ThyroUI.softGray)
                    }
                    Spacer()
                    Text("\(similarPatientIconCount(for: currentResult.score)) in 5")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ThyroUI.navy)
                }
            }

            ThyroCard {
                ThyroSectionTitle("With ThyroCare", subtitle: "We predict your TSH, T3, and T4 can improve with consistent changes.")

                HStack(spacing: 28) {
                    AnimatedMetricRing(title: "TSH decrease", value: Double(currentResult.tshDecrease) / 100.0, color: ThyroUI.teal)
                    AnimatedMetricRing(title: "T3 improve", value: Double(currentResult.t3Improvement) / 100.0, color: ThyroUI.amber)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 14) {
                    AnimatedMetricRing(title: "T4 improve", value: Double(currentResult.t4Improvement) / 100.0, color: ThyroUI.violet)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take control of your levels with ThyroCare")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)
                        Text("Use the dashboard to track labs, diet, and medication timing after each check-in.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(spacing: 14) {
                LandingButton(title: "Lets Go!") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showDetails.toggle()
                    }
                }

                Button("Thanks but no") {
                    showDetails = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
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

    private func similarPatientIconCount(for score: Int) -> Int {
        min(max(Int((Double(score) / 100.0 * 5.0).rounded()), 1), 5)
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

#Preview {
    PredictionPage()
}
