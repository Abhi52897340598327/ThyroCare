import SwiftUI

struct SummaryPage: View {
    @AppStorage("severityScore") private var severityScore = 0
    @AppStorage("severityPercentile") private var severityPercentile = 0
    @AppStorage("tshDecrease") private var tshDecrease = 0
    @AppStorage("t3Improvement") private var t3Improvement = 0
    @AppStorage("t4Improvement") private var t4Improvement = 0

    private var normalizedSeverity: Double {
        Double(severityScore) / 100.0
    }

    var body: some View {
        ThyroPageScaffold(title: "Summary") {
            ThyroCard {
                ThyroSectionTitle("Latest check-in", subtitle: "A compact view of your questionnaire and predicted thyroid trend.")

                HStack(spacing: 14) {
                    AnimatedMetricRing(title: "Severity", value: normalizedSeverity, color: ThyroUI.coral)
                    VStack(alignment: .leading, spacing: 8) {
                        MetricRow(title: "Percentile", value: severityPercentile > 0 ? "\(severityPercentile)th" : "Pending", color: ThyroUI.coral)
                        MetricRow(title: "TSH outlook", value: severityScore > 65 ? "High" : "Moderate", color: ThyroUI.amber)
                        MetricRow(title: "Medication timing", value: "Tracked", color: ThyroUI.teal)
                        MetricRow(title: "Diet balance", value: "Scored", color: ThyroUI.violet)
                    }
                }
            }

            ThyroCard {
                ThyroSectionTitle("Projected improvements")

                AnimatedBarChart(
                    values: [Double(tshDecrease) / 100.0, Double(t3Improvement) / 100.0, Double(t4Improvement) / 100.0],
                    labels: ["TSH", "T3", "T4"],
                    color: ThyroUI.teal
                )

                Text("With consistent habits, ThyroCare predicts your TSH could decrease by \(tshDecrease)%, T3 improve by \(t3Improvement)%, and T4 improve by \(t4Improvement)%.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ThyroCard {
                ThyroSectionTitle("Algorithm snapshot")
                MetricRow(title: "Inputs standardized", value: "Complete", color: ThyroUI.teal)
                MetricRow(title: "Clinical weights applied", value: "Offline", color: ThyroUI.amber)
                MetricRow(title: "Geometric distance score", value: "\(severityScore)/100", color: ThyroUI.coral)
            }
        }
    }
}

#Preview {
    SummaryPage()
}
