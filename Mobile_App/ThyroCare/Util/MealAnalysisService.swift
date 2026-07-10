import Foundation
import UIKit
import Vision

enum MealAnalysisServiceError: Error {
    case invalidBaseURL
    case invalidImageData
    case badResponse
}

struct MealAnalysisService {
    static let shared = MealAnalysisService()

    private var baseURL: URL {
        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "ThyroCareBackendBaseURL") as? String,
           let url = URL(string: configuredURL) {
            return url
        }

        return URL(string: "http://127.0.0.1:8080")!
    }

    func analyze(imageData: Data, mimeType: String = "image/jpeg") async throws -> MealAnalysis {
        let url = baseURL.appending(path: "analyze-meal")
        let uploadImageData = try compressedJPEGData(from: imageData)
        let localClassifications = try? LocalFoodImageClassifier.classify(imageData: uploadImageData)
        let requestBody = AnalyzeMealRequest(
            imageBase64: uploadImageData.base64EncodedString(),
            mimeType: "image/jpeg",
            localClassifications: localClassifications
        )
        let encodedBody = try JSONEncoder().encode(requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedBody

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw MealAnalysisServiceError.badResponse
        }

        let backendMeal = try JSONDecoder().decode(MealAnalysis.self, from: data)
        return MealThyroidImpactCalculator.applyLocalImpact(to: backendMeal)
    }

    private func compressedJPEGData(from imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw MealAnalysisServiceError.invalidImageData
        }

        let maxSide: CGFloat = 512
        let largestSide = max(image.size.width, image.size.height)
        let scale = largestSide > maxSide ? maxSide / largestSide : 1
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let compressedData = resizedImage.jpegData(compressionQuality: 0.55) else {
            throw MealAnalysisServiceError.invalidImageData
        }

        return compressedData
    }

    static func userFacingMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .timedOut:
                return "Could not reach the ThyroCare backend. Make sure the server is running and the backend URL points to your Mac."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }

        if case MealAnalysisServiceError.badResponse = error {
            return "The backend responded with an error. Check the backend Terminal logs for OpenAI or USDA failures."
        }

        return "Meal analysis failed: \(error.localizedDescription)"
    }
}

private struct AnalyzeMealRequest: Encodable {
    let imageBase64: String?
    let mimeType: String
    let localClassifications: [LocalFoodClassification]?
}

struct LocalFoodClassification: Codable {
    let name: String
    let confidence: Double
    let usdaSearchQuery: String
}

enum LocalFoodImageClassifier {
    static func classify(imageData: Data) throws -> [LocalFoodClassification] {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw MealAnalysisServiceError.invalidImageData
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation)
        try handler.perform([request])

        let classifications = (request.results ?? [])
            .filter { $0.confidence >= 0.08 }
            .compactMap { observation -> LocalFoodClassification? in
                let query = foodSearchQuery(for: observation.identifier)
                guard !query.isEmpty else { return nil }

                return LocalFoodClassification(
                    name: displayName(for: query),
                    confidence: Double(observation.confidence),
                    usdaSearchQuery: query
                )
            }

        return Array(classifications.prefix(5))
    }

    private static func foodSearchQuery(for identifier: String) -> String {
        let normalized = identifier
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        let directFoodTerms = [
            "apple", "banana", "berry", "bread", "burger", "cake", "cheese", "chicken",
            "coffee", "corn", "egg", "fish", "fruit", "grape", "meat", "milk", "noodle",
            "orange", "pasta", "pizza", "potato", "rice", "salad", "sandwich", "soup",
            "steak", "toast", "vegetable", "yogurt"
        ]

        if let term = directFoodTerms.first(where: { normalized.contains($0) }) {
            return term
        }

        if normalized.contains("dish") || normalized.contains("meal") || normalized.contains("plate") || normalized.contains("food") {
            return "mixed meal"
        }

        return ""
    }

    private static func displayName(for query: String) -> String {
        query
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}

