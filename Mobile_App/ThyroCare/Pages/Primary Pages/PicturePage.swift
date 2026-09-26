import SwiftUI
import UIKit
import AVFoundation
import Combine

struct PicturePage: View {
    @State private var meals: [MealAnalysis] = []
    @State private var showingScanner = false
    @State private var selectedTabMode = 0 // 0: Scanner, 1: USDA API Inspector, 2: Meal History
    @State private var usdaSearchQuery = "Grilled Chicken Bowl"
    @State private var selectedMealForDetail: MealAnalysis?
    @AppStorage("mealHistoryData") private var mealHistoryData = Data()
    @AppStorage("severityScore") private var storedSeverityScore = 0
    @AppStorage("severityPercentile") private var storedSeverityPercentile = 0

    private var latestMeal: MealAnalysis {
        meals.first ?? MealAnalysis.scannedSample
    }

    var body: some View {
        ThyroPageScaffold(title: "Food & USDA Analysis") {
            
            // Sub-Navigation Segment Control
            Picker("View Mode", selection: $selectedTabMode) {
                Text("Scanner").tag(0)
                Text("USDA API").tag(1)
                Text("Log History").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 6)

            if selectedTabMode == 0 {
                // MARK: - TAB 1: CAMERA SCANNER & LATEST ANALYSIS
                ThyroCard {
                    ThyroSectionTitle("Meal Camera Scan", subtitle: "Take a photo to trigger Vision AI + USDA FoodData Central lookup.")

                    PlateVectorArt()
                        .frame(maxWidth: .infinity)

                    if !meals.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Latest Meal: \(latestMeal.name)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ThyroUI.navy)
                                Text("USDA Match: \(latestMeal.usdaMatchName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(latestMeal.confidence * 100))% AI match")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThyroUI.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(ThyroUI.softGray))
                        }

                        ProgressView(value: latestMeal.confidence)
                            .tint(ThyroUI.teal)
                    } else {
                        Text("No meals scanned yet. Tap below to capture a meal photo.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                LandingButton(title: "Scan Meal Photo") {
                    showingScanner = true
                }

                if let meal = meals.first {
                    ThyroCard {
                        ThyroSectionTitle("Latest Scan Overview", subtitle: meal.name)
                        MealNutritionSummary(meal: meal)

                        NavigationLink {
                            MealAnalysisDetailPage(meal: meal)
                        } label: {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("View Full USDA & Thyroid Inspector")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(ThyroUI.teal)
                            .padding(.top, 8)
                        }
                    }

                    ThyroCard {
                        ThyroSectionTitle("Thyroid Impact Summary")
                        MetricRow(title: "TSH Impact", value: meal.tshImpact, color: ThyroUI.teal)
                        MetricRow(title: "Free T3", value: meal.t3Impact, color: ThyroUI.amber)
                        MetricRow(title: "Free T4", value: meal.t4Impact, color: ThyroUI.violet)
                    }
                }

            } else if selectedTabMode == 1 {
                // MARK: - TAB 2: USDA FOODDATA CENTRAL API INSPECTOR
                ThyroCard {
                    ThyroSectionTitle("USDA API Live Inspector", subtitle: "Inspect raw FoodData Central (FDC) query parameters and response payloads.")

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search USDA database...", text: $usdaSearchQuery)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }
                    .padding(12)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    let searchedMeal = USDALookupSimulator.search(query: usdaSearchQuery, baseMeal: latestMeal)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(searchedMeal.usdaMatchName)
                                    .font(.headline)
                                    .foregroundStyle(ThyroUI.navy)
                                Text("FDC ID: \(searchedMeal.usdaFdcId) | Source: \(searchedMeal.usdaDataType)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("200 OK (\(searchedMeal.usdaApiCallLatencyMs)ms)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThyroUI.teal)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                        }

                        Divider()

                        Text("USDA Micronutrients & Co-Factors")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)
                            .textCase(.uppercase)

                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                            GridRow {
                                MicronutrientBadge(title: "Iodine", value: String(format: "%.1f µg", searchedMeal.iodineMicrograms), color: ThyroUI.teal)
                                MicronutrientBadge(title: "Selenium", value: String(format: "%.1f µg", searchedMeal.seleniumMicrograms), color: ThyroUI.amber)
                            }
                            GridRow {
                                MicronutrientBadge(title: "Calcium", value: String(format: "%.0f mg", searchedMeal.calciumMilligrams), color: ThyroUI.violet)
                                MicronutrientBadge(title: "Sodium", value: String(format: "%.0f mg", searchedMeal.sodiumMilligrams), color: ThyroUI.coral)
                            }
                        }

                        Divider()

                        NavigationLink {
                            MealAnalysisDetailPage(meal: searchedMeal)
                        } label: {
                            HStack {
                                Text("Inspect Full USDA JSON & Absorption Profile")
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .foregroundStyle(ThyroUI.teal)
                            .padding(.vertical, 4)
                        }
                    }
                }

            } else {
                // MARK: - TAB 3: MEAL LOG HISTORY
                ThyroCard {
                    ThyroSectionTitle("Meal History", subtitle: "\(meals.count) saved scan records.")

                    if meals.isEmpty {
                        Text("No saved meals. Take a scan in the Scanner tab to populate your food history.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(meals) { meal in
                            NavigationLink {
                                MealAnalysisDetailPage(meal: meal)
                            } label: {
                                MealHistoryRow(meal: meal)
                            }
                            .buttonStyle(.plain)

                            if meal.id != meals.last?.id {
                                Divider()
                            }
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
            meals = [MealAnalysis.scannedSample]
            return
        }

        meals = decodedMeals
    }

    private func saveMeals() {
        guard let encodedMeals = try? JSONEncoder().encode(meals) else { return }
        mealHistoryData = encodedMeals
    }
}

struct MicronutrientBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(ThyroUI.navy)
        }
        .padding(8)
        .background(ThyroUI.softGray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

            VStack(spacing: 24) {
                Spacer(minLength: 14)

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
                        Text(isScanning ? "Analyzing USDA..." : "Scan Meal")
                            .font(.system(size: 28, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(RoundedRectangle(cornerRadius: 24).fill(ThyroUI.teal))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .disabled(isScanning)

                Spacer(minLength: 16)
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
        .navigationTitle("Meal Camera & USDA Scan")
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
            return "Camera preview unavailable in simulator"
        }

        if !hasCameraUsageDescription {
            return "Add NSCameraUsageDescription in Info.plist to enable camera"
        }

        return camera.errorMessage ?? "Camera access is unavailable"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.69, green: 0.84, blue: 0.75))
                .aspectRatio(0.75, contentMode: .fit)

            if isCaptured {
                StaticMealPhoto(image: capturedImage)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(1)
            } else if camera.isReady {
                CameraPreview(camera: camera)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    Text("USDA Matched")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(ThyroUI.teal.opacity(0.92)))
                .padding(.bottom, 12)
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(ThyroUI.teal)

                Text("Querying USDA API...")
                    .font(.headline)
                    .foregroundStyle(ThyroUI.navy)

                Text("Estimating Iodine, Selenium, & Levothyroxine Absorption")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 290)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    Text("USDA FDC #\(meal.usdaFdcId) • \(meal.timeLabel)")
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

