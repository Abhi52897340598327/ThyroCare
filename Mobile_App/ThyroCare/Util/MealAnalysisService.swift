import Foundation
import UIKit

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
        let requestBody = AnalyzeMealRequest(imageBase64: imageData.base64EncodedString(), mimeType: mimeType)
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

        return try JSONDecoder().decode(MealAnalysis.self, from: data)
    }
}

private struct AnalyzeMealRequest: Encodable {
    let imageBase64: String
    let mimeType: String
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
