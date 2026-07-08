import SwiftUI
import UIKit

struct PicturePage: View {
    @State private var meals: [MealAnalysis] = MealAnalysis.sampleHistory
    @State private var showingScanner = false
    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0
    @AppStorage("tshDecrease") private var storedTSHDecrease = 0
    @AppStorage("t3Improvement") private var storedT3Improvement = 0
    @AppStorage("t4Improvement") private var storedT4Improvement = 0

    private var latestMeal: MealAnalysis {
        meals.first ?? MealAnalysis.sampleHistory[0]
    }

    private var latestPredictionResult: ThyroSeverityResult {
        ThyroSeverityResult(
            score: max(storedSeverityScore, 42),
            percentile: max(storedSeverityPercentile, 55),
            tshDecrease: max(storedTSHDecrease, 12),
            t3Improvement: max(storedT3Improvement, 8),
            t4Improvement: max(storedT4Improvement, 9),
            currentRiskSummary: "Meal analysis has been added to your latest thyroid risk estimate.",
            futureRiskSummary: "This scan suggests your current meal is likely to modestly support thyroid stability."
        )
    }

    var body: some View {
        ThyroPageScaffold(title: "Food Analysis") {
            ThyroCard {
                ThyroSectionTitle("Meal scan", subtitle: "Use the camera to estimate food content and thyroid impact.")

                PlateVectorArt()
                    .frame(maxWidth: .infinity)

                ProgressView(value: latestMeal.confidence)
                    .tint(ThyroUI.teal)

                Text("Latest scan confidence: \(Int(latestMeal.confidence * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThyroUI.navy)
            }

            ThyroCard {
                ThyroSectionTitle("Latest analysis", subtitle: latestMeal.name)
                MealNutritionSummary(meal: latestMeal)
            }

            ThyroCard {
                ThyroSectionTitle("Thyroid impact")
                MetricRow(title: "TSH", value: latestMeal.tshImpact, color: ThyroUI.teal)
                MetricRow(title: "T3", value: latestMeal.t3Impact, color: ThyroUI.amber)
                MetricRow(title: "T4", value: latestMeal.t4Impact, color: ThyroUI.violet)
            }

            LandingButton(title: "Add Meal") {
                showingScanner = true
            }

            ThyroCard {
                ThyroSectionTitle("Meal history", subtitle: "Hardcoded sample log until real food analysis is connected.")

                ForEach(meals) { meal in
                    MealHistoryRow(meal: meal)

                    if meal.id != meals.last?.id {
                        Divider()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingScanner) {
            MealCameraPage { meal in
                meals.insert(meal, at: 0)
            }
        }
    }
}

struct MealCameraPage: View {
    let onMealScanned: (MealAnalysis) -> Void

    @State private var scannedMeal: MealAnalysis?
    @State private var isScanning = false
    @State private var capturedPhoto = false
    @State private var showPrediction = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 18)

                CameraLensFrame(isCaptured: capturedPhoto)
                    .frame(maxWidth: capturedPhoto ? 190 : .infinity)
                    .padding(.horizontal, capturedPhoto ? 0 : 28)
                    .scaleEffect(capturedPhoto ? 0.78 : 1.0)
                    .shadow(color: ThyroUI.navy.opacity(capturedPhoto ? 0.18 : 0), radius: 18, x: 0, y: 10)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: capturedPhoto)

                if capturedPhoto {
                    Text("Meal photo captured")
                        .font(.headline)
                        .foregroundStyle(ThyroUI.navy)
                        .transition(.opacity)
                }

                Button {
                    scanMeal()
                } label: {
                    HStack(spacing: 10) {
                        if isScanning {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isScanning ? "Analyzing" : "Scan Meal")
                            .font(.system(size: 34, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .background(RoundedRectangle(cornerRadius: 30).fill(ThyroUI.teal))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 54)
                .disabled(isScanning || capturedPhoto)
                .opacity(capturedPhoto ? 0.55 : 1)

                Spacer(minLength: 22)
            }

            if isScanning {
                LoadingOverlay()
                    .transition(.opacity)
            }
        }
        .navigationTitle("Meal Camera")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPrediction) {
            MealAnalysisDetailPage(meal: scannedMeal ?? MealAnalysis.scannedSample)
        }
    }

    private func scanMeal() {
        guard !isScanning else { return }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            capturedPhoto = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isScanning = true
            }
        }

