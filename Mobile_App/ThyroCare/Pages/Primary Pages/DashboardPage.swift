import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject private var authManager: AuthManager
    let onLogout: () -> Void

    @State private var floatCards = false
    @AppStorage("severityScore") private var severityScore = 0
    @AppStorage("severityPercentile") private var severityPercentile = 0
    @AppStorage("tshDecrease") private var tshDecrease = 0

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
    }

    var body: some View {
        ThyroPageScaffold(title: "Dashboard") {
            ThyroCard {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome, \(authManager.userName.isEmpty ? "Patient" : authManager.userName)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)
                        Text("Your thyroid trends are ready for review.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image("DashboardThyroid")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .scaleEffect(floatCards ? 1.05 : 0.96)
                }
            }

            ThyroCard {
                HStack(spacing: 16) {
                    Image("DashboardLab")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .offset(y: floatCards ? -4 : 4)

                    VStack(alignment: .leading, spacing: 8) {
                        ThyroSectionTitle("Lab trend", subtitle: "Recent thyroid values compared across check-ins.")
                        AnimatedBarChart(
                            values: [0.86, 0.73, 0.64, 0.56],
                            labels: ["May", "Jun", "Jul", "Now"],
                            color: ThyroUI.teal
                        )
                    }
                }
            }

            ThyroCard {
                ThyroSectionTitle("Today")

                HStack(spacing: 28) {
                    AnimatedMetricRing(title: "Severity", value: Double(severityScore) / 100.0, color: ThyroUI.coral)
                    AnimatedMetricRing(title: "TSH improve", value: Double(tshDecrease) / 100.0, color: ThyroUI.teal)
                }
                .frame(maxWidth: .infinity)

                MetricRow(title: "Geometric severity score", value: "\(severityScore)/100", color: ThyroUI.coral)
                MetricRow(title: "Patient percentile", value: severityPercentile > 0 ? "\(severityPercentile)th" : "Pending", color: ThyroUI.amber)
                MetricRow(title: "Distance model", value: "Updated", color: ThyroUI.teal)
            }

            ThyroCard {
                HStack(spacing: 18) {
                    Image("DashboardDiet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(floatCards ? 3 : -3))

                    VStack(alignment: .leading, spacing: 10) {
                        ThyroSectionTitle("Nutrition snapshot")
                        MetricRow(title: "Protein", value: "28%", color: ThyroUI.teal)
                        MetricRow(title: "Carbs", value: "34%", color: ThyroUI.amber)
                        MetricRow(title: "Vitamins", value: "18%", color: ThyroUI.violet)
                        MetricRow(title: "Plants", value: "20%", color: ThyroUI.coral)
                    }
                }
            }

            Button(role: .destructive) {
                authManager.logOut()
                onLogout()
            } label: {
                Text(Constants.logoutString)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThyroUI.coral.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                floatCards = true
            }
        }
    }
}

#Preview {
    DashboardPage()
        .environmentObject(AuthManager())
}
