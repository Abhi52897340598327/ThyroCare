import SwiftUI

struct DashboardPage: View {
    var store: CareStore? = nil
    var onNavigateToMessages: (() -> Void)? = nil
    var onNavigateToScanMeal: (() -> Void)? = nil
    let onLogout: () -> Void

    @EnvironmentObject private var authManager: AuthManager

    @State private var floatCards = false
    @State private var showingLabHistory = false
    @AppStorage("severityScore") private var severityScore = 0
    @AppStorage("severityPercentile") private var severityPercentile = 0
    @AppStorage("tshDecrease") private var tshDecrease = 0

    init(
        store: CareStore? = nil,
        onNavigateToMessages: (() -> Void)? = nil,
        onNavigateToScanMeal: (() -> Void)? = nil,
        onLogout: @escaping () -> Void = {}
    ) {
        self.store = store
        self.onNavigateToMessages = onNavigateToMessages
        self.onNavigateToScanMeal = onNavigateToScanMeal
        self.onLogout = onLogout
    }

    private var latestClinicianMessage: PatientRecord? {
        store?.entries("messages").filter { record in
            record.fields["authorRole"] == "clinician" || (record.fields["sender"]?.contains("Dr.") ?? false)
        }.last
    }

    private var projectedThyroidPanel: ProjectedThyroidPanel {
        let meds = store?.entries("medications") ?? []
        let meals = store?.entries("meals") ?? []
        let admins = store?.entries("administrations") ?? []
        return ThyroidBiomarkerPredictor.project(
            medicationRecords: meds,
            mealRecords: meals,
            administrationRecords: admins
        )
    }

    private var todayMealRecords: [PatientRecord] {
        let all = store?.entries("meals") ?? []
        let todayPrefix = Date().ISO8601Format().prefix(10)
        let filtered = all.filter {
            let d = $0.fields["observedDate"] ?? ""
            return d.isEmpty || d == todayPrefix
        }
        return filtered.isEmpty ? all : filtered
    }