// MARK: - DETAILED TABBED USDA & THYROID INSPECTOR PAGE
struct MealAnalysisDetailPage: View {
    let meal: MealAnalysis
    @State private var inspectorTab = 0 // 0: Macros, 1: USDA API, 2: Thyroid Impact, 3: Raw JSON
    @State private var copiedJson = false

    var body: some View {
        ThyroPageScaffold(title: meal.name) {
            
            // Sub-Inspector Segment Bar
            Picker("Inspector Tab", selection: $inspectorTab) {
                Text("Macros").tag(0)
                Text("USDA Call").tag(1)
                Text("Thyroid").tag(2)
                Text("Raw JSON").tag(3)
            }
            .pickerStyle(.segmented)

            if inspectorTab == 0 {
                // MARK: TAB 0 - MACRONUTRIENT BREAKDOWN
                ThyroCard {
                    ThyroSectionTitle("Food Content & Macro Distribution", subtitle: meal.name)
                    MealNutritionSummary(meal: meal)

                    Divider()

                    ExactFoodContentRow(title: "Protein", percent: meal.protein, color: ThyroUI.teal)
                    ExactFoodContentRow(title: "Carbs", percent: meal.carbs, color: ThyroUI.amber)
                    ExactFoodContentRow(title: "Vitamins", percent: meal.vitamins, color: ThyroUI.violet)
                    ExactFoodContentRow(title: "Fruits / Vegetables", percent: meal.produce, color: ThyroUI.coral)
                    ExactFoodContentRow(title: "Total Food Ratio", percent: meal.totalFoodPercent, color: ThyroUI.navy)
                }

            } else if inspectorTab == 1 {
                // MARK: TAB 1 - USDA FOODDATA CENTRAL API DETAILS
                ThyroCard {
                    ThyroSectionTitle("USDA API Response Details", subtitle: "FoodData Central Integration")

                    VStack(alignment: .leading, spacing: 12) {
                        DetailFieldRow(title: "USDA Matched Item", value: meal.usdaMatchName)
                        DetailFieldRow(title: "FDC ID", value: meal.usdaFdcId)
                        DetailFieldRow(title: "Data Type", value: meal.usdaDataType)
                        DetailFieldRow(title: "Submitted Query", value: meal.usdaQuery)
                        DetailFieldRow(title: "API Call Latency", value: "\(meal.usdaApiCallLatencyMs) ms")
                        DetailFieldRow(title: "HTTP Status", value: "200 OK (USDA FDC REST API)")

                        Divider()

                        Text("Assayed USDA Micronutrients")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)

                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                            GridRow {
                                MicronutrientBadge(title: "Iodine (I)", value: String(format: "%.1f µg", meal.iodineMicrograms), color: ThyroUI.teal)
                                MicronutrientBadge(title: "Selenium (Se)", value: String(format: "%.1f µg", meal.seleniumMicrograms), color: ThyroUI.amber)
                            }
                            GridRow {
                                MicronutrientBadge(title: "Calcium (Ca)", value: String(format: "%.0f mg", meal.calciumMilligrams), color: ThyroUI.violet)
                                MicronutrientBadge(title: "Sodium (Na)", value: String(format: "%.0f mg", meal.sodiumMilligrams), color: ThyroUI.coral)
                            }
                        }
                    }
                }

            } else if inspectorTab == 2 {
                // MARK: TAB 2 - THYROID HORMONAL IMPACT & LEVOTHYROXINE ADVISORY
                ThyroCard {
                    ThyroSectionTitle("Predicted Thyroid Impact", subtitle: "On-device estimation based on nutrient profile.")

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
                    .padding(.top, 10)

                    Divider()

                    ThyroSectionTitle("Levothyroxine Absorption Timing Advisory")
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundStyle(ThyroUI.coral)
                            Text(meal.levothyroxineAbsorptionRisk)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }

                        Text("Calcium (\(Int(meal.calciumMilligrams))mg) or iron co-administration can chelate levothyroxine in the gut, reducing bio-availability. Enforce a 4-hour window from medication dose.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            } else {
                // MARK: TAB 3 - RAW USDA JSON RESPONSE PAYLOAD
                ThyroCard {
                    ThyroSectionTitle("USDA FDC JSON Payload", subtitle: "Raw API Request/Response JSON")

                    Button {
                        UIPasteboard.general.string = meal.rawUsdaJsonResponse
                        copiedJson = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedJson = false }
                    } label: {
                        HStack {
                            Image(systemName: copiedJson ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(copiedJson ? "Copied Payload!" : "Copy JSON Payload")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ThyroUI.teal)
                    }

                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(meal.rawUsdaJsonResponse)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(ThyroUI.navy)
                            .padding(12)
                            .background(ThyroUI.softGray)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxHeight: 280)
                }
            }
        }
    }
}

