import SwiftUI
import UIKit

struct PicturePage: View {
    @State private var meals: [MealAnalysis] = MealAnalysis.sampleHistory
    @State private var showingScanner = false

    private var latestMeal: MealAnalysis {
        meals.first ?? MealAnalysis.sampleHistory[0]
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

    @Environment(\.dismiss) private var dismiss
    @State private var scannedMeal: MealAnalysis?
    @State private var isScanning = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 18)

                CameraLensFrame()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)

                if let scannedMeal {
                    ThyroCard {
                        ThyroSectionTitle("Scan result", subtitle: scannedMeal.name)
                        MealNutritionSummary(meal: scannedMeal)
                        MetricRow(title: "TSH", value: scannedMeal.tshImpact, color: ThyroUI.teal)
                        MetricRow(title: "T3", value: scannedMeal.t3Impact, color: ThyroUI.amber)
                        MetricRow(title: "T4", value: scannedMeal.t4Impact, color: ThyroUI.violet)
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    scanMeal()
                } label: {
                    HStack(spacing: 10) {
                        if isScanning {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isScanning ? "Scanning" : "Scan Meal")
                            .font(.system(size: 34, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .background(RoundedRectangle(cornerRadius: 30).fill(ThyroUI.teal))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 54)
                .disabled(isScanning)

                if scannedMeal != nil {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(ThyroUI.teal)
                }

                Spacer(minLength: 22)
            }
        }
        .navigationTitle("Meal Camera")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scanMeal() {
        isScanning = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            let meal = MealAnalysis.scannedSample
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                scannedMeal = meal
                isScanning = false
            }
            onMealScanned(meal)
        }
    }
}

struct CameraLensFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.69, green: 0.84, blue: 0.75))
                .aspectRatio(0.68, contentMode: .fit)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CameraPreview()
                    .clipShape(Rectangle())
                    .padding(1)
                    .allowsHitTesting(false)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 46))
                    Text("Camera preview unavailable in this environment")
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(ThyroUI.navy.opacity(0.75))
                .padding(28)
            }
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

struct MealAnalysis: Identifiable, Equatable {
    let id = UUID()
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
        t4Impact: "+2% support"
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
            t4Impact: "+1% support"
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
            t4Impact: "Neutral"
        )
    ]
}

#Preview {
    NavigationStack {
        PicturePage()
    }
}
