import SwiftUI
import UIKit
import AVFoundation
import Combine

struct PicturePage: View {
    @State private var meals: [MealAnalysis] = []
    @State private var showingScanner = false
    @AppStorage("mealHistoryData") private var mealHistoryData = Data()
    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0
    @AppStorage("tshDecrease") private var storedTSHDecrease = 0
    @AppStorage("t3Improvement") private var storedT3Improvement = 0
    @AppStorage("t4Improvement") private var storedT4Improvement = 0

    private var latestMeal: MealAnalysis? {
        meals.first
    }

    var body: some View {
        ThyroPageScaffold(title: "Food Analysis") {
            ThyroCard {
                ThyroSectionTitle("Meal scan", subtitle: "Use the camera to estimate food content and thyroid impact.")

                PlateVectorArt()
                    .frame(maxWidth: .infinity)

                if let latestMeal {
                    ProgressView(value: latestMeal.confidence)
                        .tint(ThyroUI.teal)

                    Text("Latest scan confidence: \(Int(latestMeal.confidence * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThyroUI.navy)
                } else {
                    Text("No meals scanned yet.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let latestMeal {
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
            }

            LandingButton(title: "Add Meal") {
                showingScanner = true
            }

            ThyroCard {
                ThyroSectionTitle("Meal history", subtitle: "Saved scans from this device.")

                if meals.isEmpty {
                    Text("Your scanned meals will appear here after the first analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(meals) { meal in
                        MealHistoryRow(meal: meal)

                        if meal.id != meals.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadPersistedMeals)
        .navigationDestination(isPresented: $showingScanner) {
            MealCameraPage { meal in
                meals.insert(meal.copyWithNewID, at: 0)
                saveMeals()
            }
        }
    }

    private func loadPersistedMeals() {
        guard !mealHistoryData.isEmpty,
              let decodedMeals = try? JSONDecoder().decode([MealAnalysis].self, from: mealHistoryData) else {
            meals = []
            return
        }

        meals = decodedMeals
    }

    private func saveMeals() {
        guard let encodedMeals = try? JSONEncoder().encode(meals) else { return }
        mealHistoryData = encodedMeals
    }
}

struct MealCameraPage: View {
    let onMealScanned: (MealAnalysis) -> Void

    @StateObject private var camera = MealCameraController()
    @State private var scannedMeal: MealAnalysis?
    @State private var scanErrorMessage: String?
    @State private var capturedImage: UIImage?
    @State private var isScanning = false
    @State private var capturedPhoto = false
    @State private var showPrediction = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 18)

                CameraLensFrame(camera: camera, capturedImage: capturedImage, isCaptured: capturedPhoto)
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

                if let scanErrorMessage {
                    Text(scanErrorMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThyroUI.coral)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                ThyroMedicalDisclaimer()
                    .padding(.horizontal, 28)

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
                .disabled(isScanning)

                Spacer(minLength: 22)
            }

            if isScanning {
                LoadingOverlay()
                    .transition(.opacity)
            }
        }
        .task {
            await camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .navigationTitle("Meal Camera")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPrediction) {
            MealAnalysisDetailPage(meal: scannedMeal ?? MealAnalysis.scannedSample)
        }
    }

    private func scanMeal() {
        guard !isScanning else { return }

        Task {
            do {
                await MainActor.run {
                    scanErrorMessage = nil
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isScanning = true
                    }
                }

                let imageData = try await camera.capturePhoto()
                let capturedUIImage = UIImage(data: imageData)

                await MainActor.run {
                    capturedImage = capturedUIImage
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        capturedPhoto = true
                    }
                }

                let meal = try await MealAnalysisService.shared.analyze(imageData: imageData)

                try? await Task.sleep(for: .milliseconds(900))

                await MainActor.run {
                    scannedMeal = meal
                    onMealScanned(meal)

                    withAnimation(.easeInOut(duration: 0.2)) {
                        isScanning = false
                        camera.stop()
                        showPrediction = true
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isScanning = false
                        capturedPhoto = false
                        capturedImage = nil
                        scanErrorMessage = MealAnalysisService.userFacingMessage(for: error)
                    }
                }
            }
        }
    }
}

struct CameraLensFrame: View {
    @ObservedObject var camera: MealCameraController
    let capturedImage: UIImage?
    var isCaptured = false

    private var hasCameraUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
    }

