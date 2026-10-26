import SwiftUI

struct VerifiedUserPage: View {
    let onViewDashboard: () -> Void
    var onOpenDailyTasks: () -> Void

    init(
        onViewDashboard: @escaping () -> Void = {},
        onOpenDailyTasks: @escaping () -> Void = {}
    ) {
        self.onViewDashboard = onViewDashboard
        self.onOpenDailyTasks = onOpenDailyTasks
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

                    LandingButton(title: Constants.viewDashboardString, action: onViewDashboard)

                    Button(action: onOpenDailyTasks) {
                        HStack(spacing: 8) {
                            Image(systemName: "list.clipboard.fill")
                            Text("Open Daily Tasks")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(ThyroUI.navy)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ThyroUI.teal.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: ThyroUI.navy.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
            }
        }
    }
}

#Preview {
    VerifiedUserPage()
}