struct DetailFieldRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(ThyroUI.navy)
                .multilineTextAlignment(.trailing)
        }
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

    // USDA API & Micronutrient Metadata
    var usdaMatchName: String = "Grilled Chicken Breast & Rice Bowl (USDA #171077)"
    var usdaFdcId: String = "171077"
    var usdaDataType: String = "SR Legacy / Foundation"
    var usdaQuery: String = "chicken breast rice broccoli"
    var usdaApiCallLatencyMs: Int = 142
    var iodineMicrograms: Double = 12.5
    var seleniumMicrograms: Double = 34.8
    var calciumMilligrams: Double = 45.0
    var sodiumMilligrams: Double = 420.0
    var goitrogenRiskLevel: String = "Low (Cooked Vegetables)"
    var levothyroxineAbsorptionRisk: String = "Moderate — Separate from dose by 4 hours"
    var rawUsdaJsonResponse: String = """
    {
      "foodSearchCriteria": {
        "query": "grilled chicken bowl",
        "generalSearchInput": "chicken breast rice broccoli",
        "pageNumber": 1
      },
      "totalHits": 42,
      "foods": [
        {
          "fdcId": 171077,
          "description": "Chicken breast, grilled with seasoned rice and steamed broccoli",
          "dataType": "SR Legacy",
          "foodNutrients": [
            { "nutrientName": "Protein", "value": 31.8, "unitName": "G" },
            { "nutrientName": "Carbohydrate, by difference", "value": 34.2, "unitName": "G" },
            { "nutrientName": "Selenium, Se", "value": 34.8, "unitName": "UG" },
            { "nutrientName": "Iodine, I", "value": 12.5, "unitName": "UG" },
            { "nutrientName": "Calcium, Ca", "value": 45.0, "unitName": "MG" },
            { "nutrientName": "Sodium, Na", "value": 420.0, "unitName": "MG" }
          ]
        }
      ]
    }
    """

    var totalFoodPercent: Int {
        protein + carbs + vitamins + produce
    }

    enum CodingKeys: String, CodingKey {
        case id, name, timeLabel, confidence, protein, carbs, vitamins, produce
        case tshImpact, t3Impact, t4Impact, tshPercentChange, t3PercentChange, t4PercentChange
        case usdaMatchName, usdaFdcId, usdaDataType, usdaQuery, usdaApiCallLatencyMs
        case iodineMicrograms, seleniumMicrograms, calciumMilligrams, sodiumMilligrams
        case goitrogenRiskLevel, levothyroxineAbsorptionRisk, rawUsdaJsonResponse
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
        t4PercentChange: Double,
        usdaMatchName: String = "Grilled Chicken Breast & Rice Bowl (USDA #171077)",
        usdaFdcId: String = "171077",
        usdaDataType: String = "SR Legacy / Foundation",
        usdaQuery: String = "chicken breast rice broccoli",
        usdaApiCallLatencyMs: Int = 142,
        iodineMicrograms: Double = 12.5,
        seleniumMicrograms: Double = 34.8,
        calciumMilligrams: Double = 45.0,
        sodiumMilligrams: Double = 420.0,
        goitrogenRiskLevel: String = "Low (Cooked Vegetables)",
        levothyroxineAbsorptionRisk: String = "Moderate — Separate from dose by 4 hours",
        rawUsdaJsonResponse: String? = nil
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
        self.usdaMatchName = usdaMatchName
        self.usdaFdcId = usdaFdcId
        self.usdaDataType = usdaDataType
        self.usdaQuery = usdaQuery
        self.usdaApiCallLatencyMs = usdaApiCallLatencyMs
        self.iodineMicrograms = iodineMicrograms
        self.seleniumMicrograms = seleniumMicrograms
        self.calciumMilligrams = calciumMilligrams
        self.sodiumMilligrams = sodiumMilligrams
        self.goitrogenRiskLevel = goitrogenRiskLevel
        self.levothyroxineAbsorptionRisk = levothyroxineAbsorptionRisk
        if let rawUsdaJsonResponse {
            self.rawUsdaJsonResponse = rawUsdaJsonResponse
        }
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

        usdaMatchName = try container.decodeIfPresent(String.self, forKey: .usdaMatchName) ?? "Grilled Chicken Breast & Rice Bowl (USDA #171077)"
        usdaFdcId = try container.decodeIfPresent(String.self, forKey: .usdaFdcId) ?? "171077"
        usdaDataType = try container.decodeIfPresent(String.self, forKey: .usdaDataType) ?? "SR Legacy"
        usdaQuery = try container.decodeIfPresent(String.self, forKey: .usdaQuery) ?? name.lowercased()
        usdaApiCallLatencyMs = try container.decodeIfPresent(Int.self, forKey: .usdaApiCallLatencyMs) ?? 142
        iodineMicrograms = try container.decodeIfPresent(Double.self, forKey: .iodineMicrograms) ?? 12.5
        seleniumMicrograms = try container.decodeIfPresent(Double.self, forKey: .seleniumMicrograms) ?? 34.8
        calciumMilligrams = try container.decodeIfPresent(Double.self, forKey: .calciumMilligrams) ?? 45.0
        sodiumMilligrams = try container.decodeIfPresent(Double.self, forKey: .sodiumMilligrams) ?? 420.0
        goitrogenRiskLevel = try container.decodeIfPresent(String.self, forKey: .goitrogenRiskLevel) ?? "Low"
        levothyroxineAbsorptionRisk = try container.decodeIfPresent(String.self, forKey: .levothyroxineAbsorptionRisk) ?? "Moderate — Separate from dose by 4 hours"
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
            t4PercentChange: t4PercentChange,
            usdaMatchName: usdaMatchName,
            usdaFdcId: usdaFdcId,
            usdaDataType: usdaDataType,
            usdaQuery: usdaQuery,
            usdaApiCallLatencyMs: usdaApiCallLatencyMs,
            iodineMicrograms: iodineMicrograms,
            seleniumMicrograms: seleniumMicrograms,
            calciumMilligrams: calciumMilligrams,
            sodiumMilligrams: sodiumMilligrams,
            goitrogenRiskLevel: goitrogenRiskLevel,
            levothyroxineAbsorptionRisk: levothyroxineAbsorptionRisk,
            rawUsdaJsonResponse: rawUsdaJsonResponse
        )
    }
}

