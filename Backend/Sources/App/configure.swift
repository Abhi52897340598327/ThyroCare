import Foundation
import Vapor
import Leaf

// MARK: - Helper Globals & Stores
let mealAnalysisStore = MealAnalysisStore()
let storeEngine = DataStoreEngine.shared

// MARK: - Response Helper DTOs
struct PatientSummaryResponse: Content {
    let patientId: String
    let latestTSH: Double
    let previousTSH: Double?
    let trendDirection: String
    let activeMedicationsCount: Int
    let labsCount: Int
}

struct ClinicianPatientSummary: Content {
    let patientId: String
    let name: String
    let latestTSH: Double
    let previousTSH: Double?
    let percentChange: Double
    let trendDirection: String
    let lastLabDate: String
    let reviewFlag: Bool
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

// MARK: - HTML Rendering Helpers
func dashboardResponse() -> Response {
    Response(
        status: .ok,
        headers: ["content-type": "text/html; charset=utf-8"],
        body: .init(string: DashboardRenderer.render(analyses: mealAnalysisStore.recent()))
    )
}

func debugDashboardResponse() -> Response {
    let logs = AuditLogger.shared.recentLogs()
    let logRows = logs.isEmpty
        ? "<tr><td colspan='5' class='empty'>No audit logs yet. Interact with the API or web portal.</td></tr>"
        : logs.map { log in
            "<tr><td>\(log.timestamp)</td><td><strong>\(log.actorUserId)</strong> (\(log.actorRole.rawValue))</td><td>\(log.patientId)</td><td>\(log.action)</td><td><span class='badge'>\(log.resourceType)</span></td></tr>"
        }.joined(separator: "\n")

    let html = """
    <!doctype html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>ThyroCare V3 Debug & Audit Portal</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; background: #0f172a; color: #f8fafc; padding: 30px; }
            .card { background: #1e293b; border-radius: 10px; padding: 24px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); border: 1px solid #334155; }
            h1 { color: #38bdf8; margin-top: 0; }
            p { color: #94a3b8; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 14px; }
            th, td { text-align: left; padding: 12px 10px; border-bottom: 1px solid #334155; }
            th { color: #38bdf8; font-size: 12px; text-transform: uppercase; }
            .badge { background: #0284c7; color: white; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: bold; }
            .empty { text-align: center; color: #64748b; padding: 20px; }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>ThyroCare V3 — Isolated Debug & System Health</h1>
            <p>Status: <strong style="color:#4ade80;">Active</strong> | Route: <code>/debug</code> | Services: Auth, RBAC, Trend Engine, Knowledge Base, Reports, Audit Logger</p>
            <h3>Recent System Audit Logs</h3>
            <table>
                <thead>
                    <tr><th>Timestamp</th><th>Actor</th><th>Target Patient</th><th>Action</th><th>Resource</th></tr>
                </thead>
                <tbody>
                    \(logRows)
                </tbody>
            </table>
        </div>
    </body>
    </html>
    """

    return Response(
        status: .ok,
        headers: ["content-type": "text/html; charset=utf-8"],
        body: .init(string: html)
    )
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
                    <p>Status: <strong>Ready</strong>. Dedicated debug route available at <a href="/debug">/debug</a>.</p>
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
                } else if name.contains("vitamin b") || name.contains("thiamin") || name.contains("riboflavin") || name.contains("niacin") || name.contains("folate") {
                    vitaminBTotal += value
                } else if name.contains("vitamin d") {
                    vitaminD = value
                }
            } else if name.contains("energy") || name.contains("calorie") {
                if calories == nil { calories = value }
            } else if name.contains("fiber") {
                fiber = value
            } else if name.contains("sugars") {
                sugar = value
            } else if name.contains("total lipid") || name.contains("fat") {
                fat = value
            } else if name.contains("potassium") {
                potassium = value
            }
        }

        if usdaFood.dataType?.lowercased().contains("foundation") == true || usdaFood.dataType?.lowercased().contains("survey") == true {
            produceScore += grams
        }

        details.append(
            USDANutritionDetail(
                detectedFood: detectedFood.name,
                estimatedGrams: grams,
                usdaSearchQuery: detectedFood.usdaSearchQuery,
                usdaDescription: usdaFood.description ?? "USDA entry",
                calories: calories,
                proteinGrams: protein,
                carbohydrateGrams: carbs,
                fiberGrams: fiber,
                sugarGrams: sugar,
                fatGrams: fat,
                potassiumMilligrams: potassium,
                vitaminCMilligrams: vitaminC,
                vitaminBMilligrams: vitaminBTotal > 0 ? vitaminBTotal : nil,
                vitaminDMicrograms: vitaminD
            )
        )
    }

    func normalized() -> NutritionSummary {
        var copy = self
        let totalMacroGrams = max(copy.proteinGrams + copy.carbGrams, 1)

        copy.proteinPercent = min(max(Int((copy.proteinGrams / totalMacroGrams) * 100), 10), 60)
        copy.carbsPercent = min(max(Int((copy.carbGrams / totalMacroGrams) * 100), 15), 75)
        copy.vitaminPercent = min(max(Int((copy.vitaminScore / 80.0) * 100), 10), 95)
        copy.producePercent = min(max(Int((copy.produceScore / 300.0) * 100), 10), 95)

        return copy
    }
}

