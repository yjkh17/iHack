import Foundation
import AppKit

// MARK: - Asset Extraction Engine

class CarAssetExtractor {
    
    static func extractAssets(from url: URL) async throws -> [CarAsset] {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Method 1: Try our enhanced native Swift .car parsing
        let assets = try await extractAssetsNatively(from: url, to: tempDir)
        if !assets.isEmpty {
            // Get metadata for better asset names and details
            let metadataAssets = await getAssetUtilMetadata(url)
            
            // Combine extracted assets with metadata for better names
            return combineExtractedWithMetadata(extracted: assets, metadata: metadataAssets)
        }
        
        // Method 2: If extraction fails, show metadata-only with placeholders
        let metadataAssets = await getAssetUtilMetadata(url)
        if !metadataAssets.isEmpty {
            return metadataAssets.map { metadataAsset in
                CarAsset(
                    name: metadataAsset.name,
                    type: metadataAsset.type,
                    size: metadataAsset.size,
                    scale: metadataAsset.scale,
                    url: nil,
                    thumbnail: nil,
                    isIconSet: false
                )
            }
        }
        
        // Method 3: Basic analysis fallback
        return try await createBasicAssetInfo(url)
    }
    
    private static func extractAssetsNatively(from url: URL, to tempDir: URL) async throws -> [CarAsset] {
        let data = try Data(contentsOf: url)
        
        // Try multiple extraction approaches
        var assets: [CarAsset] = []
        
        // Method 1: Use our existing parser
        let parser = CarFileParser(data: data)
        do {
            let carFile = try parser.parse()
            for asset in carFile.assets {
                let fileName = "\(asset.name).\(asset.fileExtension)"
                let assetURL = tempDir.appendingPathComponent(fileName)
                
                try asset.data.write(to: assetURL)
                
                var thumbnail: NSImage?
                if asset.type == .image {
                    // Create thumbnail safely without Sendable issues
                    thumbnail = createValidatedNSImage(from: asset.data)
                    if thumbnail != nil {
                        print(" Validated thumbnail created for \(fileName): \(thumbnail!.size)")
                    } else {
                        thumbnail = createValidatedNSImage(fromFile: assetURL)
                        if thumbnail != nil {
                            print(" File-based validated thumbnail created for \(fileName): \(thumbnail!.size)")
                        } else {
                            print(" Failed to create thumbnail for \(fileName)")
                            let firstBytes = asset.data.prefix(16)
                            let hex = firstBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                            print("   - Data signature: \(hex)")
                            print("   - Data size: \(asset.data.count) bytes")
                        }
                    }
                }
                
                let carAsset = CarAsset(
                    name: fileName,
                    type: asset.type,
                    size: ByteCountFormatter.string(fromByteCount: Int64(asset.data.count), countStyle: .file),
                    scale: asset.scale,
                    url: assetURL,
                    thumbnail: thumbnail,
                    isIconSet: false
                )
                
                assets.append(carAsset)
            }
        } catch {
            print("CarFileParser failed: \(error)")
        }
        
        // Method 2: Direct binary extraction (more aggressive)
        let directAssets = try await extractAssetsDirect(from: data, to: tempDir)
        assets.append(contentsOf: directAssets)
        
        return assets
    }
    