    private var cameraUnavailableMessage: String {
        if !camera.isCameraAvailable {
            return "Camera preview unavailable in this environment"
        }

        if !hasCameraUsageDescription {
            return "Add NSCameraUsageDescription in the target Info settings to enable the iPhone camera"
        }

        return camera.errorMessage ?? "Camera access is unavailable"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.69, green: 0.84, blue: 0.75))
                .aspectRatio(0.68, contentMode: .fit)

            if isCaptured {
                StaticMealPhoto(image: capturedImage)
                    .clipShape(Rectangle())
                    .padding(1)
            } else if camera.isReady {
                CameraPreview(camera: camera)
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
    let image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.87, green: 0.96, blue: 0.91), Color(red: 0.70, green: 0.86, blue: 0.77)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

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

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: MealCameraController

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.previewLayer.session = camera.session
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

final class MealCameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published private(set) var isReady = false
    @Published private(set) var errorMessage: String?

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "thyrocare.camera.session")
    nonisolated(unsafe) private var photoContinuation: CheckedContinuation<Data, Error>?
    private var isConfigured = false

    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    @MainActor
    func start() async {
        guard isCameraAvailable else {
            errorMessage = "Camera preview unavailable in this environment"
            isReady = false
            return
        }

        let accessGranted = await requestCameraAccess()
        guard accessGranted else {
            errorMessage = "Camera access is required to scan meals"
            isReady = false
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            do {
                try self.configureIfNeeded()
                if !self.session.isRunning {
                    self.session.startRunning()
                }

                DispatchQueue.main.async {
                    self.errorMessage = nil
                    self.isReady = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isReady = false
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else { return }
                guard self.isConfigured else {
                    continuation.resume(throwing: MealAnalysisServiceError.invalidImageData)
                    return
                }

                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                self.output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            photoContinuation?.resume(throwing: MealAnalysisServiceError.invalidImageData)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: data)
        photoContinuation = nil
    }

    private func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            throw MealAnalysisServiceError.invalidImageData
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input), session.canAddOutput(output) else {
            session.commitConfiguration()
            throw MealAnalysisServiceError.invalidImageData
        }

        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        isConfigured = true
    }
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
            ThyroMedicalDisclaimer()

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
                ThyroSectionTitle("Predicted thyroid impact", subtitle: "Calculated on-device from the analyzed food profile.")

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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timeLabel
        case confidence
        case protein
        case carbs
        case vitamins
        case produce
        case tshImpact
        case t3Impact
        case t4Impact
        case tshPercentChange
        case t3PercentChange
        case t4PercentChange
    }

    init(
        id: UUID = UUID(),
        name: String,
        timeLabel: String,
        confidence: Double,
        protein: Int,
        carbs: Int,
        vitamins: Int,
        produce: Int,
        tshImpact: String,
        t3Impact: String,
        t4Impact: String,
        tshPercentChange: Double,
        t3PercentChange: Double,
        t4PercentChange: Double
    ) {
        self.id = id
        self.name = name
        self.timeLabel = timeLabel
        self.confidence = confidence
        self.protein = protein
        self.carbs = carbs
        self.vitamins = vitamins
        self.produce = produce
        self.tshImpact = tshImpact
        self.t3Impact = t3Impact
        self.t4Impact = t4Impact
        self.tshPercentChange = tshPercentChange
        self.t3PercentChange = t3PercentChange
        self.t4PercentChange = t4PercentChange
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        timeLabel = try container.decode(String.self, forKey: .timeLabel)
        confidence = try container.decode(Double.self, forKey: .confidence)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        vitamins = try container.decode(Int.self, forKey: .vitamins)
        produce = try container.decode(Int.self, forKey: .produce)
        tshImpact = try container.decode(String.self, forKey: .tshImpact)
        t3Impact = try container.decode(String.self, forKey: .t3Impact)
        t4Impact = try container.decode(String.self, forKey: .t4Impact)
        tshPercentChange = try container.decode(Double.self, forKey: .tshPercentChange)
        t3PercentChange = try container.decode(Double.self, forKey: .t3PercentChange)
        t4PercentChange = try container.decode(Double.self, forKey: .t4PercentChange)
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

    var copyWithNewID: MealAnalysis {
        MealAnalysis(
            name: name,
            timeLabel: timeLabel,
            confidence: confidence,
            protein: protein,
            carbs: carbs,
            vitamins: vitamins,
            produce: produce,
            tshImpact: tshImpact,
            t3Impact: t3Impact,
            t4Impact: t4Impact,
            tshPercentChange: tshPercentChange,
            t3PercentChange: t3PercentChange,
            t4PercentChange: t4PercentChange
        )
    }

}

#Preview {
    NavigationStack {
        PicturePage()
    }
}