private struct HormoneImpact {
    let tshDescription: String
    let t3Description: String
    let t4Description: String
    let tshPercentChange: Double
    let t3PercentChange: Double
    let t4PercentChange: Double
}

private enum HormoneImpactCalculator {
    static func calculate(nutrition: NutritionSummary) -> HormoneImpact {
        let proteinBonus = Double(nutrition.proteinPercent) * 0.04
        let vitaminBonus = Double(nutrition.vitaminPercent) * 0.03
        let produceBonus = Double(nutrition.producePercent) * 0.03

        let t3Change = min(max(-1.2 + proteinBonus + vitaminBonus, -3.0), 3.5)
        let t4Change = min(max(-0.8 + produceBonus + (proteinBonus * 0.5), -2.5), 3.0)
        let tshChange = min(max(0.9 - (t3Change * 0.45), -3.0), 4.0)

        let tshDesc = tshChange >= 0 ? "Potential slight TSH rise (+\(String(format: "%.1f", tshChange))%)" : "Potential slight TSH decrease (\(String(format: "%.1f", tshChange))%)"
        let t3Desc = t3Change >= 0 ? "Supports T3 conversion (+\(String(format: "%.1f", t3Change))%)" : "Lower T3 conversion support (\(String(format: "%.1f", t3Change))%)"
        let t4Desc = t4Change >= 0 ? "Favorable T4 stability (+\(String(format: "%.1f", t4Change))%)" : "Mild T4 reduction factor (\(String(format: "%.1f", t4Change))%)"

        return HormoneImpact(
            tshDescription: tshDesc,
            t3Description: t3Desc,
            t4Description: t4Desc,
            tshPercentChange: tshChange,
            t3PercentChange: t3Change,
            t4PercentChange: t4Change
        )
    }
}

private extension String {
    func extractJSONObject() -> String {
        guard let start = firstIndex(of: "{"),
              let end = lastIndex(of: "}") else {
            return self
        }

        return String(self[start...end])
    }
}

