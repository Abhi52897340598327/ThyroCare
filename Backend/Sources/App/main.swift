import Foundation
import Vapor
import Leaf

let mealAnalysisStore = MealAnalysisStore()

@main
struct ThyroCareBackend {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)
        defer { Task { try? await app.asyncShutdown() } }

        try configure(app)
        try await app.execute()
    }
}

func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)
    app.routes.defaultMaxBodySize = "8mb"

    app.get("health") { _ in
        ["status": "ok", "service": "ThyroCareBackend"]
    }

    app.post("analyze-meal") { req async throws -> MealAnalysisResponse in
        let request = try req.content.decode(AnalyzeMealRequest.self)
        let imagePath = try saveUploadedMealImage(request, app: req.application, logger: req.logger)
        let service = MealAnalysisPipeline(client: req.client, logger: req.logger)
        let response = try await service.analyze(request)
        mealAnalysisStore.add(response, imagePath: imagePath)
        req.logger.info("Meal analysis completed: \(response.name), confidence \(Int(response.confidence * 100))%")
        return response
    }

    app.get("analyses") { _ in
        mealAnalysisStore.recent()
    }

    app.get("dashboard") { _ -> Response in
        Response(
            status: .ok,
            headers: ["content-type": "text/html; charset=utf-8"],
            body: .init(string: DashboardRenderer.render(analyses: mealAnalysisStore.recent()))
        )
    }
}

func saveUploadedMealImage(_ request: AnalyzeMealRequest, app: Application, logger: Logger) throws -> String? {
    guard let imageBase64 = request.imageBase64,
          let imageData = Data(base64Encoded: imageBase64) else {
        return nil
    }

    let uploadDirectory = app.directory.publicDirectory + "meal-uploads/"
    try FileManager.default.createDirectory(atPath: uploadDirectory, withIntermediateDirectories: true)

    let fileName = "meal-\(UUID().uuidString).jpg"
    try imageData.write(to: URL(fileURLWithPath: uploadDirectory + fileName))

    let publicPath = "/meal-uploads/\(fileName)"
    logger.info("Saved meal image for model inspection: \(publicPath)")
    return publicPath
}

struct AnalyzeMealRequest: Content {
    let imageBase64: String?
    let mimeType: String?
    let localClassifications: [LocalFoodClassification]?
}

struct MealAnalysisResponse: Content {
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
    let nutritionDetails: [USDANutritionDetail]
}

struct USDANutritionDetail: Content {
    let detectedFood: String
    let estimatedGrams: Double
    let usdaSearchQuery: String
    let usdaDescription: String
    let calories: Double?
    let proteinGrams: Double?
    let carbohydrateGrams: Double?
    let fiberGrams: Double?
    let sugarGrams: Double?
    let fatGrams: Double?
    let potassiumMilligrams: Double?
    let vitaminCMilligrams: Double?
    let vitaminBMilligrams: Double?
    let vitaminDMicrograms: Double?
}

final class MealAnalysisStore: @unchecked Sendable {
    private var analyses: [StoredMealAnalysis] = []
    private let lock = NSLock()

    func add(_ analysis: MealAnalysisResponse, imagePath: String?) {
        lock.lock()
        analyses.insert(StoredMealAnalysis(analysis: analysis, imagePath: imagePath), at: 0)
        if analyses.count > 20 {
            analyses.removeLast(analyses.count - 20)
        }
        lock.unlock()
    }

    func recent() -> [StoredMealAnalysis] {
        lock.lock()
        let currentAnalyses = analyses
        lock.unlock()
        return currentAnalyses
    }
}

struct StoredMealAnalysis: Content {
    let analysis: MealAnalysisResponse
    let imagePath: String?
}

