import Foundation
import Vapor

struct MealPhotoUpload: Content {
    let imageBase64: String
}

struct MealPhotoResponse: Content {
    let mealID: String
    let mimeType: String
    let imageBase64: String
}

/// Strip JPEG metadata blocks on the server as well as normalizing on clients.
/// Reject malformed marker lengths; do not accept arbitrary files with a .jpg extension.
enum CareJPEG {
    static func sanitized(_ data: Data) throws -> Data {
        let bytes = [UInt8](data)
        guard bytes.count >= 4, bytes.count <= 8_000_000,
              bytes[0] == 0xff, bytes[1] == 0xd8,
              bytes[bytes.count - 2] == 0xff, bytes[bytes.count - 1] == 0xd9 else {
            throw Abort(.badRequest, reason: "Use a JPEG photo under 8 MB.")
        }
        var result: [UInt8] = [0xff, 0xd8]
        var offset = 2
        var hasFrame = false
        while offset + 3 < bytes.count {
            guard bytes[offset] == 0xff else { throw Abort(.badRequest, reason: "Invalid photo encoding.") }
            let marker = bytes[offset + 1]
            let length = Int(bytes[offset + 2]) * 256 + Int(bytes[offset + 3])
            guard length >= 2, offset + length + 2 <= bytes.count else { throw Abort(.badRequest, reason: "Incomplete photo.") }
            if marker == 0xda {
                guard hasFrame else { throw Abort(.badRequest, reason: "Missing image frame.") }
                result.append(contentsOf: bytes[offset...])
                return Data(result)
            }
            if [0xc0, 0xc1, 0xc2].contains(marker) {
                guard length >= 8 else { throw Abort(.badRequest) }
                let height = Int(bytes[offset + 5]) * 256 + Int(bytes[offset + 6])
                let width = Int(bytes[offset + 7]) * 256 + Int(bytes[offset + 8])
                guard height > 0, width > 0, height <= 8192, width <= 8192 else { throw Abort(.badRequest, reason: "Photo dimensions are unsupported.") }
                hasFrame = true
            }
            // APP1/EXIF/XMP, APP13/IPTC and COM can contain GPS or other incidental metadata.
            if marker != 0xe1 && marker != 0xed && marker != 0xfe {
                result.append(contentsOf: bytes[offset..<(offset + length + 2)])
            }
            offset += length + 2
        }
        throw Abort(.badRequest, reason: "Incomplete JPEG photo.")
    }
}