// MARK: - App Configuration Entrypoint
public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.views.use(.leaf)
    app.routes.defaultMaxBodySize = "16mb"

    @Sendable func servePublicHTML(req: Request, path: String) -> Response {
        let fullPath = app.directory.publicDirectory + path
        if FileManager.default.fileExists(atPath: fullPath),
           let data = FileManager.default.contents(atPath: fullPath) {
            return Response(status: .ok, headers: ["content-type": "text/html; charset=utf-8"], body: .init(data: data))
        }
        let fallbackPath = app.directory.publicDirectory + "index.html"
        if FileManager.default.fileExists(atPath: fallbackPath),
           let data = FileManager.default.contents(atPath: fallbackPath) {
            return Response(status: .ok, headers: ["content-type": "text/html; charset=utf-8"], body: .init(data: data))
        }
        return dashboardResponse()
    }

    // MARK: - Core Root & Health
    app.get { req -> Response in
        servePublicHTML(req: req, path: "index.html")
    }

    app.get("health") { _ in
        [
            "status": "ok",
            "service": "ThyroCareBackend",
            "version": "3.0.0",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Clinician Web App Static Routes
    app.get("clinician") { req -> Response in
        servePublicHTML(req: req, path: "clinician.html")
    }

    app.get("clinician", "**") { req -> Response in
        let uriPath = req.url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let htmlPath = uriPath + ".html"
        let publicHTML = app.directory.publicDirectory + htmlPath
        if FileManager.default.fileExists(atPath: publicHTML),
           let data = FileManager.default.contents(atPath: publicHTML) {
            return Response(status: .ok, headers: ["content-type": "text/html; charset=utf-8"], body: .init(data: data))
        }
        return servePublicHTML(req: req, path: "clinician.html")
    }

    app.get("family") { req -> Response in
        servePublicHTML(req: req, path: "family.html")
    }

    app.get("patient") { req -> Response in
        servePublicHTML(req: req, path: "patient.html")
    }

    app.get("providers") { req -> Response in
        servePublicHTML(req: req, path: "providers.html")
    }

    // MARK: - Debug & Telemetry Portal (SEPARATE LINK)
    app.get("debug") { _ -> Response in
        debugDashboardResponse()
    }

    app.get("debug", "") { _ -> Response in
        debugDashboardResponse()
    }

    app.get("dashboard") { req -> Response in
        servePublicHTML(req: req, path: "index.html")
    }

    app.get("dashboard", "") { req -> Response in
        servePublicHTML(req: req, path: "index.html")
    }

    // MARK: - Auth Routes
    app.post("auth", "login") { req async throws -> AuthResponse in
        struct LoginReq: Content { let email: String; let role: String? }
        let body = try req.content.decode(LoginReq.self)
        let role = UserRole(rawValue: body.role ?? "patient") ?? .patient
        let user = UserProfile(id: "P-1001", email: body.email, name: "Abhiraam Venigalla", role: role)
        return AuthResponse(token: "thyrocare_secure_token_\(UUID().uuidString)", user: user)
    }

    // MARK: - Patient Data & Longitudinal Labs
    app.get("patients", ":id", "summary") { req -> PatientSummaryResponse in
        let pid = req.parameters.get("id") ?? "P-1001"
        AuditLogger.shared.log(actorUserId: pid, actorRole: .patient, patientId: pid, resourceType: "PatientSummary", action: "VIEW_SUMMARY")
        let labs = storeEngine.getLabs(patientId: pid)
        let meds = storeEngine.getMedications(patientId: pid)
        let trend = ThyroidTrendEngine.analyze(patientId: pid, labs: labs)
        return PatientSummaryResponse(
            patientId: pid,
            latestTSH: trend.latestTSH,
            previousTSH: trend.previousTSH,
            trendDirection: trend.direction.rawValue,
            activeMedicationsCount: meds.count,
            labsCount: labs.count
        )
    }

    app.get("patients", ":id", "labs") { req -> [LabResultRecord] in
        let pid = req.parameters.get("id") ?? "P-1001"
        AuditLogger.shared.log(actorUserId: pid, actorRole: .patient, patientId: pid, resourceType: "LabResults", action: "VIEW_LABS")
        return storeEngine.getLabs(patientId: pid)
    }

    app.post("patients", ":id", "labs") { req async throws -> LabResultRecord in
        let pid = req.parameters.get("id") ?? "P-1001"
        struct AddLabInput: Content {
            let tsh: Double
            let freeT4: Double?
            let freeT3: Double?
            let labName: String?
            let testDate: String?
        }
        let input = try req.content.decode(AddLabInput.self)
        let record = LabResultRecord(
            patientId: pid,
            testDate: input.testDate ?? ISO8601DateFormatter().string(from: Date()).prefix(10).description,
            labName: input.labName ?? "Quest Diagnostics",
            tsh: input.tsh,
            freeT4: input.freeT4,
            freeT3: input.freeT3
        )
        storeEngine.addLab(patientId: pid, lab: record)
        AuditLogger.shared.log(actorUserId: pid, actorRole: .patient, patientId: pid, resourceType: "LabResults", action: "CREATE_LAB")
        return record
    }

    app.get("patients", ":id", "trends") { req -> ThyroidTrendAnalysis in
        let pid = req.parameters.get("id") ?? "P-1001"
        let labs = storeEngine.getLabs(patientId: pid)
        return ThyroidTrendEngine.analyze(patientId: pid, labs: labs)
    }

    app.get("patients", ":id", "timeline") { req -> [TimelineEvent] in
        let pid = req.parameters.get("id") ?? "P-1001"
        let labs = storeEngine.getLabs(patientId: pid)
        let meds = storeEngine.getMedications(patientId: pid)
        let foods = storeEngine.getFoodLogs(patientId: pid)

        var events: [TimelineEvent] = []
        labs.forEach { lab in
            events.append(TimelineEvent(patientId: pid, date: lab.testDate, category: "lab", title: "Laboratory Test (TSH \(lab.tsh))", summary: "TSH: \(lab.tsh) mIU/L | Lab: \(lab.labName)"))
        }
        meds.forEach { med in
            events.append(TimelineEvent(patientId: pid, date: med.startDate, category: "medication", title: "Medication Started (\(med.name))", summary: "\(med.name) \(med.dose) \(med.unit) - \(med.frequency)"))
        }
        foods.forEach { food in
            events.append(TimelineEvent(patientId: pid, date: food.timestamp.prefix(10).description, category: "food", title: "Meal Scanned (\(food.mealName))", summary: food.safetyDisclaimer))
        }

        return events.sorted { $0.date > $1.date }
    }

    app.get("patients", ":id", "clinical-summary") { req -> AICinicalSummary in
        let pid = req.parameters.get("id") ?? "P-1001"
        let labs = storeEngine.getLabs(patientId: pid)
        let meds = storeEngine.getMedications(patientId: pid)
        let foods = storeEngine.getFoodLogs(patientId: pid)
        return AISummarizerService.summarize(patientName: pid, labs: labs, meds: meds, foods: foods)
    }

    // MARK: - Medication Management
    app.get("patients", ":id", "medications") { req -> [MedicationRecord] in
        let pid = req.parameters.get("id") ?? "P-1001"
        return storeEngine.getMedications(patientId: pid)
    }

    app.post("patients", ":id", "medications") { req async throws -> MedicationRecord in
        let pid = req.parameters.get("id") ?? "P-1001"
        struct AddMedInput: Content {
            let name: String
            let dose: String
            let unit: String?
            let frequency: String?
        }
        let input = try req.content.decode(AddMedInput.self)
        let med = MedicationRecord(
            patientId: pid,
            name: input.name,
            genericName: input.name,
            dose: input.dose,
            unit: input.unit ?? "mcg",
            frequency: input.frequency ?? "Daily",
            startDate: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
            interactionNotes: ThyroidKnowledgeBase.inspectMedication(input.name)
        )
        storeEngine.addMedication(patientId: pid, med: med)
        return med
    }

    // MARK: - Clinician Web App Portal Endpoints
    app.get("clinician", "patients") { req -> [ClinicianPatientSummary] in
        AuditLogger.shared.log(actorUserId: "C-2001", actorRole: .clinician, patientId: "ALL", resourceType: "ClinicianDashboard", action: "VIEW_PATIENT_LIST")
        let patients = storeEngine.getAllPatientsForClinician(clinicianId: "C-2001")
        return patients.map { p in
            let labs = storeEngine.getLabs(patientId: p.id)
            let trend = ThyroidTrendEngine.analyze(patientId: p.id, labs: labs)
            let events = storeEngine.getReviewEvents(patientId: p.id)
            return ClinicianPatientSummary(
                patientId: p.id,
                name: p.name,
                latestTSH: trend.latestTSH,
                previousTSH: trend.previousTSH,
                percentChange: trend.percentChange,
                trendDirection: trend.direction.rawValue,
                lastLabDate: labs.last?.testDate ?? "None",
                reviewFlag: !events.filter { $0.status == "pending" }.isEmpty
            )
        }
    }

    app.get("clinician", "patients", ":id", "review-events") { req -> [ClinicalReviewEvent] in
        let pid = req.parameters.get("id") ?? "P-1002"
        return storeEngine.getReviewEvents(patientId: pid)
    }

    app.post("clinician", "review-events", ":id", "review") { req async throws -> HTTPStatus in
        let eventId = req.parameters.get("id") ?? ""
        struct ReviewInput: Content {
            let status: String
            let clinicianPrivateNotes: String?
            let patientVisibleNotes: String?
        }
        let input = try req.content.decode(ReviewInput.self)
        storeEngine.updateReviewEvent(eventId: eventId, status: input.status, privateNotes: input.clinicianPrivateNotes, publicNotes: input.patientVisibleNotes)
        return .ok
    }

    // MARK: - Family Portal Endpoints
    app.get("family-links") { req -> [FamilyLinkRecord] in
        return storeEngine.getFamilyLinks(ownerId: "P-1001")
    }

    app.post("family-links") { req async throws -> FamilyLinkRecord in
        struct AddFamilyLinkInput: Content {
            let linkedUserId: String
            let linkedUserName: String
            let relationship: String
            let permissionLevel: String?
        }
        let input = try req.content.decode(AddFamilyLinkInput.self)
        let link = FamilyLinkRecord(
            ownerUserId: "P-1001",
            linkedUserId: input.linkedUserId,
            linkedUserName: input.linkedUserName,
            relationship: input.relationship,
            permissionLevel: FamilyPermissionLevel(rawValue: input.permissionLevel ?? "VIEW_SUMMARY") ?? .viewSummary
        )
        storeEngine.addFamilyLink(link: link)
        return link
    }

    app.delete("family-links", ":id") { req -> HTTPStatus in
        let linkId = req.parameters.get("id") ?? ""
        storeEngine.deleteFamilyLink(linkId: linkId)
        return .ok
    }

    // MARK: - Clinician Consent Endpoints
    app.get("patients", ":id", "clinician-access") { req -> [ClinicianConsentRecord] in
        let pid = req.parameters.get("id") ?? "P-1001"
        return storeEngine.getConsents(patientId: pid)
    }

    app.post("patients", ":id", "clinician-access") { req async throws -> ClinicianConsentRecord in
        let pid = req.parameters.get("id") ?? "P-1001"
        struct ConsentInput: Content {
            let clinicianId: String
            let clinicianName: String
            let permissionLevel: String?
        }
        let input = try req.content.decode(ConsentInput.self)
        let consent = ClinicianConsentRecord(
            patientId: pid,
            clinicianId: input.clinicianId,
            clinicianName: input.clinicianName,
            permissionLevel: ClinicianPermissionLevel(rawValue: input.permissionLevel ?? "SUMMARY_ONLY") ?? .summaryOnly
        )
        storeEngine.addConsent(patientId: pid, consent: consent)
        return consent
    }

    app.delete("patients", ":id", "clinician-access", ":clinicianId") { req -> HTTPStatus in
        let pid = req.parameters.get("id") ?? "P-1001"
        let cid = req.parameters.get("clinicianId") ?? ""
        storeEngine.revokeConsent(patientId: pid, clinicianId: cid)
        return .ok
    }

    // MARK: - Provider / Endocrinologist Locator
    app.get("providers", "endocrinologists") { req -> [EndocrinologistProvider] in
        let query: String? = req.query["query"]
        return ProviderSearchService.searchEndocrinologists(query: query)
    }

    // MARK: - Reports Generator & Sharing
    app.post("patients", ":id", "reports") { req async throws -> GeneratedReportRecord in
        let pid = req.parameters.get("id") ?? "P-1001"
        let labs = storeEngine.getLabs(patientId: pid)
        let meds = storeEngine.getMedications(patientId: pid)
        let foods = storeEngine.getFoodLogs(patientId: pid)
        let trend = ThyroidTrendEngine.analyze(patientId: pid, labs: labs)
        let ai = AISummarizerService.summarize(patientName: "Abhiraam Venigalla", labs: labs, meds: meds, foods: foods)

        let report = ReportGeneratorService.generate(
            patientId: pid,
            patientName: "Abhiraam Venigalla",
            labs: labs,
            meds: meds,
            trend: trend,
            aiSummary: ai
        )
        storeEngine.saveReport(report: report)
        AuditLogger.shared.log(actorUserId: pid, actorRole: .patient, patientId: pid, resourceType: "Report", action: "GENERATE_REPORT")
        return report
    }

    app.get("reports", ":id") { req async throws -> Response in
        let rid = req.parameters.get("id") ?? ""
        guard let report = storeEngine.getReport(reportId: rid) else {
            throw Abort(.notFound, reason: "Report not found or token expired.")
        }
        return Response(
            status: .ok,
            headers: ["content-type": "text/html; charset=utf-8"],
            body: .init(string: report.htmlReport)
        )
    }

    // MARK: - Meal Ingestion & Analysis
    app.post("analyze-meal") { req async throws -> MealAnalysisResponse in
        let request = try req.content.decode(AnalyzeMealRequest.self)
        let imagePath = try saveUploadedMealImage(request, app: req.application, logger: req.logger)
        let service = MealAnalysisPipeline(client: req.client, logger: req.logger)
        let response = try await service.analyze(request)
        mealAnalysisStore.add(response, imagePath: imagePath)

        let (compounds, interp) = ThyroidKnowledgeBase.inspectFood(response.name)
        let foodItem = IdentifiedFoodItem(food: response.name, confidence: response.confidence, identifiedCompounds: compounds, clinicalInterpretation: interp)
        let foodRecord = FoodLogRecord(patientId: "P-1001", mealName: response.name, imageURL: imagePath, identifiedFoods: [foodItem])
        storeEngine.addFoodLog(patientId: "P-1001", food: foodRecord)

        req.logger.info("Meal analysis completed: \(response.name), confidence \(Int(response.confidence * 100))%")
        return response
    }

    app.get("analyses") { _ in
        mealAnalysisStore.recent()
    }
}