enum DashboardRenderer {
    static func render(analyses: [StoredMealAnalysis]) -> String {
        let rows = analyses.isEmpty
            ? """
            <tr>
                <td colspan="11" class="empty">No meal analyses yet. Scan a meal in the iPhone app, then refresh this page.</td>
            </tr>
            """
            : analyses.map(row).joined(separator: "\n")

        return """
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta http-equiv="refresh" content="8">
            <title>ThyroCare Backend</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                    margin: 0;
                    background: #e8faf5;
                    color: #0b2239;
                }
                main {
                    max-width: 1120px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                section {
                    background: white;
                    border-radius: 8px;
                    padding: 24px;
                    box-shadow: 0 12px 32px rgba(11, 34, 57, 0.1);
                }
                h1 {
                    margin: 0 0 8px;
                }
                p {
                    color: #5d6875;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                    font-size: 14px;
                }
                th, td {
                    text-align: left;
                    padding: 12px 10px;
                    border-bottom: 1px solid #d8ebe5;
                }
                th {
                    color: #0f9c9c;
                    font-size: 12px;
                    text-transform: uppercase;
                    letter-spacing: 0.04em;
                }
                .empty {
                    text-align: center;
                    color: #5d6875;
                    padding: 32px 10px;
                }
                .badge {
                    display: inline-block;
                    padding: 4px 8px;
                    border-radius: 999px;
                    background: rgba(15, 156, 156, 0.12);
                    color: #087878;
                    font-weight: 700;
                }
                img.meal-image {
                    width: 96px;
                    height: 96px;
                    object-fit: cover;
                    border-radius: 8px;
                    border: 1px solid #d8ebe5;
                    background: #f5fbf8;
                }
                a {
                    color: #087878;
                    font-weight: 700;
                }
                .nutrition-detail {
                    margin: 8px 0 0;
                    color: #5d6875;
                    font-size: 12px;
                    max-width: 420px;
                }
                .nutrition-detail summary {
                    cursor: pointer;
                    color: #087878;
                    font-weight: 700;
                }
                .nutrition-detail ul {
                    margin: 8px 0 0;
                    padding-left: 18px;
                }
                .nutrition-detail li {
                    margin-bottom: 8px;
                }
                .nutrition-detail span {
                    display: block;
                    margin-top: 2px;
                }
            </style>
        </head>
        <body>
            <main>
                <section>
                    <h1>ThyroCare Backend</h1>
                    <p>Status: <strong>Ready</strong>. This page auto-refreshes every 8 seconds.</p>
                    <table>
                        <thead>
                            <tr>
                                <th>Image sent to model</th>
                                <th>Meal</th>
                                <th>USDA food bank return output</th>
                                <th>Confidence</th>
                                <th>Protein</th>
                                <th>Carbs</th>
                                <th>Vitamins</th>
                                <th>Produce</th>
                                <th>TSH</th>
                                <th>T3</th>
                                <th>T4</th>
                            </tr>
                        </thead>
                        <tbody>
                            \(rows)
                        </tbody>
                    </table>
                </section>
            </main>
        </body>
        </html>
        """
    }

    private static func row(for storedAnalysis: StoredMealAnalysis) -> String {
        let analysis = storedAnalysis.analysis
        let imageHTML: String
        if let imagePath = storedAnalysis.imagePath {
            imageHTML = """
            <a href="\(escape(imagePath))" target="_blank">
                <img class="meal-image" src="\(escape(imagePath))" alt="Meal image sent to Gemini">
            </a>
            """
        } else {
            imageHTML = "<span>No image</span>"
        }

        return """
        <tr>
            <td>\(imageHTML)</td>
            <td><strong>\(escape(analysis.name))</strong><br><span>\(escape(analysis.timeLabel))</span></td>
            <td>\(nutritionDetailsHTML(for: analysis))</td>
            <td><span class="badge">\(Int(analysis.confidence * 100))%</span></td>
            <td>\(analysis.protein)%</td>
            <td>\(analysis.carbs)%</td>
            <td>\(analysis.vitamins)%</td>
            <td>\(analysis.produce)%</td>
            <td>\(format(analysis.tshPercentChange))%</td>
            <td>\(format(analysis.t3PercentChange))%</td>
            <td>\(format(analysis.t4PercentChange))%</td>
        </tr>
        """
    }

