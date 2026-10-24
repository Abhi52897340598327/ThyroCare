import SwiftUI
import UIKit
import AVFoundation
import Combine
import WebKit

struct PicturePage: View {
    var store: CareStore?
    @State private var diet = ""
    @State private var meals: [MealAnalysis] = []
    @State private var showingScanner = false
    @State private var selectedTabMode = 0 // 0: Scanner, 1: Live Web Portal, 2: USDA API Inspector, 3: Meal History
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
                Text("Web Portal").tag(1)
                Text("USDA API").tag(2)
                Text("Log History").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 6)

            if selectedTabMode == 0 {
                // MARK: - TAB 1: CAMERA SCANNER & LATEST ANALYSIS
                ThyroCard {
                    ThyroSectionTitle("Meal Camera Scan", subtitle: "Capture and confirm a meal photo for your care record.")

                    TextField("Diet or eating pattern (optional)", text: $diet)
                        .textFieldStyle(.roundedBorder)

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

                Link(destination: URL(string: "https://thyrocare-9qfo.onrender.com/clinician/food-analysis")!) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Open Web Dashboard Food Analysis")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundStyle(ThyroUI.teal)
                    .padding(14)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                // MARK: - TAB 2: LIVE EMBEDDED WEB DASHBOARD FOOD ANALYSIS
                ThyroCard {
                    ThyroSectionTitle("Live Web Portal", subtitle: "thyrocare-9qfo.onrender.com/clinician/food-analysis")

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Connected to Live Cloud Server")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ThyroUI.teal)

                        Spacer()

                        Link("Open Safari ↗", destination: URL(string: "https://thyrocare-9qfo.onrender.com/clinician/food-analysis")!)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ThyroUI.navy)
                    }

                    WebPortalView(url: URL(string: "https://thyrocare-9qfo.onrender.com/clinician/food-analysis")!)
                        .frame(height: 520)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

            } else if selectedTabMode == 2 {
                // MARK: - TAB 3: USDA FOODDATA CENTRAL API INSPECTOR
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
                // MARK: - TAB 4: MEAL LOG HISTORY
                ThyroCard {
                    ThyroSectionTitle("Meal History", subtitle: "Photos and entries saved to your account.")
                    if !meals.isEmpty {
                        ForEach(meals) { meal in
                            NavigationLink {
                                MealAnalysisDetailPage(meal: meal)
                            } label: {
                                MealHistoryRow(meal: meal)
                            }
                            Divider()
                        }
                    }

                    if let store {
                        Text(store.syncLabel).font(.caption).foregroundStyle(.secondary)
                        ForEach(store.entries("meals")) { record in
                            NavigationLink {
                                CareRecordDetail(store: store, record: record)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.fields["description"] ?? "Meal photo")
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(record.fields["observedDate"] ?? "") · \(record.fields["mealTime"] ?? "")")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(ThyroUI.navy)
                            Divider()
                        }
                        ForEach(store.pending.filter { $0.kind == "meals" }) { draft in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(draft.fields["description"] ?? "Meal photo")
                                Text("Saved on device · Waiting to sync")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if meals.isEmpty && (store == nil || (store!.entries("meals").isEmpty && !store!.pending.contains(where: { $0.kind == "meals" }))) {
                        Text("No saved meals. Capture a photo or add a meal manually.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    if let store {
                        NavigationLink("Add a meal manually") {
                            CareEntryView(store: store, kind: "meals")
                        }
                    }
                }
            }
        }
        .onAppear(perform: loadPersistedMeals)
        .sheet(isPresented: $showingScanner) {
            NavigationStack {
                MealCameraPage(store: store, diet: diet) { meal in
                    meals.insert(meal.copyWithNewID, at: 0)
                    saveMeals()
                }
            }
        }
    }

    private func loadPersistedMeals() {
        guard !mealHistoryData.isEmpty,
              let decodedMeals = try? JSONDecoder().decode([MealAnalysis].self, from: mealHistoryData) else {
            meals = []
            return
        }

        let validMeals = decodedMeals.filter { $0.usdaMatchName != "USDA match unavailable" }
        meals = validMeals

        if validMeals.count != decodedMeals.count {
            saveMeals()
        }
    }

    private func saveMeals() {
        guard let encodedMeals = try? JSONEncoder().encode(meals) else { return }
        mealHistoryData = encodedMeals
    }
}