    var body: some View {
        ThyroPageScaffold(title: "Dashboard") {
            if let doctorMsg = latestClinicianMessage, let bodyText = doctorMsg.fields["body"], !bodyText.isEmpty {
                ThyroCard {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ThyroUI.teal)
                                .frame(width: 40, height: 40)
                            Image(systemName: "stethoscope")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(doctorMsg.fields["sender"] ?? "Dr. Jane Smith")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                                Spacer()
                                Text("New Response")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(ThyroUI.teal)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ThyroUI.mint)
                                    .clipShape(Capsule())
                            }

                            Text("“\(bodyText)”")
                                .font(.footnote)
                                .foregroundStyle(ThyroUI.ink)
                                .lineLimit(2)

                            if let onNavigateToMessages {
                                Button(action: onNavigateToMessages) {
                                    HStack(spacing: 4) {
                                        Text("Open Care Thread & Reply")
                                            .font(.caption.weight(.semibold))
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(ThyroUI.teal)
                                    .padding(.top, 2)
                                }
                            }
                        }
                    }
                }
            }

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

            // MARK: - Current Projected Thyroid Levels (TSH, T3, T4)
            ThyroCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundStyle(ThyroUI.teal)
                                Text("Projected Thyroid Levels")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                            }
                            Text("Simulated levels taking into account all meds & food taken")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(projectedThyroidPanel.isEuthyroidOptimal ? "Euthyroid Optimal" : "Target Approaching")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ThyroUI.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ThyroUI.mint)
                            .clipShape(Capsule())
                    }

                    // 3 Hormone Tiles (TSH, Free T4, Free T3)
                    HStack(spacing: 8) {
                        BiomarkerTile(
                            hormone: "TSH",
                            value: String(format: "%.2f", projectedThyroidPanel.tsh),
                            unit: "mIU/L",
                            delta: String(format: "%.2f", projectedThyroidPanel.tshDelta),
                            isReduction: projectedThyroidPanel.tshDelta < 0,
                            targetRange: "Target: 0.5–2.5",
                            color: ThyroUI.teal
                        )

                        BiomarkerTile(
                            hormone: "Free T4",
                            value: String(format: "%.2f", projectedThyroidPanel.freeT4),
                            unit: "ng/dL",
                            delta: String(format: "+%.2f", projectedThyroidPanel.t4Delta),
                            isReduction: false,
                            targetRange: "Ref: 0.8–1.8",
                            color: ThyroUI.violet
                        )

                        BiomarkerTile(
                            hormone: "Free T3",
                            value: String(format: "%.2f", projectedThyroidPanel.freeT3),
                            unit: "pg/mL",
                            delta: String(format: "+%.2f", projectedThyroidPanel.t3Delta),
                            isReduction: false,
                            targetRange: "Ref: 2.3–4.2",
                            color: ThyroUI.amber
                        )
                    }

                    Divider()

                    // Accounting Details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(ThyroUI.teal)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Medications Accounted")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                                Text(projectedThyroidPanel.medicationImpactSummary)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "fork.knife")
                                .foregroundStyle(ThyroUI.coral)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Food & Nutrition Accounted")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                                Text(projectedThyroidPanel.nutritionImpactSummary)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(ThyroUI.softGray.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // MARK: - Daily Calorie Tracker
            ThyroCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(ThyroUI.coral)
                                Text("Calorie Tracker")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                            }
                            Text("Daily energy intake fueling thyroid conversion & metabolic rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                            Text("\(Int(projectedThyroidPanel.totalCaloriesToday)) / \(Int(projectedThyroidPanel.targetCalories)) kcal")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(ThyroUI.coral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    // Progress Ring & Summary
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(ThyroUI.softGray, lineWidth: 10)
                                .frame(width: 88, height: 88)
                            Circle()
                                .trim(from: 0, to: min(1.0, projectedThyroidPanel.calorieProgressRatio))
                                .stroke(
                                    LinearGradient(
                                        colors: [ThyroUI.amber, ThyroUI.coral],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 88, height: 88)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("\(Int(projectedThyroidPanel.totalCaloriesToday))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(ThyroUI.navy)
                                Text("kcal")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Remaining Budget")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThyroUI.ink)
                                Spacer()
                                Text("\(Int(projectedThyroidPanel.calorieRemaining)) kcal")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ThyroUI.teal)
                            }

                            ProgressView(value: min(1.0, projectedThyroidPanel.calorieProgressRatio))
                                .tint(ThyroUI.coral)

                            HStack(spacing: 8) {
                                MacroPill(label: "Protein", percent: "\(Int(projectedThyroidPanel.proteinGrams))%", color: ThyroUI.teal)
                                MacroPill(label: "Carbs", percent: "\(Int(projectedThyroidPanel.carbsGrams))%", color: ThyroUI.amber)
                                MacroPill(label: "Plants", percent: "\(Int(projectedThyroidPanel.produceGrams))%", color: ThyroUI.coral)
                            }
                            .padding(.top, 2)
                        }
                    }

                    Divider()

                    // Today Logged Meals
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today’s Tracked Meals")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                            Spacer()
                            if let onNavigateToScanMeal {
                                Button(action: onNavigateToScanMeal) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption2)
                                        Text("Scan Meal Photo")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundStyle(ThyroUI.teal)
                                }
                            }
                        }

                        if !todayMealRecords.isEmpty {
                            ForEach(todayMealRecords.prefix(3)) { meal in
                                HStack {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .foregroundStyle(ThyroUI.teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(meal.fields["description"] ?? meal.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(ThyroUI.navy)
                                            .lineLimit(1)
                                        Text(meal.fields["mealTime"] ?? meal.fields["observedDate"] ?? "Logged Meal")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption2)
                                        Text("\(meal.fields["calories"] ?? "420") kcal")
                                            .font(.caption.weight(.bold))
                                    }
                                    .foregroundStyle(ThyroUI.coral)
                                }
                                .padding(.vertical, 2)
                            }
                        } else {
                            HStack {
                                Text("Overnight Oats & Fresh Berries")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ThyroUI.navy)
                                Spacer()
                                Text("380 kcal")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(ThyroUI.coral)
                            }
                            HStack {
                                Text("Salmon & Quinoa Bowl (Scanned)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ThyroUI.navy)
                                Spacer()
                                Text("520 kcal")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(ThyroUI.coral)
                            }
                        }
                    }

                    if let onNavigateToScanMeal {
                        Button(action: onNavigateToScanMeal) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan Meal Photo & Log Calories")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(ThyroUI.teal))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
            }

            Button {
                showingLabHistory = true
            } label: {
                ThyroCard {
                    HStack(spacing: 16) {
                        Image("DashboardLab")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 92, height: 92)
                            .offset(y: floatCards ? -4 : 4)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ThyroSectionTitle("Lab trend", subtitle: "Recent thyroid values compared across check-ins.")
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("View All")
                                        .font(.caption2.weight(.bold))
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                }
                                .foregroundStyle(ThyroUI.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ThyroUI.mint)
                                .clipShape(Capsule())
                            }

                            AnimatedBarChart(
                                values: [0.86, 0.73, 0.64, 0.56],
                                labels: ["May", "Jun", "Jul", "Now"],
                                color: ThyroUI.teal
                            )
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            ThyroCard {
                HStack(spacing: 18) {
                    Image("DashboardDiet")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(floatCards ? 3 : -3))

                    VStack(alignment: .leading, spacing: 10) {
                        ThyroSectionTitle("Nutrition snapshot")
                        MetricRow(title: "Protein", value: "\(Int(projectedThyroidPanel.proteinGrams))%", color: ThyroUI.teal)
                        MetricRow(title: "Carbs", value: "\(Int(projectedThyroidPanel.carbsGrams))%", color: ThyroUI.amber)
                        MetricRow(title: "Vitamins", value: "18%", color: ThyroUI.violet)
                        MetricRow(title: "Plants", value: "\(Int(projectedThyroidPanel.produceGrams))%", color: ThyroUI.coral)
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
        .sheet(isPresented: $showingLabHistory) {
            LabHistorySheetView(store: store)
        }
    }
}