    private static func nutritionDetailsHTML(for analysis: MealAnalysisResponse) -> String {
        guard !analysis.nutritionDetails.isEmpty else {
            return "<span class=\"nutrition-detail\">No USDA nutrient matches returned.</span>"
        }

        let items = analysis.nutritionDetails.map { detail in
            let nutrients = [
                detail.calories.map { "Calories \(format($0))" },
                detail.proteinGrams.map { "Protein \(format($0))g" },
                detail.carbohydrateGrams.map { "Carbs \(format($0))g" },
                detail.fiberGrams.map { "Fiber \(format($0))g" },
                detail.sugarGrams.map { "Sugar \(format($0))g" },
                detail.fatGrams.map { "Fat \(format($0))g" },
                detail.potassiumMilligrams.map { "Potassium \(format($0))mg" },
                detail.vitaminCMilligrams.map { "Vitamin C \(format($0))mg" },
                detail.vitaminBMilligrams.map { "Vitamin B total \(format($0))mg" },
                detail.vitaminDMicrograms.map { "Vitamin D \(format($0))mcg" }
            ]
            .compactMap { $0 }
            .joined(separator: " · ")

            return """
            <li>
                <strong>\(escape(detail.detectedFood))</strong>
                <span>\(format(detail.estimatedGrams))g estimate · USDA: \(escape(detail.usdaDescription)) · query: \(escape(detail.usdaSearchQuery))</span>
                <span>\(escape(nutrients))</span>
            </li>
            """
        }
        .joined(separator: "\n")

        return """
        <details class="nutrition-detail">
            <summary>USDA nutrition data</summary>
            <ul>\(items)</ul>
        </details>
        """
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

struct VisionFood: Codable {
    let name: String
    let estimatedGrams: Double
    let usdaSearchQuery: String
}

struct VisionAnalysis: Codable {
    let mealName: String
    let confidence: Double
    let foods: [VisionFood]
}

struct LocalFoodClassification: Codable {
    let name: String
    let confidence: Double
    let usdaSearchQuery: String
}

struct MealAnalysisPipeline {
    let client: Client
    let logger: Logger

    func analyze(_ request: AnalyzeMealRequest) async throws -> MealAnalysisResponse {
        let vision = try await identifyFoods(request)
        let nutrition = try await nutritionSummary(for: vision.foods)
        return buildResponse(vision: vision, nutrition: nutrition)
    }

    private func identifyFoods(_ request: AnalyzeMealRequest) async throws -> VisionAnalysis {
        guard let imageBase64 = request.imageBase64, !imageBase64.isEmpty else {
            if let localClassifications = request.localClassifications, !localClassifications.isEmpty {
                return buildVisionAnalysis(from: localClassifications)
            }

            throw Abort(.badRequest, reason: "No image data or local classifications were provided")
        }

        if let geminiAPIKey = Environment.get("GEMINI_API_KEY"), !geminiAPIKey.isEmpty, geminiAPIKey != "replace_me" {
            do {
                return try await identifyFoodsWithGemini(
                    imageBase64: imageBase64,
                    mimeType: request.mimeType ?? "image/jpeg",
                    localClassifications: request.localClassifications,
                    apiKey: geminiAPIKey
                )
            } catch {
                logger.error("Gemini request failed: \(error.localizedDescription)")
            }
        }

        guard let apiKey = Environment.get("OPENAI_API_KEY"), !apiKey.isEmpty, apiKey != "replace_me" else {
            if let localClassifications = request.localClassifications, !localClassifications.isEmpty {
                logger.warning("No usable hosted vision API key; using local Vision classifications as fallback")
                return buildVisionAnalysis(from: localClassifications)
            }

            logger.warning("No usable hosted vision API key or local classifications; using generic meal fallback")
            return fallbackVisionAnalysis()
        }

        let model = Environment.get("OPENAI_MODEL") ?? "gpt-4.1-mini"
        let mimeType = request.mimeType ?? "image/jpeg"
        let dataURL = "data:\(mimeType);base64,\(imageBase64)"
        let prompt = mealVisionPrompt(localClassifications: request.localClassifications)

        let body: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "user",
                    "content": [
                        ["type": "input_text", "text": prompt],
                        ["type": "input_image", "image_url": dataURL]
                    ]
                ]
            ],
            "temperature": 0.1
        ]