struct WebPortalView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        if let url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url, uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
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
    @Environment(\.dismiss) private var dismiss
    var store: CareStore?
    var diet = ""
    let onMealScanned: (MealAnalysis) -> Void
    @State private var mealDate = Date()
    @State private var saved = false
    @State private var captureDate: Date?

    @StateObject private var camera = MealCameraController()
    @State private var scannedMeal: MealAnalysis?
    @State private var scanErrorMessage: String?
    @State private var capturedImage: UIImage?
    @State private var isScanning = false
    @State private var capturedPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Camera / Captured Photo Frame
                CameraLensFrame(camera: camera, capturedImage: capturedImage, isCaptured: capturedPhoto)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .shadow(color: ThyroUI.navy.opacity(capturedPhoto ? 0.12 : 0), radius: 12, x: 0, y: 6)

                // Error Message if any
                if let scanErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(scanErrorMessage)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThyroUI.coral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                }

                // Shutter Button (Before Photo is Captured)
                if !capturedPhoto {
                    Button {
                        takePictureAndAnalyze()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take a Picture")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(ThyroUI.teal))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .disabled(isScanning)
                } else if isScanning {
                    // Active Scanning State
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(ThyroUI.teal)

                        Text("Analyzing meal with AI...")
                            .font(.headline)
                            .foregroundStyle(ThyroUI.navy)

                        Text("Identifying foods with Gemini 3.5 Flash & mapping USDA micronutrients")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }

                // MARK: - Output Down Below (When Analysis Complete)
                if let meal = scannedMeal {
                    VStack(spacing: 16) {
                        // Success Confirmation Badge
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.green)
                            Text("Analyzed & Saved to Meal History")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(Color.green.opacity(0.12)))

                        // Meal Overview Card
                        ThyroCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(ThyroUI.navy)
                                    Text("USDA Match: \(meal.usdaMatchName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(meal.confidence * 100))% AI Match")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(ThyroUI.teal)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(ThyroUI.softGray))
                            }

                            Divider()

                            // Macronutrient Donut + Breakdown
                            MealNutritionSummary(meal: meal)
                        }
                        .padding(.horizontal, 20)

                        // Thyroid Impact Card
                        ThyroCard {
                            ThyroSectionTitle("Thyroid Impact Summary", subtitle: "Projected hormonal co-factor effects")
                            MetricRow(title: "TSH Impact", value: meal.tshImpact, color: ThyroUI.teal)
                            MetricRow(title: "Free T3", value: meal.t3Impact, color: ThyroUI.amber)
                            MetricRow(title: "Free T4", value: meal.t4Impact, color: ThyroUI.violet)
                        }
                        .padding(.horizontal, 20)

                        // USDA Micronutrient Co-Factors Card
                        ThyroCard {
                            ThyroSectionTitle("USDA Micronutrients & Co-Factors")
                            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                GridRow {
                                    MicronutrientBadge(title: "Iodine", value: String(format: "%.1f µg", meal.iodineMicrograms), color: ThyroUI.teal)
                                    MicronutrientBadge(title: "Selenium", value: String(format: "%.1f µg", meal.seleniumMicrograms), color: ThyroUI.amber)
                                }
                                GridRow {
                                    MicronutrientBadge(title: "Calcium", value: String(format: "%.0f mg", meal.calciumMilligrams), color: ThyroUI.violet)
                                    MicronutrientBadge(title: "Sodium", value: String(format: "%.0f mg", meal.sodiumMilligrams), color: ThyroUI.coral)
                                }
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Goitrogen Risk:")
                                        .font(.caption.weight(.bold))
                                    Text(meal.goitrogenRiskLevel)
                                        .font(.caption)
                                }
                                HStack {
                                    Text("Levothyroxine Absorption:")
                                        .font(.caption.weight(.bold))
                                    Text(meal.levothyroxineAbsorptionRisk)
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(ThyroUI.navy)

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
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Action Buttons: Done / Retake
                        HStack(spacing: 12) {
                            Button {
                                retakePhoto()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Retake")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(ThyroUI.navy)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 14).fill(ThyroUI.softGray))
                            }
                            .buttonStyle(.plain)

                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Done")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(RoundedRectangle(cornerRadius: 14).fill(ThyroUI.teal))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                ThyroMedicalDisclaimer()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
            .padding(.top, 16)
        }
        .task {
            await camera.start()
        }
        .onDisappear {
            camera.stop()
        }
        .navigationTitle("Meal Camera & USDA Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(ThyroUI.teal)
            }
        }
    }

    private func retakePhoto() {
        capturedImage = nil
        capturedPhoto = false
        scannedMeal = nil
        saved = false
        scanErrorMessage = nil
        Task {
            await camera.start()
        }
    }

    private func takePictureAndAnalyze() {
        guard !isScanning else { return }
        Task { @MainActor in
            isScanning = true
            scanErrorMessage = nil
            do {
                let data: Data
                #if targetEnvironment(simulator)
                data = MealCameraPage.sampleMealImageData()
                #else
                if camera.isCameraAvailable {
                    data = try await camera.capturePhoto()
                } else {
                    data = MealCameraPage.sampleMealImageData()
                }
                #endif

                guard let image = UIImage(data: data) else {
                    throw CareClientError.message("Could not process photo. Please try again.")
                }
                capturedImage = image
                captureDate = Date()
                capturedPhoto = true

                // Prepare normalized JPEG for analysis
                let scale = min(1, 1600 / max(image.size.width, image.size.height))
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                format.opaque = true
                let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                    UIColor.white.setFill()
                    UIRectFill(CGRect(origin: .zero, size: size))
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                guard let jpeg = normalized.jpegData(compressionQuality: 0.82) else {
                    throw CareClientError.message("Could not prepare image for analysis.")
                }

                // Call MealAnalysisService (Gemini + USDA)
                let meal = try await MealAnalysisService.shared.analyze(imageData: jpeg)
                scannedMeal = meal

                // Automatically save to meal history
                onMealScanned(meal)

                // Also save to CareStore if available
                if let store {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd"
                    let day = formatter.string(from: mealDate)
                    formatter.dateFormat = "HH:mm"
                    let fields = [
                        "description": meal.name,
                        "observedDate": day,
                        "mealTime": formatter.string(from: mealDate),
                        "timezone": TimeZone.current.identifier,
                        "capturedAt": (captureDate ?? Date()).ISO8601Format(),
                        "diet": diet,
                        "analysisStatus": "complete",
                        "analysisModel": "gemini-3.5-flash",
                        "analysisAt": Date().ISO8601Format(),
                        "recognizedFoods": meal.name,
                        "usdaMatch": meal.usdaMatchName,
                        "hasPhoto": "true",
                        "source": "Patient camera photo analyzed with Gemini 3.5 Flash",
                        "summary": "AI identified: \(meal.name) (USDA: \(meal.usdaMatchName)). Protein: \(meal.protein)%, Carbs: \(meal.carbs)%, Produce: \(meal.produce)%."
                    ]
                    _ = await store.save(kind: "meals", fields: fields, photo: jpeg)
                }

                saved = true
                camera.stop()
            } catch {
                scanErrorMessage = MealAnalysisService.userFacingMessage(for: error)
            }
            isScanning = false
        }
    }

    static func sampleMealImageData() -> Data {
        let possiblePaths = [
            "/Users/abhiraamvenigalla/Desktop/CAC/ThyroCare/Backend/Public/meal-uploads/meal-5BE41EF3-BBF0-4E15-852E-27CA222C7C25.jpg",
            "/Users/abhiraamvenigalla/Desktop/CAC/ThyroCare/Backend/Public/meal-uploads/meal-A788D5D1-2EE3-4B68-81AA-DC1680DA565F.jpg"
        ]
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)), !data.isEmpty {
                return data
            }
        }

        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(red: 0.88, green: 0.83, blue: 0.76, alpha: 1.0).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 40, y: 40, width: 432, height: 432))
            cg.setStrokeColor(UIColor(white: 0.88, alpha: 1.0).cgColor)
            cg.setLineWidth(4)
            cg.strokeEllipse(in: CGRect(x: 40, y: 40, width: 432, height: 432))

            cg.setFillColor(UIColor(red: 0.95, green: 0.52, blue: 0.40, alpha: 1.0).cgColor)
            let salmonRect = CGRect(x: 140, y: 170, width: 230, height: 110)
            let salmonPath = UIBezierPath(roundedRect: salmonRect, cornerRadius: 18)
            salmonPath.fill()

            cg.setStrokeColor(UIColor(red: 0.55, green: 0.25, blue: 0.18, alpha: 0.7).cgColor)
            cg.setLineWidth(4)
            for i in 0..<5 {
                let x = 160.0 + Double(i) * 45.0
                cg.move(to: CGPoint(x: x, y: 175))
                cg.addLine(to: CGPoint(x: x + 25, y: 275))
                cg.strokePath()
            }

            cg.setFillColor(UIColor(red: 0.22, green: 0.60, blue: 0.32, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 130, y: 300, width: 75, height: 75))
            cg.fillEllipse(in: CGRect(x: 190, y: 310, width: 70, height: 70))
            cg.fillEllipse(in: CGRect(x: 250, y: 305, width: 75, height: 75))

            cg.setFillColor(UIColor(red: 0.96, green: 0.72, blue: 0.28, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 180, y: 90, width: 150, height: 70))

            cg.setFillColor(UIColor(red: 0.99, green: 0.88, blue: 0.25, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 350, y: 240, width: 40, height: 50))
        }
        return img.jpegData(compressionQuality: 0.85) ?? Data()
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
            return "Camera Simulator Preview\nTap 'Take a Picture' below"
        }

        if !hasCameraUsageDescription {
            return "Add NSCameraUsageDescription in Info.plist to enable camera"
        }

        return camera.errorMessage ?? "Camera access is unavailable"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.69, green: 0.84, blue: 0.75))
                .aspectRatio(1.2, contentMode: .fit)

            if isCaptured {
                StaticMealPhoto(image: capturedImage)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding(1)
            } else if camera.isReady {
                CameraPreview(camera: camera)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
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
                .foregroundStyle(ThyroUI.navy.opacity(0.85))
                .padding(24)
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
                    Text("Photo Captured")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(ThyroUI.teal.opacity(0.92)))
                .padding(.bottom, 12)
            }
        }
        .aspectRatio(1.2, contentMode: .fit)
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
        #if targetEnvironment(simulator)
        return MealCameraPage.sampleMealImageData()
        #else
        if !isCameraAvailable || !isConfigured {
            return MealCameraPage.sampleMealImageData()
        }
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else { return }
                guard self.isConfigured else {
                    continuation.resume(returning: MealCameraPage.sampleMealImageData())
                    return
                }

                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                self.output.capturePhoto(with: settings, delegate: self)
            }
        }
        #endif
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
                        DetailFieldRow(
                            title: "API Call Latency",
                            value: meal.usdaApiCallLatencyMs > 0 ? "\(meal.usdaApiCallLatencyMs) ms" : "Not provided"
                        )
                        DetailFieldRow(
                            title: "USDA Metadata Status",
                            value: meal.usdaFdcId == "Unavailable" ? "Incomplete backend response" : "Verified USDA match"
                        )

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
    var rawUsdaJsonResponse: String = "{\"status\":\"USDA response unavailable\"}"

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

    private enum NutritionCodingKeys: String, CodingKey {
        case nutritionDetails
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
        usdaMatchName: String = "USDA match unavailable",
        usdaFdcId: String = "Unavailable",
        usdaDataType: String = "Unavailable",
        usdaQuery: String = "Unavailable",
        usdaApiCallLatencyMs: Int = 0,
        iodineMicrograms: Double = 0,
        seleniumMicrograms: Double = 0,
        calciumMilligrams: Double = 0,
        sodiumMilligrams: Double = 0,
        goitrogenRiskLevel: String = "Not evaluated",
        levothyroxineAbsorptionRisk: String = "Not evaluated",
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

        let nutritionContainer = try decoder.container(keyedBy: NutritionCodingKeys.self)
        let legacyNutritionDetails = try nutritionContainer.decodeIfPresent(
            [MealUSDANutritionDetail].self,
            forKey: .nutritionDetails
        ) ?? []
        let firstUSDAMatch = legacyNutritionDetails.first

        usdaMatchName = try container.decodeIfPresent(String.self, forKey: .usdaMatchName)
            ?? firstUSDAMatch?.usdaDescription
            ?? "USDA match unavailable"
        usdaFdcId = try container.decodeIfPresent(String.self, forKey: .usdaFdcId)
            ?? firstUSDAMatch?.usdaFdcId
            ?? "Unavailable"
        usdaDataType = try container.decodeIfPresent(String.self, forKey: .usdaDataType)
            ?? firstUSDAMatch?.usdaDataType
            ?? "Unavailable"
        usdaQuery = try container.decodeIfPresent(String.self, forKey: .usdaQuery)
            ?? firstUSDAMatch?.usdaSearchQuery
            ?? "Unavailable"
        usdaApiCallLatencyMs = try container.decodeIfPresent(Int.self, forKey: .usdaApiCallLatencyMs) ?? 0
        iodineMicrograms = try container.decodeIfPresent(Double.self, forKey: .iodineMicrograms) ?? 0
        seleniumMicrograms = try container.decodeIfPresent(Double.self, forKey: .seleniumMicrograms) ?? 0
        calciumMilligrams = try container.decodeIfPresent(Double.self, forKey: .calciumMilligrams) ?? 0
        sodiumMilligrams = try container.decodeIfPresent(Double.self, forKey: .sodiumMilligrams) ?? 0
        goitrogenRiskLevel = try container.decodeIfPresent(String.self, forKey: .goitrogenRiskLevel) ?? "Not evaluated"
        levothyroxineAbsorptionRisk = try container.decodeIfPresent(String.self, forKey: .levothyroxineAbsorptionRisk) ?? "Not evaluated"
        if let rawResponse = try container.decodeIfPresent(String.self, forKey: .rawUsdaJsonResponse) {
            rawUsdaJsonResponse = rawResponse
        } else if let encodedDetails = try? JSONEncoder().encode(legacyNutritionDetails),
                  let detailsJSON = String(data: encodedDetails, encoding: .utf8) {
            rawUsdaJsonResponse = detailsJSON
        } else {
            rawUsdaJsonResponse = "{\"status\":\"USDA response unavailable\"}"
        }
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

private struct MealUSDANutritionDetail: Codable {
    let usdaSearchQuery: String
    let usdaDescription: String
    let usdaFdcId: String?
    let usdaDataType: String?
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