enum MealImageFactory {
    static func placeholderJPEGData() -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
        let image = renderer.image { context in
            UIColor(red: 0.87, green: 0.96, blue: 0.91, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 640, height: 640))

            UIColor(red: 0.05, green: 0.58, blue: 0.58, alpha: 1).setFill()
            UIBezierPath(ovalIn: CGRect(x: 130, y: 130, width: 380, height: 380)).fill()

            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 210, y: 210, width: 220, height: 220)).fill()
        }

        return image.jpegData(compressionQuality: 0.82)
    }
}

enum MealThyroidImpactCalculator {
    static func applyLocalImpact(to meal: MealAnalysis) -> MealAnalysis {
        let normalized = normalizedFoodPercentages(
            protein: meal.protein,
            carbs: meal.carbs,
            vitamins: meal.vitamins,
            produce: meal.produce
        )
        let impact = calculate(
            protein: normalized.protein,
            carbs: normalized.carbs,
            vitamins: normalized.vitamins,
            produce: normalized.produce
        )

        return MealAnalysis(
            name: meal.name,
            timeLabel: meal.timeLabel,
            confidence: meal.confidence,
            protein: normalized.protein,
            carbs: normalized.carbs,
            vitamins: normalized.vitamins,
            produce: normalized.produce,
            tshImpact: impact.tshDescription,
            t3Impact: impact.t3Description,
            t4Impact: impact.t4Description,
            tshPercentChange: impact.tshPercentChange,
            t3PercentChange: impact.t3PercentChange,
            t4PercentChange: impact.t4PercentChange
        )
    }

    private static func normalizedFoodPercentages(
        protein: Int,
        carbs: Int,
        vitamins: Int,
        produce: Int
    ) -> (protein: Int, carbs: Int, vitamins: Int, produce: Int) {
        let rawValues = [protein, carbs, vitamins, produce].map { max($0, 0) }
        let total = rawValues.reduce(0, +)

        guard total > 0 else {
            return (25, 35, 20, 20)
        }

        var percentages = rawValues.map { Int((Double($0) / Double(total) * 100).rounded()) }
        let correction = 100 - percentages.reduce(0, +)
        if let largestIndex = percentages.indices.max(by: { percentages[$0] < percentages[$1] }) {
            percentages[largestIndex] += correction
        }

        return (percentages[0], percentages[1], percentages[2], percentages[3])
    }

    private static func calculate(
        protein: Int,
        carbs: Int,
        vitamins: Int,
        produce: Int
    ) -> ThyroidImpact {
        let features = ThyroidNutritionFeatureVector(
            protein: Double(protein),
            carbs: Double(carbs),
            vitamins: Double(vitamins),
            produce: Double(produce)
        )

        let tsh = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.tsh).rounded(to: 1)
        let t3 = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.t3).rounded(to: 1)
        let t4 = ThyroidNutritionWeights.score(features, weights: ThyroidNutritionWeights.t4).rounded(to: 1)

        return ThyroidImpact(
            tshDescription: tsh <= 0 ? "Likely support" : "May increase",
            t3Description: t3 >= 0 ? "Support" : "May dip",
            t4Description: t4 >= 0 ? "Support" : "May dip",
            tshPercentChange: tsh,
            t3PercentChange: t3,
            t4PercentChange: t4
        )
    }
}

private struct ThyroidNutritionFeatureVector {
    let protein: Double
    let carbs: Double
    let vitamins: Double
    let produce: Double
}

private struct ThyroidNutritionWeightSet {
    let protein: Double
    let carbs: Double
    let vitamins: Double
    let produce: Double
}

private enum ThyroidNutritionWeights {
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

private struct ThyroidImpact {
    let tshDescription: String
    let t3Description: String
    let t4Description: String
    let tshPercentChange: Double
    let t3PercentChange: Double
    let t4PercentChange: Double
}

private extension Double {
    func rounded(to places: Int) -> Double {
        let multiplier = Foundation.pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