        let response = try await client.post("https://api.openai.com/v1/responses") { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            req.headers.contentType = .json
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            req.body = .init(data: jsonData)
        }

        guard response.status == .ok else {
            let detail = response.body.flatMap { String(buffer: $0) } ?? "No response body"
            logger.error("OpenAI request failed: \(detail)")

            if let localClassifications = request.localClassifications, !localClassifications.isEmpty {
                logger.warning("Using local Vision classifications because OpenAI failed")
                return buildVisionAnalysis(from: localClassifications)
            }

            logger.warning("Using generic meal fallback because OpenAI failed and no local classifications were available")
            return fallbackVisionAnalysis()
        }

        let openAIResponse = try response.content.decode(OpenAIResponse.self)
        guard let text = openAIResponse.outputText else {
            throw Abort(.badGateway, reason: "OpenAI did not return parseable meal JSON")
        }

        let jsonText = text.extractJSONObject()
        guard let data = jsonText.data(using: .utf8) else {
            throw Abort(.badGateway, reason: "OpenAI returned invalid UTF-8")
        }

        return try JSONDecoder().decode(VisionAnalysis.self, from: data)
    }

    private func identifyFoodsWithGemini(
        imageBase64: String,
        mimeType: String,
        localClassifications: [LocalFoodClassification]?,
        apiKey: String
    ) async throws -> VisionAnalysis {
        let model = Environment.get("GEMINI_MODEL") ?? "gemini-3.1-pro-preview"
        let escapedModel = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        let url = "https://generativelanguage.googleapis.com/v1beta/models/\(escapedModel):generateContent?key=\(apiKey)"

        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": mealVisionPrompt(localClassifications: localClassifications)],
                        [
                            "inline_data": [
                                "mime_type": mimeType,
                                "data": imageBase64
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "responseMimeType": "application/json"
            ]
        ]

        let response = try await client.post(URI(string: url)) { req in
            req.headers.contentType = .json
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            req.body = .init(data: jsonData)
        }

        guard response.status == .ok else {
            let detail = response.body.flatMap { String(buffer: $0) } ?? "No response body"
            logger.error("Gemini request failed: \(detail)")
            throw Abort(.badGateway, reason: "Gemini meal analysis failed")
        }

        let geminiResponse = try response.content.decode(GeminiGenerateContentResponse.self)
        guard let text = geminiResponse.outputText else {
            throw Abort(.badGateway, reason: "Gemini did not return parseable meal JSON")
        }

        let jsonText = text.extractJSONObject()
        guard let data = jsonText.data(using: .utf8) else {
            throw Abort(.badGateway, reason: "Gemini returned invalid UTF-8")
        }

        return try JSONDecoder().decode(VisionAnalysis.self, from: data)
    }

    private func mealVisionPrompt(localClassifications: [LocalFoodClassification]?) -> String {
        let localHints = localClassifications?
            .prefix(5)
            .map { "\($0.name) (\(Int($0.confidence * 100))% confidence)" }
            .joined(separator: ", ") ?? "none"

        return """
        Identify the visible foods and estimate portions in grams.
        Local on-device Vision hints, if useful: \(localHints).
        Trust the image more than the hints when they disagree.
        Return only compact JSON with this exact shape:
        {"mealName":"string","confidence":0.0,"foods":[{"name":"string","estimatedGrams":100,"usdaSearchQuery":"string"}]}
        Confidence must be between 0 and 1. Use USDA-friendly search terms.
        """
    }

    private func fallbackVisionAnalysis() -> VisionAnalysis {
        VisionAnalysis(
            mealName: "Scanned meal",
            confidence: 0.48,
            foods: [
                VisionFood(name: "Mixed meal", estimatedGrams: 250, usdaSearchQuery: "mixed meal"),
                VisionFood(name: "Vegetables", estimatedGrams: 90, usdaSearchQuery: "vegetables"),
                VisionFood(name: "Protein food", estimatedGrams: 120, usdaSearchQuery: "chicken")
            ]
        )
    }

    private func buildVisionAnalysis(from classifications: [LocalFoodClassification]) -> VisionAnalysis {
        let usableClassifications = classifications
            .filter { !$0.usdaSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.confidence > $1.confidence }
            .prefix(5)

        let foods = usableClassifications.map { classification in
            VisionFood(
                name: classification.name,
                estimatedGrams: estimatedGrams(forConfidence: classification.confidence),
                usdaSearchQuery: classification.usdaSearchQuery
            )
        }

        let mealName = foods.first.map { "\($0.name) meal" } ?? "Scanned meal"
        let confidence = usableClassifications.first.map { min(max($0.confidence, 0), 1) } ?? 0.55

        return VisionAnalysis(mealName: mealName, confidence: confidence, foods: foods)
    }

    private func estimatedGrams(forConfidence confidence: Double) -> Double {
        let normalizedConfidence = min(max(confidence, 0), 1)
        return (120 + (normalizedConfidence * 130)).rounded()
    }

    private func nutritionSummary(for foods: [VisionFood]) async throws -> NutritionSummary {
        guard let apiKey = Environment.get("USDA_API_KEY"), !apiKey.isEmpty, apiKey != "replace_me" else {
            throw Abort(.internalServerError, reason: "USDA_API_KEY is missing")
        }

        var summary = NutritionSummary()

        for food in foods.prefix(6) {
            guard var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search") else {
                continue
            }

            components.queryItems = [
                URLQueryItem(name: "api_key", value: apiKey),
                URLQueryItem(name: "query", value: food.usdaSearchQuery),
                URLQueryItem(name: "pageSize", value: "1")
            ]

            guard let url = components.url else { continue }
            let response = try await client.get(URI(string: url.absoluteString))
            guard response.status == .ok else { continue }

            let search = try response.content.decode(USDASearchResponse.self)
            guard let match = search.foods.first else { continue }

            summary.add(detectedFood: food, usdaFood: match)
        }

        return summary.normalized()
    }

    private func buildResponse(vision: VisionAnalysis, nutrition: NutritionSummary) -> MealAnalysisResponse {
        let hormone = HormoneImpactCalculator.calculate(nutrition: nutrition)

        return MealAnalysisResponse(
            name: vision.mealName,
            timeLabel: "Just now",
            confidence: min(max(vision.confidence, 0), 1),
            protein: nutrition.proteinPercent,
            carbs: nutrition.carbsPercent,
            vitamins: nutrition.vitaminPercent,
            produce: nutrition.producePercent,
            tshImpact: hormone.tshDescription,
            t3Impact: hormone.t3Description,
            t4Impact: hormone.t4Description,
            tshPercentChange: hormone.tshPercentChange,
            t3PercentChange: hormone.t3PercentChange,
            t4PercentChange: hormone.t4PercentChange,
            nutritionDetails: nutrition.details
        )
    }
}