        Task {
            let meal: MealAnalysis
            if let imageData = MealImageFactory.placeholderJPEGData(),
               let analyzedMeal = try? await MealAnalysisService.shared.analyze(imageData: imageData) {
                meal = analyzedMeal
            } else {
                meal = MealAnalysis.scannedSample
            }

            try? await Task.sleep(for: .milliseconds(900))

            await MainActor.run {
                scannedMeal = meal
                onMealScanned(meal)

                withAnimation(.easeInOut(duration: 0.2)) {
                    isScanning = false
                    showPrediction = true
                }
            }
        }
    }
}

struct CameraLensFrame: View {
    var isCaptured = false

    private var hasCameraUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
    }

    private var canOpenCameraPreview: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera) && hasCameraUsageDescription
    }

    private var cameraUnavailableMessage: String {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return "Camera preview unavailable in this environment"
        }

        return "Add NSCameraUsageDescription in the target Info settings to enable the iPhone camera"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.69, green: 0.84, blue: 0.75))
                .aspectRatio(0.68, contentMode: .fit)

            if isCaptured {
                StaticMealPhoto()
                    .clipShape(Rectangle())
                    .padding(1)
            } else if canOpenCameraPreview {
                CameraPreview()
                    .clipShape(Rectangle())
                    .padding(1)
                    .allowsHitTesting(false)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 46))
                    Text(cameraUnavailableMessage)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(ThyroUI.navy.opacity(0.75))
                .padding(28)
            }
        }
    }
}

struct StaticMealPhoto: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.87, green: 0.96, blue: 0.91), Color(red: 0.70, green: 0.86, blue: 0.77)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PlateVectorArt()
                .scaleEffect(0.82)
                .opacity(0.92)

            VStack {
                Spacer()
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Captured")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(ThyroUI.teal.opacity(0.92)))
                .padding(.bottom, 14)
            }
        }
        .aspectRatio(0.68, contentMode: .fit)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(ThyroUI.teal)

                Text("Analyzing meal")
                    .font(.headline)
                    .foregroundStyle(ThyroUI.navy)

                Text("Estimating nutrition and thyroid impact")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 280)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: ThyroUI.navy.opacity(0.18), radius: 18, x: 0, y: 10)
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = false
        picker.cameraViewTransform = CGAffineTransform(scaleX: 1.35, y: 1.35)
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct MealNutritionSummary: View {
    let meal: MealAnalysis

    var body: some View {
        HStack(spacing: 18) {
            DonutSegmentChart(
                values: [Double(meal.protein), Double(meal.carbs), Double(meal.vitamins), Double(meal.produce)],
                colors: [ThyroUI.teal, ThyroUI.amber, ThyroUI.violet, ThyroUI.coral]
            )
            .frame(width: 92, height: 92)

            VStack(spacing: 8) {
                MetricRow(title: "Protein", value: "\(meal.protein)%", color: ThyroUI.teal)
                MetricRow(title: "Carbs", value: "\(meal.carbs)%", color: ThyroUI.amber)
                MetricRow(title: "Vitamins", value: "\(meal.vitamins)%", color: ThyroUI.violet)
                MetricRow(title: "Produce", value: "\(meal.produce)%", color: ThyroUI.coral)
            }
        }
    }
}