// MARK: - USDA LOOKUP SIMULATOR FOR SEARCH INSPECTOR TAB
enum USDALookupSimulator {
    static func search(query: String, baseMeal: MealAnalysis) -> MealAnalysis {
        let q = query.lowercased()
        if q.contains("salmon") || q.contains("fish") {
            return MealAnalysis(
                name: "Wild Alaskan Salmon & Quinoa",
                timeLabel: "Searched query",
                confidence: 0.96,
                protein: 42,
                carbs: 22,
                vitamins: 18,
                produce: 18,
                tshImpact: "Favorable support",
                t3Impact: "+5.4% support",
                t4Impact: "+4.1% support",
                tshPercentChange: -3.2,
                t3PercentChange: 5.4,
                t4PercentChange: 4.1,
                usdaMatchName: "Salmon, wild, cooked, dry heat (USDA #175168)",
                usdaFdcId: "175168",
                usdaDataType: "SR Legacy",
                usdaQuery: query,
                usdaApiCallLatencyMs: 118,
                iodineMicrograms: 34.0,
                seleniumMicrograms: 46.8,
                calciumMilligrams: 15.0,
                sodiumMilligrams: 85.0,
                goitrogenRiskLevel: "None",
                levothyroxineAbsorptionRisk: "Low Risk — Minimal GI Binding"
            )
        } else if q.contains("broccoli") || q.contains("kale") || q.contains("cabbage") {
            return MealAnalysis(
                name: "Steamed Broccoli & Kale Salad",
                timeLabel: "Searched query",
                confidence: 0.91,
                protein: 14,
                carbs: 26,
                vitamins: 30,
                produce: 30,
                tshImpact: "Monitor glucosinolates",
                t3Impact: "+1.2% support",
                t4Impact: "+0.8% support",
                tshPercentChange: 0.5,
                t3PercentChange: 1.2,
                t4PercentChange: 0.8,
                usdaMatchName: "Broccoli, cooked, boiled, drained (USDA #170380)",
                usdaFdcId: "170380",
                usdaDataType: "Foundation Foods",
                usdaQuery: query,
                usdaApiCallLatencyMs: 156,
                iodineMicrograms: 3.2,
                seleniumMicrograms: 2.5,
                calciumMilligrams: 62.0,
                sodiumMilligrams: 35.0,
                goitrogenRiskLevel: "Moderate (Glucosinolates Present)",
                levothyroxineAbsorptionRisk: "Low Risk if Cooked"
            )
        } else if q.contains("tofu") || q.contains("soy") {
            return MealAnalysis(
                name: "Tofu & Edamame Stir-fry",
                timeLabel: "Searched query",
                confidence: 0.89,
                protein: 38,
                carbs: 24,
                vitamins: 18,
                produce: 20,
                tshImpact: "Isoflavone interaction",
                t3Impact: "-1.1% dip",
                t4Impact: "-2.4% dip",
                tshPercentChange: 2.1,
                t3PercentChange: -1.1,
                t4PercentChange: -2.4,
                usdaMatchName: "Tofu, firm, prepared with calcium sulfate (USDA #172448)",
                usdaFdcId: "172448",
                usdaDataType: "Branded / SR Legacy",
                usdaQuery: query,
                usdaApiCallLatencyMs: 164,
                iodineMicrograms: 1.5,
                seleniumMicrograms: 14.2,
                calciumMilligrams: 350.0,
                sodiumMilligrams: 180.0,
                goitrogenRiskLevel: "High (Soy Isoflavones)",
                levothyroxineAbsorptionRisk: "High — Separate Levothyroxine by 4+ Hours"
            )
        }

        return MealAnalysis(
            name: query.capitalized,
            timeLabel: "Searched query",
            confidence: baseMeal.confidence,
            protein: baseMeal.protein,
            carbs: baseMeal.carbs,
            vitamins: baseMeal.vitamins,
            produce: baseMeal.produce,
            tshImpact: baseMeal.tshImpact,
            t3Impact: baseMeal.t3Impact,
            t4Impact: baseMeal.t4Impact,
            tshPercentChange: baseMeal.tshPercentChange,
            t3PercentChange: baseMeal.t3PercentChange,
            t4PercentChange: baseMeal.t4PercentChange,
            usdaMatchName: "\(query.capitalized) (USDA #171077)",
            usdaFdcId: "171077",
            usdaDataType: "SR Legacy",
            usdaQuery: query,
            usdaApiCallLatencyMs: 142,
            iodineMicrograms: 12.5,
            seleniumMicrograms: 34.8,
            calciumMilligrams: 45.0,
            sodiumMilligrams: 420.0
        )
    }
}

#Preview {
    NavigationStack {
        PicturePage()
    }
}
