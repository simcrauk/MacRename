import Foundation
import ImageIO

/// Extracts EXIF and XMP metadata from image files using CGImageSource.
public enum MetadataExtractor {

    /// Extracts metadata patterns from an image file.
    /// Returns a dictionary mapping pattern names to their string values.
    public static func extractPatterns(from url: URL, exif: Bool, xmp: Bool) -> [String: String] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return [:]
        }

        var patterns: [String: String] = [:]

        if exif {
            extractEXIF(from: source, into: &patterns)
        }

        if xmp {
            extractXMP(from: source, into: &patterns)
        }

        return patterns
    }

    // MARK: - EXIF Extraction

    private static func extractEXIF(from source: CGImageSource, into patterns: inout [String: String]) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return
        }

        // Top-level TIFF properties
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            if let make = tiff[kCGImagePropertyTIFFMake as String] as? String {
                patterns["CAMERA_MAKE"] = make.trimmingCharacters(in: .whitespaces)
            }
            if let model = tiff[kCGImagePropertyTIFFModel as String] as? String {
                patterns["CAMERA_MODEL"] = model.trimmingCharacters(in: .whitespaces)
            }
            if let artist = tiff[kCGImagePropertyTIFFArtist as String] as? String {
                patterns["AUTHOR"] = artist
            }
            if let copyright = tiff[kCGImagePropertyTIFFCopyright as String] as? String {
                patterns["COPYRIGHT"] = copyright
            }
            if let orientation = tiff[kCGImagePropertyTIFFOrientation as String] {
                patterns["ORIENTATION"] = "\(orientation)"
            }
        }

        // EXIF dictionary
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let iso = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let first = iso.first {
                patterns["ISO"] = "\(first)"
            }
            if let fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double {
                patterns["APERTURE"] = String(format: "f/%.1f", fNumber)
            }
            if let exposure = exif[kCGImagePropertyExifExposureTime as String] as? Double {
                if exposure < 1 {
                    patterns["SHUTTER"] = "1/\(Int(round(1.0 / exposure)))"
                } else {
                    patterns["SHUTTER"] = String(format: "%.1f", exposure)
                }
            }
            if let focal = exif[kCGImagePropertyExifFocalLength as String] as? Double {
                patterns["FOCAL"] = String(format: "%.0fmm", focal)
            }
            if let flash = exif[kCGImagePropertyExifFlash as String] as? Int {
                patterns["FLASH"] = (flash & 1) != 0 ? "On" : "Off"
            }
            if let bias = exif[kCGImagePropertyExifExposureBiasValue as String] as? Double {
                patterns["EXPOSURE_BIAS"] = String(format: "%+.1f", bias)
            }
            if let colorSpace = exif[kCGImagePropertyExifColorSpace as String] as? Int {
                patterns["COLOR_SPACE"] = colorSpace == 1 ? "sRGB" : "\(colorSpace)"
            }
            if let lens = exif[kCGImagePropertyExifLensModel as String] as? String {
                patterns["LENS"] = lens
            }

            // Date taken
            if let dateStr = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                parseDateComponents(dateStr, prefix: "DATE_TAKEN", into: &patterns)
            }
        }

        // Image dimensions
        if let width = properties[kCGImagePropertyPixelWidth as String] as? Int {
            patterns["WIDTH"] = "\(width)"
        }
        if let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
            patterns["HEIGHT"] = "\(height)"
        }

        // GPS
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String {
                let signed = latRef == "S" ? -lat : lat
                patterns["LATITUDE"] = String(format: "%.6f", signed)
            }
            if let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                let signed = lonRef == "W" ? -lon : lon
                patterns["LONGITUDE"] = String(format: "%.6f", signed)
            }
            if let alt = gps[kCGImagePropertyGPSAltitude as String] as? Double {
                patterns["ALTITUDE"] = String(format: "%.1fm", alt)
            }
        }
    }

    // MARK: - XMP Extraction

    private static func extractXMP(from source: CGImageSource, into patterns: inout [String: String]) {
        // CGImageSource doesn't have a dedicated XMP dictionary, but many XMP fields
        // are mapped into standard property dictionaries. We also check for IPTC.
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return
        }

        // IPTC often contains XMP-equivalent fields
        if let iptc = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            if let creator = iptc[kCGImagePropertyIPTCCreatorContactInfo as String] as? String {
                patterns["CREATOR"] = creator
            }
            if let rights = iptc[kCGImagePropertyIPTCRightsUsageTerms as String] as? String {
                patterns["RIGHTS"] = rights
            }
            if let title = iptc[kCGImagePropertyIPTCObjectName as String] as? String {
                patterns["TITLE"] = title
            }
            if let description = iptc[kCGImagePropertyIPTCCaptionAbstract as String] as? String {
                patterns["DESCRIPTION"] = description
            }
            if let keywords = iptc[kCGImagePropertyIPTCKeywords as String] as? [String] {
                patterns["SUBJECT"] = keywords.joined(separator: ", ")
            }
        }

        // TIFF for creator tool
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            if let software = tiff[kCGImagePropertyTIFFSoftware as String] as? String {
                patterns["CREATOR_TOOL"] = software
            }
            // Reuse author/copyright from TIFF if not already set
            if patterns["AUTHOR"] == nil, let artist = tiff[kCGImagePropertyTIFFArtist as String] as? String {
                patterns["AUTHOR"] = artist
            }
            if patterns["COPYRIGHT"] == nil, let copyright = tiff[kCGImagePropertyTIFFCopyright as String] as? String {
                patterns["COPYRIGHT"] = copyright
            }
        }

        // XMP create date from EXIF digitized date
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let dateStr = exif[kCGImagePropertyExifDateTimeDigitized as String] as? String {
                parseDateComponents(dateStr, prefix: "CREATE_DATE", into: &patterns)
            }
        }
    }

    // MARK: - Date Parsing

    /// Parses EXIF date string "YYYY:MM:DD HH:mm:SS" into individual pattern components.
    private static func parseDateComponents(
        _ dateString: String,
        prefix: String,
        into patterns: inout [String: String]
    ) {
        // EXIF date format: "2024:03:15 14:30:45"
        let parts = dateString.split(separator: " ")
        guard let datePart = parts.first else { return }

        let dateComponents = datePart.split(separator: ":")
        if dateComponents.count >= 3 {
            let year = String(dateComponents[0])
            let month = String(dateComponents[1])
            let day = String(dateComponents[2])

            patterns["\(prefix)_YYYY"] = year
            patterns["\(prefix)_YY"] = String(year.suffix(2))
            patterns["\(prefix)_MM"] = month
            patterns["\(prefix)_DD"] = day
        }

        if parts.count >= 2 {
            let timeComponents = parts[1].split(separator: ":")
            if timeComponents.count >= 3 {
                patterns["\(prefix)_HH"] = String(timeComponents[0])
                patterns["\(prefix)_mm"] = String(timeComponents[1])
                patterns["\(prefix)_SS"] = String(timeComponents[2])
            }
        }
    }
}
