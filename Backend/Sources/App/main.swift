import Foundation
import Vapor
import Leaf

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

    app.get("health") { _ in
        ["status": "ok", "service": "ThyroCareBackend"]
    }

    app.post("analyze-meal") { req async throws -> MealAnalysisResponse in
        let request = try req.content.decode(AnalyzeMealRequest.self)
        let service = MealAnalysisPipeline(client: req.client, logger: req.logger)
        return try await service.analyze(request)
    }

    app.get("dashboard") { req async throws -> View in
        try await req.view.render("dashboard", [
            "title": "ThyroCare Backend",
            "status": "Ready",
            "endpoint": "/analyze-meal"
        ])
    }
}

struct AnalyzeMealRequest: Content {
    let imageBase64: String
    let mimeType: String?
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

struct MealAnalysisPipeline {
    let client: Client
    let logger: Logger

    func analyze(_ request: AnalyzeMealRequest) async throws -> MealAnalysisResponse {
        let vision = try await identifyFoods(request)
        let nutrition = try await nutritionSummary(for: vision.foods)
        return buildResponse(vision: vision, nutrition: nutrition)
    }

    private func identifyFoods(_ request: AnalyzeMealRequest) async throws -> VisionAnalysis {
        guard let apiKey = Environment.get("OPENAI_API_KEY"), !apiKey.isEmpty, apiKey != "replace_me" else {
            throw Abort(.internalServerError, reason: "OPENAI_API_KEY is missing")
        }

        let model = Environment.get("OPENAI_MODEL") ?? "gpt-4.1-mini"
        let mimeType = request.mimeType ?? "image/jpeg"
        let dataURL = "data:\(mimeType);base64,\(request.imageBase64)"
        let prompt = """
        Identify the visible foods and estimate portions in grams.
        Return only compact JSON with this exact shape:
        {"mealName":"string","confidence":0.0,"foods":[{"name":"string","estimatedGrams":100,"usdaSearchQuery":"string"}]}
        Confidence must be between 0 and 1. Use USDA-friendly search terms.
        """

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
            throw Abort(.badGateway, reason: "OpenAI meal analysis failed")
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

            summary.add(food: match, grams: food.estimatedGrams)
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
            t4PercentChange: hormone.t4PercentChange
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

struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable {
    let description: String?
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

    var proteinPercent = 25
    var carbsPercent = 35
    var vitaminPercent = 20
    var producePercent = 20

    mutating func add(food: USDAFood, grams: Double) {
        let scale = max(grams, 1) / 100.0

        for nutrient in food.foodNutrients {
            let name = nutrient.nutrientName?.lowercased() ?? ""
            let value = (nutrient.value ?? 0) * scale

            if name.contains("protein") {
                proteinGrams += value
            } else if name.contains("carbohydrate") {
                carbGrams += value
            } else if name.contains("vitamin") {
                vitaminScore += value
            } else if name.contains("fiber") || name.contains("folate") || name.contains("potassium") {
                produceScore += value
            }
        }
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
        let proteinSupport = Double(nutrition.proteinPercent) / 100.0
        let carbLoad = Double(nutrition.carbsPercent) / 100.0
        let micronutrientSupport = Double(nutrition.vitaminPercent + nutrition.producePercent) / 100.0

        let tsh = ((carbLoad * 4.0) - (proteinSupport * 2.2) - (micronutrientSupport * 2.5)).rounded(to: 1)
        let t3 = ((proteinSupport * 4.0) + (micronutrientSupport * 2.2) - (carbLoad * 1.5)).rounded(to: 1)
        let t4 = ((micronutrientSupport * 3.1) + (proteinSupport * 1.2) - (carbLoad * 1.0)).rounded(to: 1)

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