    private static func extractAssetsDirect(from data: Data, to tempDir: URL) async throws -> [CarAsset] {
        var assets: [CarAsset] = []
        var assetIndex = 0
        
        let signatures: [(signature: [UInt8], type: CarAsset.AssetType, ext: String)] = [
            ([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], .image, "png"),
            ([0x89, 0x50, 0x4E, 0x47], .image, "png"),
            ([0xFF, 0xD8, 0xFF, 0xE0], .image, "jpg"),
            ([0xFF, 0xD8, 0xFF, 0xE1], .image, "jpg"),
            ([0xFF, 0xD8, 0xFF, 0xDB], .image, "jpg"),
            ([0xFF, 0xD8, 0xFF, 0xEE], .image, "jpg"),
            ([0x25, 0x50, 0x44, 0x46], .pdf, "pdf"),
            ([0x41, 0x54, 0x58, 0x4E], .image, "atx"),
            ([0x48, 0x45, 0x49, 0x43], .image, "heic"),
            ([0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63], .image, "heic"),
            ([0x62, 0x76, 0x78, 0x32], .image, "bvx2"),
            ([0x64, 0x65, 0x65, 0x70], .image, "deep"),
            ([0x3C, 0x3F, 0x78, 0x6D, 0x6C], .image, "svg"), // <?xml
            ([0x3C, 0x73, 0x76, 0x67], .image, "svg"), // <svg
        ]
        
        for (signature, type, ext) in signatures {
            let signatureData = Data(signature)
            var searchStart = data.startIndex
            
            while searchStart < data.endIndex {
                guard let range = data.range(of: signatureData, in: searchStart..<data.endIndex) else {
                    break
                }
                
                let startOffset = range.lowerBound
                let endOffset = findAssetEndImproved(from: startOffset, for: type, in: data)
                
                if endOffset > startOffset {
                    let assetData = data.subdata(in: startOffset..<endOffset)
                    
                    if assetData.count >= 100 {
                        let fileName = "extracted_\(assetIndex).\(ext)"
                        let assetURL = tempDir.appendingPathComponent(fileName)
                        
                        try assetData.write(to: assetURL)
                        
                        var thumbnail: NSImage?
                        if type == .image {
                            // Create thumbnail safely without Sendable issues
                            thumbnail = createValidatedNSImage(from: assetData)
                            if thumbnail != nil {
                                print(" Validated thumbnail created for \(fileName): \(thumbnail!.size)")
                            } else {
                                thumbnail = createValidatedNSImage(fromFile: assetURL)
                                if thumbnail != nil {
                                    print(" File-based validated thumbnail created for \(fileName): \(thumbnail!.size)")
                                } else {
                                    print(" Failed to create thumbnail for \(fileName)")
                                    let firstBytes = assetData.prefix(16)
                                    let hex = firstBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                                    print("   - Data signature: \(hex)")
                                    print("   - Data size: \(assetData.count) bytes")
                                }
                            }
                        }
                        
                        let asset = CarAsset(
                            name: fileName,
                            type: type,
                            size: ByteCountFormatter.string(fromByteCount: Int64(assetData.count), countStyle: .file),
                            scale: determineScaleFromContext(at: startOffset, in: data),
                            url: assetURL,
                            thumbnail: thumbnail,
                            isIconSet: false
                        )
                        
                        assets.append(asset)
                        assetIndex += 1
                    }
                }
                
                searchStart = range.upperBound
            }
        }
        
        let alternativeAssets = try await extractCompressedAssets(from: data, to: tempDir, startIndex: assetIndex)
        assets.append(contentsOf: alternativeAssets)
        
        return assets
    }
    