struct OpenAIResponse: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String?
            let text: String?
        }

        let content: [Content]?
    }

    let output: [Output]?
    let output_text: String?

    var outputText: String? {
        if let output_text { return output_text }

        return output?
            .compactMap(\.content)
            .flatMap { $0 }
            .compactMap(\.text)
            .joined(separator: "\n")
    }
}

struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }

            let parts: [Part]?
        }

        let content: Content?
    }

    let candidates: [Candidate]?

    var outputText: String? {
        candidates?
            .compactMap(\.content?.parts)
            .flatMap { $0 }
            .compactMap(\.text)
            .joined(separator: "\n")
    }
}

struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable {
    let fdcId: Int?
    let description: String?
    let dataType: String?
    let brandOwner: String?
    let foodNutrients: [USDAFoodNutrient]
}

struct USDAFoodNutrient: Decodable {
    let nutrientName: String?
    let value: Double?
}

struct NutritionSummary {
    var proteinGrams = 0.0
    var carbGrams = 0.0
    var vitaminScore = 0.0
    var produceScore = 0.0
    var details: [USDANutritionDetail] = []

    var proteinPercent = 25
    var carbsPercent = 35
    var vitaminPercent = 20
    var producePercent = 20

    mutating func add(detectedFood: VisionFood, usdaFood: USDAFood) {
        let grams = detectedFood.estimatedGrams
        let scale = max(grams, 1) / 100.0
        var calories: Double?
        var protein: Double?
        var carbs: Double?
        var fiber: Double?
        var sugar: Double?
        var fat: Double?
        var potassium: Double?
        var vitaminC: Double?
        var vitaminBTotal = 0.0
        var vitaminD: Double?

        for nutrient in usdaFood.foodNutrients {
            let name = nutrient.nutrientName?.lowercased() ?? ""
            let value = (nutrient.value ?? 0) * scale

            if name.contains("protein") {
                proteinGrams += value
                protein = value
            } else if name.contains("carbohydrate") {
                carbGrams += value
                carbs = value
            } else if name.contains("vitamin") {
                vitaminScore += value
                if name.contains("vitamin c") || name.contains("ascorbic") {
                    vitaminC = value
                } else if name.contains("vitamin d") {
                    vitaminD = value
                }
            } else if name.contains("fiber") || name.contains("folate") || name.contains("potassium") {
                produceScore += value
            }

            if isVitaminBNutrient(name) {
                vitaminBTotal += value
            }

            if name.contains("energy") || name == "calories" {
                calories = value
            } else if name.contains("fiber") {
                fiber = value
            } else if name.contains("sugars") || name.contains("sugar") {
                sugar = value
            } else if name.contains("total lipid") || name.contains("fat") {
                fat = value
            } else if name.contains("potassium") {
                potassium = value
            }
        }

        details.append(
            USDANutritionDetail(
                detectedFood: detectedFood.name,
                estimatedGrams: grams.rounded(to: 1),
                usdaSearchQuery: detectedFood.usdaSearchQuery,
                usdaDescription: usdaFood.description ?? "Unknown USDA food",
                calories: calories?.rounded(to: 1),
                proteinGrams: protein?.rounded(to: 1),
                carbohydrateGrams: carbs?.rounded(to: 1),
                fiberGrams: fiber?.rounded(to: 1),
                sugarGrams: sugar?.rounded(to: 1),
                fatGrams: fat?.rounded(to: 1),
                potassiumMilligrams: potassium?.rounded(to: 1),
                vitaminCMilligrams: vitaminC?.rounded(to: 1),
                vitaminBMilligrams: vitaminBTotal > 0 ? vitaminBTotal.rounded(to: 1) : nil,
                vitaminDMicrograms: vitaminD?.rounded(to: 1)
            )
        )
    }

