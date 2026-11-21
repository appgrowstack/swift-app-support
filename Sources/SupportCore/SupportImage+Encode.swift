import Foundation
import ImageIO
import UniformTypeIdentifiers

extension SupportImage {
    /// The server's limit for one image.
    public static let maxBytes = 5_000_000

    /// Re-encodes any image (a screenshot, a HEIC photo) as a JPEG whose longest side is at most
    /// `maxPixels`, under 5 MB. Location and other metadata are dropped. `nil` if it isn't an image.
    public static func jpeg(from data: Data, maxPixels: Int = 2048) -> SupportImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        for quality in [0.8, 0.6, 0.4] {
            let out = NSMutableData()
            guard let dest = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
            CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
            guard CGImageDestinationFinalize(dest) else { return nil }
            if out.length <= maxBytes { return SupportImage(data: out as Data, contentType: "image/jpeg") }
        }
        return nil
    }
}
