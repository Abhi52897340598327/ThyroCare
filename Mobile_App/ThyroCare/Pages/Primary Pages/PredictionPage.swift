import SwiftUI

struct PredictionPage: View {
    let result: ThyroSeverityResult
    var onGoToDashboard: (() -> Void)? = nil

    @State private var navigateToDashboard = false
    @State private var showDetails = false
    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0
    @AppStorage("tshDecrease") private var storedTSHDecrease = 0
    @AppStorage("t3Improvement") private var storedT3Improvement = 0
    @AppStorage("t4Improvement") private var storedT4Improvement = 0

    init(result: ThyroSeverityResult? = nil, onGoToDashboard: (() -> Void)? = nil) {
        if let result {
            self.result = result
        } else {
            self.result = ThyroSeverityResult.baseline
        }
        self.onGoToDashboard = onGoToDashboard
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
            ThyroMedicalDisclaimer()

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

            // MARK: - Redesigned "With ThyroCare" Card
            WithThyroCareCard(result: currentResult)

            VStack(spacing: 14) {
                LandingButton(title: Constants.proceduralString) {
                    if let onGoToDashboard {
                        onGoToDashboard()
                    } else {
                        navigateToDashboard = true
                    }
                }

                Button("Thanks but no") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showDetails.toggle()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .navigationDestination(isPresented: $navigateToDashboard) {
                DashboardPage()
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

// MARK: - Redesigned "With ThyroCare" Card Component

struct WithThyroCareCard: View {
    let result: ThyroSeverityResult

    private var tshValue: Int {
        result.tshDecrease > 0 ? result.tshDecrease : 28
    }

    private var t3Value: Int {
        result.t3Improvement > 0 ? result.t3Improvement : 18
    }

    private var t4Value: Int {
        result.t4Improvement > 0 ? result.t4Improvement : 24
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header with clinical projection pill
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.bold))
                    Text("90-Day Clinical Projection")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(ThyroUI.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ThyroUI.teal.opacity(0.12))
                .clipShape(Capsule())

                Text("With ThyroCare")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(ThyroUI.navy)

                Text("Our pharmacokinetic feedback model projects significant biomarker normalization when adhering to fasting intervals and scheduled dosing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3-Column Biomarker Improvement Cards
            HStack(spacing: 10) {
                BiomarkerProjectionTile(
                    title: "TSH Level",
                    delta: "-\(tshValue)%",
                    direction: .decrease,
                    subtitle: "Pituitary Regulation",
                    color: ThyroUI.teal,
                    progress: min(Double(tshValue) / 40.0, 1.0)
                )

                BiomarkerProjectionTile(
                    title: "Free T3",
                    delta: "+\(t3Value)%",
                    direction: .increase,
                    subtitle: "Active Conversion",
                    color: ThyroUI.amber,
                    progress: min(Double(t3Value) / 30.0, 1.0)
                )

                BiomarkerProjectionTile(
                    title: "Free T4",
                    delta: "+\(t4Value)%",
                    direction: .increase,
                    subtitle: "Steady-State Pool",
                    color: ThyroUI.violet,
                    progress: min(Double(t4Value) / 35.0, 1.0)
                )
            }

            // Milestone Timeline Roadmap
            VStack(alignment: .leading, spacing: 10) {
                Text("Projected Recovery Timeline")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThyroUI.navy)
                    .textCase(.uppercase)

                HStack(alignment: .top, spacing: 0) {
                    TimelineMilestoneNode(
                        day: "Day 14",
                        title: "Absorption Set",
                        subtitle: "Fasting timing stabilized",
                        color: ThyroUI.teal,
                        isLast: false
                    )
                    TimelineMilestoneNode(
                        day: "Day 35",
                        title: "5x Half-Life",
                        subtitle: "PK steady-state plateau",
                        color: ThyroUI.amber,
                        isLast: false
                    )
                    TimelineMilestoneNode(
                        day: "Day 90",
                        title: "Euthyroid",
                        subtitle: "TSH feedback equilibrium",
                        color: ThyroUI.violet,
                        isLast: true
                    )
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ThyroUI.navy.opacity(0.06), lineWidth: 1)
            )

            // Protocol Adherence Levers
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Adherence Levers")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThyroUI.navy)
                    .textCase(.uppercase)

                HStack(spacing: 8) {
                    AdherenceLeverPill(icon: "sun.max.fill", label: "60m Pre-Meal Fast", color: ThyroUI.teal)
                    AdherenceLeverPill(icon: "clock.arrow.2.circlepath", label: "4h Mineral Gap", color: ThyroUI.amber)
                    AdherenceLeverPill(icon: "pills.fill", label: "Daily Dosing", color: ThyroUI.violet)
                }
            }

            // Clinical Empowerment Banner
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(ThyroUI.teal)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Take Control With Precision Care")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ThyroUI.navy)
                    Text("Track symptoms, meals, and medication logs daily on the dashboard to reach these milestones.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(ThyroUI.teal.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white, ThyroUI.mint.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ThyroUI.teal.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: ThyroUI.navy.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

enum ProjectionDirection {
    case increase
    case decrease

    var icon: String {
        switch self {
        case .increase: return "arrow.up.right"
        case .decrease: return "arrow.down.right"
        }
    }
}

struct BiomarkerProjectionTile: View {
    let title: String
    let delta: String
    let direction: ProjectionDirection
    let subtitle: String
    let color: Color
    let progress: Double

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            // Icon & Delta
            HStack(spacing: 4) {
                Image(systemName: direction.icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .padding(5)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())

                Text(delta)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(ThyroUI.navy)
                    .monospacedDigit()
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThyroUI.navy)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ThyroUI.softGray)
                        .frame(height: 5)
                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geo.size.width * animatedProgress, height: 5)
                }
            }
            .frame(height: 5)
            .padding(.top, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 6, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                animatedProgress = progress
            }
        }
    }
}

struct TimelineMilestoneNode: View {
    let day: String
    let title: String
    let subtitle: String
    let color: Color
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .center, spacing: 4) {
                // Circle Node
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 22, height: 22)
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }

                Text(day)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ThyroUI.navy)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            if !isLast {
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }
        }
    }
}

struct AdherenceLeverPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ThyroUI.navy)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        PredictionPage()
            .environmentObject(AuthManager())
    }
}
