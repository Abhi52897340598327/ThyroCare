import SwiftUI

struct VerifiedUserPage: View {
    let onViewDashboard: () -> Void

    init(onViewDashboard: @escaping () -> Void = {}) {
        self.onViewDashboard = onViewDashboard
    }

    var body: some View {
        ThyroPageScaffold {
            VStack(spacing: 18) {
                ThyroidVectorArt()
                    .frame(maxWidth: .infinity)

                Text(Constants.appName)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(ThyroUI.navy)
                    .frame(maxWidth: .infinity)

                ThyroCard {
                    ThyroSectionTitle("Your account is verified", subtitle: "View your dashboard or continue checking in with new data.")

                    HStack(spacing: 14) {
                        AnimatedMetricRing(title: "Profile", value: 0.92, color: ThyroUI.teal)
                        VStack(alignment: .leading, spacing: 8) {
                            MetricRow(title: "Status", value: "Verified", color: ThyroUI.teal)
                            MetricRow(title: "Dashboard", value: "Ready", color: ThyroUI.amber)
                            MetricRow(title: "Questionaire", value: "Open", color: ThyroUI.violet)
                        }
                    }

                    LandingButton(title: Constants.buttonTitles[2], action: onViewDashboard)
                }
            }
        }
    }
}

#Preview {
    VerifiedUserPage()
}
