import Foundation
import AppKit

// MARK: - Asset Extraction Engine

class CarAssetExtractor {
    
    static func extractAssets(from url: URL) async throws -> [CarAsset] {
        // Create temp directory for extraction
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
                    thumbnail: CarThumbnailGenerator.createPlaceholderThumbnail(for: metadataAsset.name),
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
                    thumbnail = NSImage(data: asset.data)
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
                    
                    if isValidAssetData(assetData, type: type) {
                        let fileName = "extracted_\(assetIndex).\(ext)"
                        let assetURL = tempDir.appendingPathComponent(fileName)
                        
                        try assetData.write(to: assetURL)
                        
                        var thumbnail: NSImage?
                        if type == .image {
                            thumbnail = NSImage(data: assetData)
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
        
        return assets
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
        guard data.count > 200 else { return false }
        
        switch type {
        case .image:
            if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                return data.count > 20 && data[8...11].elementsEqual([0x49, 0x48, 0x44, 0x52])
            } else if data.starts(with: [0xFF, 0xD8, 0xFF]) {
                let hasEOI = data.contains(Data([0xFF, 0xD9]))
                let canCreateImage = NSImage(data: data) != nil
                return hasEOI && canCreateImage
            }
            return NSImage(data: data) != nil
            
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
                    thumbnail: CarThumbnailGenerator.createPlaceholderThumbnail(for: metaAsset.name),
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
}