    private func isVitaminBNutrient(_ name: String) -> Bool {
        name.contains("thiamin")
            || name.contains("riboflavin")
            || name.contains("niacin")
            || name.contains("pantothenic")
            || name.contains("vitamin b")
            || name.contains("b-6")
            || name.contains("b-12")
            || name.contains("folate")
            || name.contains("folic")
    }

    func normalized() -> NutritionSummary {
        let raw = [
            max(proteinGrams, 1),
            max(carbGrams, 1),
            max(vitaminScore * 4, 1),
            max(produceScore * 1.6, 1)
        ]

        let total = raw.reduce(0, +)
        var percentages = raw.map { Int(($0 / total * 100).rounded()) }
        let correction = 100 - percentages.reduce(0, +)
        if let maxIndex = percentages.indices.max(by: { percentages[$0] < percentages[$1] }) {
            percentages[maxIndex] += correction
        }

        var copy = self
        copy.proteinPercent = percentages[0]
        copy.carbsPercent = percentages[1]
        copy.vitaminPercent = percentages[2]
        copy.producePercent = percentages[3]
        return copy
    }
}

struct HormoneImpact {
    let tshDescription: String
    let t3Description: String
    let t4Description: String
    let tshPercentChange: Double
    let t3PercentChange: Double
    let t4PercentChange: Double
}