struct BiomarkerTile: View {
    let hormone: String
    let value: String
    let unit: String
    let delta: String
    let isReduction: Bool
    let targetRange: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hormone)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(ThyroUI.navy)
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 2) {
                Image(systemName: isReduction ? "arrow.down.forward" : "arrow.up.forward")
                    .font(.system(size: 8))
                Text(delta)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(color)

            Text(targetRange)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MacroPill: View {
    let label: String
    let percent: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label) \(percent)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(ThyroUI.ink)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    DashboardPage()
        .environmentObject(AuthManager())
}


// MARK: - Past Lab Results History Sheet

struct LabResultRecord: Identifiable {
    let id = UUID()
    let date: String
    let periodLabel: String
    let testingLab: String
    let labLocation: String
    let orderingPhysician: String
    let tshValue: Double
    let freeT3Value: Double
    let freeT4Value: Double
    let tshStatus: String
    let isOptimal: Bool
}

struct LabHistorySheetView: View {
    var store: CareStore? = nil
    @Environment(\.dismiss) private var dismiss

    private let sampleLabs: [LabResultRecord] = [
        LabResultRecord(
            date: "October 18, 2026",
            periodLabel: "Now",
            testingLab: "Quest Diagnostics",
            labLocation: "Metropolitan Endocrine Center • Suite 400",
            orderingPhysician: "Dr. Jane Smith, MD",
            tshValue: 1.85,
            freeT3Value: 3.40,
            freeT4Value: 1.45,
            tshStatus: "Optimal Range",
            isOptimal: true
        ),
        LabResultRecord(
            date: "July 22, 2026",
            periodLabel: "Jul",
            testingLab: "LabCorp Patient Service Center",
            labLocation: "Regional Medical Center • Outpatient Lab",
            orderingPhysician: "Dr. Jane Smith, MD",
            tshValue: 2.70,
            freeT3Value: 3.10,
            freeT4Value: 1.30,
            tshStatus: "Target Approaching",
            isOptimal: true
        ),
        LabResultRecord(
            date: "June 15, 2026",
            periodLabel: "Jun",
            testingLab: "Quest Diagnostics",
            labLocation: "Northwest Clinical Diagnostic Laboratory",
            orderingPhysician: "Dr. Jane Smith, MD",
            tshValue: 3.85,
            freeT3Value: 2.80,
            freeT4Value: 1.15,
            tshStatus: "Borderline High",
            isOptimal: false
        ),
        LabResultRecord(
            date: "May 12, 2026",
            periodLabel: "May",
            testingLab: "BioReference Laboratories",
            labLocation: "Endocrine Care Special Testing Facility",
            orderingPhysician: "Dr. Jane Smith, MD",
            tshValue: 5.40,
            freeT3Value: 2.30,
            freeT4Value: 0.92,
            tshStatus: "Elevated Baseline",
            isOptimal: false
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.white, ThyroUI.mint.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        // Overall Trend Summary Card
                        ThyroCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Overall Lab Trend")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(ThyroUI.navy)
                                        Text("May 2026 – October 2026 (Now)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("65.7% TSH Reduction")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(ThyroUI.teal)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ThyroUI.mint)
                                        .clipShape(Capsule())
                                }

                                AnimatedBarChart(
                                    values: [0.86, 0.73, 0.64, 0.56],
                                    labels: ["May", "Jun", "Jul", "Now"],
                                    color: ThyroUI.teal
                                )

                                Text("Thyroid values demonstrate a consistent downward TSH trajectory approaching the ideal clinical window (0.5 – 2.5 mIU/L), with concurrent increases in Free T3 and Free T4 conversion.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Section Header
                        HStack {
                            Text("Past Blood Test Reports")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                            Spacer()
                            Text("\(sampleLabs.count) check-ins")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)

                        // Lab Cards List
                        ForEach(sampleLabs) { lab in
                            ThyroCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Header with Date, Period, Status
                                    HStack(alignment: .center) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .font(.caption)
                                                .foregroundStyle(ThyroUI.teal)
                                            Text(lab.date)
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(ThyroUI.navy)
                                        }

                                        Spacer()

                                        HStack(spacing: 6) {
                                            Text(lab.periodLabel)
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(.secondary)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(ThyroUI.softGray)
                                                .clipShape(Capsule())

                                            Text(lab.tshStatus)
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(lab.isOptimal ? ThyroUI.teal : ThyroUI.coral)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(lab.isOptimal ? ThyroUI.mint : ThyroUI.coral.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }

                                    // Testing Laboratory & Ordering Physician
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "flask.fill")
                                            .font(.caption)
                                            .foregroundStyle(ThyroUI.teal)
                                            .frame(width: 24, height: 24)
                                            .background(ThyroUI.mint)
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(lab.testingLab)
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(ThyroUI.ink)
                                                Text("• CLIA Certified")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Text(lab.labLocation)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Text("Ordered by \(lab.orderingPhysician)")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(ThyroUI.teal)
                                        }
                                    }

                                    Divider()

                                    // 3 Lab Values: TSH, Free T3, Free T4
                                    HStack(spacing: 8) {
                                        LabMetricTile(
                                            name: "TSH",
                                            value: String(format: "%.2f", lab.tshValue),
                                            unit: "mIU/L",
                                            reference: "Target: 0.5–2.5",
                                            color: lab.isOptimal ? ThyroUI.teal : ThyroUI.coral
                                        )

                                        LabMetricTile(
                                            name: "Free T3",
                                            value: String(format: "%.2f", lab.freeT3Value),
                                            unit: "pg/mL",
                                            reference: "Ref: 2.3–4.2",
                                            color: ThyroUI.amber
                                        )

                                        LabMetricTile(
                                            name: "Free T4",
                                            value: String(format: "%.2f", lab.freeT4Value),
                                            unit: "ng/dL",
                                            reference: "Ref: 0.8–1.8",
                                            color: ThyroUI.violet
                                        )
                                    }
                                }
                            }
                        }

                        // Clinical Disclaimer
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("All hormone assays verified from performing diagnostic laboratories. Values reflect fasting early morning blood draws. Always discuss dosage modifications with your treating clinician.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 20)

                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Lab History & Bloodwork")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThyroUI.teal)
                }
            }
        }
    }
}

struct LabMetricTile: View {
    let name: String
    let value: String
    let unit: String
    let reference: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(ThyroUI.navy)
                Text(unit)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(reference)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