struct MealHistoryRow: View {
    let meal: MealAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundStyle(ThyroUI.navy)
                    Text(meal.timeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(meal.confidence * 100))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThyroUI.teal)
            }

            HStack(spacing: 10) {
                Text("P \(meal.protein)%")
                Text("C \(meal.carbs)%")
                Text("V \(meal.vitamins)%")
                Text("F/V \(meal.produce)%")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct MealAnalysisDetailPage: View {
    let meal: MealAnalysis

    var body: some View {
        ThyroPageScaffold(title: "Meal Results") {
            ThyroCard {
                ThyroSectionTitle("Food contents", subtitle: meal.name)
                MealNutritionSummary(meal: meal)

                Divider()

                ExactFoodContentRow(title: "Protein", percent: meal.protein, color: ThyroUI.teal)
                ExactFoodContentRow(title: "Carbs", percent: meal.carbs, color: ThyroUI.amber)
                ExactFoodContentRow(title: "Vitamins", percent: meal.vitamins, color: ThyroUI.violet)
                ExactFoodContentRow(title: "Fruits / Vegetables", percent: meal.produce, color: ThyroUI.coral)
                ExactFoodContentRow(title: "Total", percent: meal.totalFoodPercent, color: ThyroUI.navy)
            }

            ThyroCard {
                ThyroSectionTitle("Predicted thyroid impact", subtitle: "Hardcoded meal-analysis values until the real model is connected.")

                VStack(spacing: 18) {
                    HStack(alignment: .top, spacing: 18) {
                        HormoneImpactTile(
                            hormone: "TSH",
                            percentChange: meal.tshPercentChange,
                            color: ThyroUI.teal
                        )

                        HormoneImpactTile(
                            hormone: "T3",
                            percentChange: meal.t3PercentChange,
                            color: ThyroUI.amber
                        )
                    }

                    HormoneImpactTile(
                        hormone: "T4",
                        percentChange: meal.t4PercentChange,
                        color: ThyroUI.violet
                    )
                    .frame(maxWidth: 150)
                }
                .padding(.top, 14)
                .frame(maxWidth: .infinity)
            }

            ThyroCard {
                ThyroSectionTitle("Interpretation")
                Text("This meal has a higher protein balance with moderate carbohydrates and produce. Based on the placeholder scoring rules, it is expected to reduce TSH by \(formattedPercent(abs(meal.tshPercentChange))) and support T3/T4 availability by \(formattedPercent(meal.t3PercentChange)) and \(formattedPercent(meal.t4PercentChange)).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}

struct ExactFoodContentRow: View {
    let title: String
    let percent: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThyroUI.ink)
                Spacer()
                Text("\(percent)%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThyroUI.navy)
            }

            ProgressView(value: Double(percent), total: 100)
                .tint(color)
        }
    }
}

struct HormoneImpactTile: View {
    let hormone: String
    let percentChange: Double
    let color: Color

    var body: some View {
        AnimatedMetricRing(title: hormone, value: min(abs(percentChange) / 10.0, 1), color: color)
            .frame(width: 96, height: 96)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
    }
}

struct MealAnalysis: Identifiable, Equatable, Codable {
    var id = UUID()
    let name: String
    let timeLabel: String
    let confidence: Double
    let protein: Int
    let carbs: Int
    let vitamins: Int
    let produce: Int
    let tshImpact: String
    let t3Impact: String
    let t4Impact: String
    let tshPercentChange: Double
    let t3PercentChange: Double
    let t4PercentChange: Double

    var totalFoodPercent: Int {
        protein + carbs + vitamins + produce
    }

    static let scannedSample = MealAnalysis(
        name: "Grilled chicken bowl",
        timeLabel: "Just now",
        confidence: 0.93,
        protein: 32,
        carbs: 34,
        vitamins: 14,
        produce: 20,
        tshImpact: "Likely stable",
        t3Impact: "+3% support",
        t4Impact: "+2% support",
        tshPercentChange: -1.8,
        t3PercentChange: 3.2,
        t4PercentChange: 2.4
    )

    static let sampleHistory = [
        MealAnalysis(
            name: "Egg toast and berries",
            timeLabel: "Today, 8:20 AM",
            confidence: 0.86,
            protein: 24,
            carbs: 42,
            vitamins: 12,
            produce: 22,
            tshImpact: "Slight support",
            t3Impact: "+2% support",
            t4Impact: "+1% support",
            tshPercentChange: -0.9,
            t3PercentChange: 2.1,
            t4PercentChange: 1.3
        ),
        MealAnalysis(
            name: "Rice bowl",
            timeLabel: "Yesterday, 1:05 PM",
            confidence: 0.81,
            protein: 18,
            carbs: 54,
            vitamins: 8,
            produce: 20,
            tshImpact: "May increase",
            t3Impact: "Neutral",
            t4Impact: "Neutral",
            tshPercentChange: 2.6,
            t3PercentChange: -0.4,
            t4PercentChange: -0.2
        )
    ]
}

#Preview {
    NavigationStack {
        PicturePage()
    }
}