    private static func createValidatedNSImage(from data: Data) -> NSImage? {
        // Handle SVG files specially
        if data.starts(with: [0x3C, 0x3F, 0x78, 0x6D, 0x6C]) ||
           data.starts(with: [0x3C, 0x73, 0x76, 0x67]) ||
           String(data: data.prefix(100), encoding: .utf8)?.contains("<svg") == true {
            // Try to create NSImage from SVG data
            if let nsImage = NSImage(data: data) {
                return nsImage.isValid ? nsImage : nil
            }
            return nil
        }
        
        // Try to create image without UTI hints that might cause issues
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        guard CGImageSourceGetCount(imageSource) > 0 else {
            return nil
        }
        
        // Create options without problematic UTI hints
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldAllowFloat: false
        ]
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return nsImage.isValid ? nsImage : nil
    }
    
    private static func createValidatedNSImage(fromFile url: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return createValidatedNSImage(from: data)
    }
    
    private static func findAssetEndImproved(from start: Data.Index, for type: CarAsset.AssetType, in data: Data) -> Data.Index {
        switch type {
        case .image:
            if data[start..<min(start + 8, data.endIndex)].starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                if let pngEnd = data.range(of: Data([0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82]), in: start..<data.endIndex) {
                    return pngEnd.upperBound
                }
                let nextSig = Data([0x89, 0x50, 0x4E, 0x47])
                if let nextRange = data.range(of: nextSig, in: (start + 1000)..<data.endIndex) {
                    return nextRange.lowerBound
                }
            } else {
                var searchPos = start + 100
                while searchPos < data.endIndex - 1 {
                    if let jpegEnd = data.range(of: Data([0xFF, 0xD9]), in: searchPos..<data.endIndex) {
                        let afterEOI = jpegEnd.upperBound
                        if afterEOI >= data.endIndex ||
                           data[afterEOI] == 0x00 ||
                           data[afterEOI] == 0xFF ||
                           afterEOI + 4 < data.endIndex && data[afterEOI..<afterEOI+4].starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                            return jpegEnd.upperBound
                        }
                        searchPos = jpegEnd.upperBound
                    } else {
                        break
                    }
                }
            }
            return min(start + 2 * 1024 * 1024, data.endIndex)
            
        case .pdf:
            if let pdfEnd = data.range(of: Data("%%EOF".utf8), in: start..<data.endIndex) {
                return pdfEnd.upperBound
            }
            return min(start + 10 * 1024 * 1024, data.endIndex)
            
        case .data:
            return min(start + 1024, data.endIndex)
        }
    }
    
    private static func isValidAssetData(_ data: Data, type: CarAsset.AssetType) -> Bool {
        guard data.count > 100 else { return false }
        
        switch type {
        case .image:
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                // PNG: Check for IHDR chunk after signature
                return data.count > 20 && data[8...11].elementsEqual([0x49, 0x48, 0x44, 0x52])
            } else if data.starts(with: [0xFF, 0xD8, 0xFF]) {
                // JPEG: Use our validated creation method instead of direct NSImage
                let hasEOI = data.contains(Data([0xFF, 0xD9]))
                let canCreateImage = createValidatedNSImage(from: data) != nil
                return hasEOI && canCreateImage
            }
            
            let canCreateImage = createValidatedNSImage(from: data) != nil
            if canCreateImage {
                print("Successfully validated image asset (\(data.count) bytes)")
            } else {
                print("Failed to validate image asset (\(data.count) bytes) - possibly compressed")
                // Debug the failing data
                let firstBytes = data.prefix(16)
                let hex = firstBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                print("   - Failed data signature: \(hex)")
            }
            return canCreateImage
            
        case .pdf:
            return data.suffix(1024).contains("%%EOF".data(using: .utf8) ?? Data())
        case .data:
            return true
        }
    }
    
    private static func determineScaleFromContext(at offset: Data.Index, in data: Data) -> String {
        let contextRange = max(data.startIndex, offset - 200)..<min(offset + 200, data.endIndex)
        let contextData = data.subdata(in: contextRange)
        
        if let contextString = String(data: contextData, encoding: .ascii) {
            if contextString.contains("@3x") || contextString.contains("3x") {
                return "@3x"
            } else if contextString.contains("@2x") || contextString.contains("2x") {
                return "@2x"
            }
        }
        
        return "@1x"
    }
    
    private static func getAssetUtilMetadata(_ url: URL) async -> [CarAsset] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", "macosx", "assetutil", "--info", url.path]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                return parseAssetUtilOutput(output)
            }
        } catch {
            print("AssetUtil metadata failed: \(error)")
        }
        
        return []
    }
    
    private static func parseAssetUtilOutput(_ output: String) -> [CarAsset] {
        var assets: [CarAsset] = []
        
        if let jsonData = output.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                    for item in jsonArray {
                        guard let assetType = item["AssetType"] as? String else { continue }
                        
                        let name = item["Name"] as? String ?? "Unknown Asset"
                        let pixelWidth = item["PixelWidth"] as? Int ?? 0
                        let pixelHeight = item["PixelHeight"] as? Int ?? 0
                        let sizeOnDisk = item["SizeOnDisk"] as? Int ?? 0
                        let scale = item["Scale"] as? Int ?? 1
                        let compression = item["Compression"] as? String ?? ""
                        let appearance = item["Appearance"] as? String
                        let encoding = item["Encoding"] as? String ?? ""
                        
                        let carAssetType: CarAsset.AssetType = {
                            switch assetType {
                            case "Icon Image", "Image", "MultiSized Image":
                                return .image
                            case "Vector":
                                return .pdf
                            case "PackedImage":
                                return .image
                            default:
                                return .data
                            }
                        }()
                        
                        let scaleString = scale > 1 ? "@\(scale)x" : "@1x"
                        
                        var assetName = name
                        if pixelWidth > 0 && pixelHeight > 0 {
                            assetName += " (\(pixelWidth)×\(pixelHeight))"
                        }
                        if let appearance = appearance, appearance == "NSAppearanceNameDarkAqua" {
                            assetName += " [Dark]"
                        }
                        if !compression.isEmpty && compression != "deepmap2" {
                            assetName += " [\(compression)]"
                        }
                        if !encoding.isEmpty && encoding != "ARGB" {
                            assetName += " [\(encoding)]"
                        }
                        if assetType == "PackedImage" {
                            assetName += " [Packed]"
                        }
                        if assetType == "Vector" {
                            assetName += " [Vector]"
                        }
                        
                        let asset = CarAsset(
                            name: assetName,
                            type: carAssetType,
                            size: sizeOnDisk > 0 ? ByteCountFormatter.string(fromByteCount: Int64(sizeOnDisk), countStyle: .file) : "Unknown",
                            scale: scaleString,
                            url: nil,
                            thumbnail: nil,
                            isIconSet: false
                        )
                        
                        assets.append(asset)
                    }
                    
                    return assets.sorted { $0.name < $1.name }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        
        return []
    }
    
    private static func combineExtractedWithMetadata(extracted: [CarAsset], metadata: [CarAsset]) -> [CarAsset] {
        var result: [CarAsset] = []
        
        result.append(contentsOf: extracted)
        
        let appIconAssets = metadata.filter { $0.name.lowercased().contains("appicon") }
        if !appIconAssets.isEmpty {
            let iconSet = CarIconSetBuilder.createIconSet(from: appIconAssets, name: "AppIcon")
            result.append(iconSet)
        }
        
        for metaAsset in metadata {
            if metaAsset.name.lowercased().contains("appicon") {
                continue
            }
            
            let hasExtractedVersion = extracted.contains { extractedAsset in
                extractedAsset.name.localizedCaseInsensitiveContains(metaAsset.name.components(separatedBy: " ").first ?? "") ||
                metaAsset.name.localizedCaseInsensitiveContains(extractedAsset.name.components(separatedBy: "_").last?.components(separatedBy: ".").first ?? "")
            }
            
            if !hasExtractedVersion {
                let placeholderAsset = CarAsset(
                    name: metaAsset.name,
                    type: metaAsset.type,
                    size: metaAsset.size,
                    scale: metaAsset.scale,
                    url: nil,
                    thumbnail: nil,
                    isIconSet: false
                )
                
                result.append(placeholderAsset)
            }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    private static func createBasicAssetInfo(_ url: URL) async throws -> [CarAsset] {
        var assets: [CarAsset] = []
        
        let commonAssets = [
            ("AppIcon", CarAsset.AssetType.image, "@1x", false),
            ("AppIcon", CarAsset.AssetType.image, "@2x", false),
            ("AppIcon", CarAsset.AssetType.image, "@3x", false),
        ]
        
        for (name, type, scale, isIconSet) in commonAssets {
            let asset = CarAsset(
                name: name + scale + ".png",
                type: type,
                size: "Unknown",
                scale: scale,
                url: nil,
                thumbnail: nil,
                isIconSet: isIconSet
            )
            assets.append(asset)
        }
        
        return assets
    }
    
    private static func extractCompressedAssets(from data: Data, to tempDir: URL, startIndex: Int) async throws -> [CarAsset] {
        var assets: [CarAsset] = []
        var assetIndex = startIndex
        
        // Look for potential compressed asset boundaries using metadata patterns
        let patterns = [
            "deepmap2".data(using: .utf8)!,
            "lzfse".data(using: .utf8)!,
            "ARGB".data(using: .utf8)!,
            "RGB".data(using: .utf8)!,
        ]
        
        for pattern in patterns {
            var searchStart = data.startIndex
            
            while searchStart < data.endIndex {
                guard let range = data.range(of: pattern, in: searchStart..<data.endIndex) else {
                    break
                }
                
                // Look for potential compressed data around the pattern
                let contextStart = max(data.startIndex, range.lowerBound - 2000)
                let contextEnd = min(data.endIndex, range.upperBound + 5000)
                let contextData = data.subdata(in: contextStart..<contextEnd)
                
                // Try to find any recognizable image data in this context
                if let imageData = extractImageFromCompressedContext(contextData) {
                    let thumbnail = createValidatedNSImage(from: imageData)
                    
                    let asset = CarAsset(
                        name: "compressed_\(assetIndex).dat",
                        type: .image,
                        size: ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file),
                        scale: "@1x",
                        url: tempDir.appendingPathComponent("compressed_\(assetIndex).dat"),
                        thumbnail: thumbnail,
                        isIconSet: false
                    )
                    
                    if thumbnail != nil {
                        assets.append(asset)
                        assetIndex += 1
                    }
                }
                
                searchStart = range.upperBound
            }
        }
        
        return assets
    }
    
    private static func extractImageFromCompressedContext(_ data: Data) -> Data? {
        // Try different decompression approaches or look for embedded images
        
        // Method 1: Look for any embedded standard image signatures
        let imageSignatures: [[UInt8]] = [
            [0x89, 0x50, 0x4E, 0x47],
            [0xFF, 0xD8, 0xFF],
        ]
        
        for signature in imageSignatures {
            let sigData = Data(signature)
            if let range = data.range(of: sigData) {
                let remainingData = data.subdata(in: range.lowerBound..<data.endIndex)
                if remainingData.count > 500 && NSImage(data: remainingData) != nil {
                    return remainingData
                }
            }
        }
        
        // Method 2: Try to interpret the data as image directly (for some compressed formats)
        if data.count > 500 && NSImage(data: data) != nil {
            return data
        }
        
        return nil
    }
}