enum HormoneImpactCalculator {
    static func calculate(nutrition: NutritionSummary) -> HormoneImpact {
        let features = ThyroidNutritionFeatureVector(
            protein: Double(nutrition.proteinPercent),
            carbs: Double(nutrition.carbsPercent),
            vitamins: Double(nutrition.vitaminPercent),
            produce: Double(nutrition.producePercent)
        )

        let tsh = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.tsh).rounded(to: 1)
        let t3 = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.t3).rounded(to: 1)
        let t4 = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.t4).rounded(to: 1)

        return HormoneImpact(
            tshDescription: tsh <= 0 ? "Likely support" : "May increase",
            t3Description: t3 >= 0 ? "Support" : "May dip",
            t4Description: t4 >= 0 ? "Support" : "May dip",
            tshPercentChange: tsh,
            t3PercentChange: t3,
            t4PercentChange: t4
        )
    }
}

struct ThyroidNutritionFeatureVector {
    let protein: Double
    let carbs: Double
    let vitamins: Double
    let produce: Double
}

struct ThyroidNutritionWeightSet {
    let protein: Double
    let carbs: Double
    let vitamins: Double
    let produce: Double
}

enum ThyroidNutritionWeights {
    private static let baseline = ThyroidNutritionFeatureVector(protein: 25, carbs: 35, vitamins: 20, produce: 20)
    private static let percentScale = 10.0

    // Generated by Scripts/train_thyroid_nutrition_weights.R from NHANES 2007-2012.
    // These are cross-sectional association weights, not causal short-term meal effects.
    static let tsh = ThyroidNutritionWeightSet(protein: 0.10521309, carbs: 0.19192710, vitamins: -0.50299902, produce: 0.19986079)
    static let t3 = ThyroidNutritionWeightSet(protein: 0.03051861, carbs: 0.35628464, vitamins: -0.58748455, produce: 0.02571220)
    static let t4 = ThyroidNutritionWeightSet(protein: 0.24001525, carbs: 0.35777575, vitamins: 0.29357228, produce: -0.10863672)

    static func score(_ features: ThyroidNutritionFeatureVector, weights: ThyroidNutritionWeightSet) -> Double {
        let centeredProtein = (features.protein - baseline.protein) / 100.0
        let centeredCarbs = (features.carbs - baseline.carbs) / 100.0
        let centeredVitamins = (features.vitamins - baseline.vitamins) / 100.0
        let centeredProduce = (features.produce - baseline.produce) / 100.0

        let raw = (centeredProtein * weights.protein)
            + (centeredCarbs * weights.carbs)
            + (centeredVitamins * weights.vitamins)
            + (centeredProduce * weights.produce)

        return min(max(raw * percentScale, -8), 8)
    }
}

private extension String {
    func extractJSONObject() -> String {
        guard let start = firstIndex(of: "{"), let end = lastIndex(of: "}") else {
            return self
        }

        return String(self[start...end])
    }
}

private extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = Foundation.pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
