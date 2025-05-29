import Foundation

// MARK: - File Analysis Engine

class CarFileAnalyzer {
    
    static func analyzeCarData(_ data: Data, url: URL) -> CarFileInfo {
        var info = CarFileInfo()
        
        // File size
        info.fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        
        // Header analysis
        if data.count > 16 {
            let header = data.prefix(16)
            let headerHex = header.map { String(format: "%02X", $0) }.joined(separator: " ")
            info.headerInfo = headerHex
            
            // Magic number (first 4 bytes)
            if data.count >= 4 {
                let magicBytes = data.prefix(4)
                let magic = magicBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
                info.magicNumber = "0x\(String(format: "%08X", magic))"
            }
        }
        
        // Use fallback analysis for immediate results
        info.estimatedAssetCount = estimateAssetCount(in: data)
        info.detectedFileTypes = detectFileTypes(in: data)
        info.compressionInfo = analyzeCompression(in: data)
        
        return info
    }
    
    static func analyzeCarDataEnhanced(_ data: Data, url: URL) async -> CarFileInfo {
        var info = CarFileInfo()
        
        // File size
        info.fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        
        // Header analysis
        if data.count > 16 {
            let header = data.prefix(16)
            let headerHex = header.map { String(format: "%02X", $0) }.joined(separator: " ")
            info.headerInfo = headerHex
            
            // Magic number (first 4 bytes)
            if data.count >= 4 {
                let magicBytes = data.prefix(4)
                let magic = magicBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
                info.magicNumber = "0x\(String(format: "%08X", magic))"
            }
        }
        
        let assetUtilAssets = await getAssetUtilAnalysis(url)
        if !assetUtilAssets.isEmpty {
            info.estimatedAssetCount = "\(assetUtilAssets.count) assets detected via assetutil"
            info.detectedFileTypes = analyzeAssetTypes(assetUtilAssets)
            info.compressionInfo = analyzeCompressionTypes(assetUtilAssets)
        } else {
            // Fallback analysis if assetutil fails
            info.estimatedAssetCount = estimateAssetCount(in: data)
            info.detectedFileTypes = detectFileTypes(in: data)
            info.compressionInfo = analyzeCompression(in: data)
        }
        
        return info
    }
    
    private static func getAssetUtilAnalysis(_ url: URL) async -> [CarAsset] {
        return await withCheckedContinuation { continuation in
            Task.detached {
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
                        let assets = parseAssetUtilOutput(output)
                        continuation.resume(returning: assets)
                    } else {
                        continuation.resume(returning: [])
                    }
                } catch {
                    print("AssetUtil analysis failed: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    private static func parseAssetUtilOutput(_ output: String) -> [CarAsset] {
        var assets: [CarAsset] = []
        
        if let jsonData = output.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                    for item in jsonArray {
                        guard let assetType = item["AssetType"] as? String else { continue }
                        
                        let name = item["Name"] as? String ?? "Unknown Asset"
                        let sizeOnDisk = item["SizeOnDisk"] as? Int ?? 0
                        let scale = item["Scale"] as? Int ?? 1
                        
                        let carAssetType: CarAsset.AssetType = {
                            switch assetType {
                            case "Icon Image", "Image", "MultiSized Image":
                                return .image
                            case "Vector":
                                return .pdf
                            default:
                                return .data
                            }
                        }()
                        
                        let scaleString = scale > 1 ? "@\(scale)x" : "@1x"
                        let sizeString = sizeOnDisk > 0 ? ByteCountFormatter.string(fromByteCount: Int64(sizeOnDisk), countStyle: .file) : "Unknown"
                        
                        let asset = CarAsset(
                            name: name,
                            type: carAssetType,
                            size: sizeString,
                            scale: scaleString,
                            url: nil,
                            thumbnail: nil
                        )
                        
                        assets.append(asset)
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        
        return assets
    }
    
    private static func analyzeAssetTypes(_ assets: [CarAsset]) -> String {
        let typeCounts = Dictionary(grouping: assets, by: { $0.type }).mapValues { $0.count }
        var types: [String] = []
        
        if let imageCount = typeCounts[.image], imageCount > 0 {
            types.append("\(imageCount) images")
        }
        if let pdfCount = typeCounts[.pdf], pdfCount > 0 {
            types.append("\(pdfCount) vectors")
        }
        if let dataCount = typeCounts[.data], dataCount > 0 {
            types.append("\(dataCount) data assets")
        }
        
        return types.isEmpty ? "Unknown content" : types.joined(separator: ", ")
    }
    
    private static func analyzeCompressionTypes(_ assets: [CarAsset]) -> String {
        if assets.count > 0 {
            return "Mixed compression (deepmap2, lzfse, JPEG)"
        }
        return "Optimized binary format"
    }
    
    private static func estimateAssetCount(in data: Data) -> String {
        var count = 0
        count += countOccurrences(of: Data([0x89, 0x50, 0x4E, 0x47]), in: data) // PNG
        count += countOccurrences(of: Data([0xFF, 0xD8, 0xFF]), in: data) // JPEG
        count += countOccurrences(of: Data([0x25, 0x50, 0x44, 0x46]), in: data) // PDF
        return "~\(count) potential assets detected"
    }
    
    private static func detectFileTypes(in data: Data) -> String {
        var types: [String] = []
        
        if countOccurrences(of: Data([0x89, 0x50, 0x4E, 0x47]), in: data) > 0 {
            types.append("PNG images")
        }
        if countOccurrences(of: Data([0xFF, 0xD8, 0xFF]), in: data) > 0 {
            types.append("JPEG images")
        }
        if countOccurrences(of: Data([0x25, 0x50, 0x44, 0x46]), in: data) > 0 {
            types.append("PDF vectors")
        }
        
        return types.isEmpty ? "Unknown content" : types.joined(separator: ", ")
    }
    
    private static func analyzeCompression(in data: Data) -> String {
        let zlibSignature = Data([0x78, 0x9C])
        let gzipSignature = Data([0x1F, 0x8B])
        
        if countOccurrences(of: zlibSignature, in: data) > 0 {
            return "zlib compressed"
        } else if countOccurrences(of: gzipSignature, in: data) > 0 {
            return "gzip compressed"
        }
        
        return "Optimized binary format"
    }
    
    private static func countOccurrences(of pattern: Data, in data: Data) -> Int {
        var count = 0
        var searchRange = data.startIndex..<data.endIndex
        
        while let range = data.range(of: pattern, in: searchRange) {
            count += 1
            searchRange = range.upperBound..<data.endIndex
            if searchRange.isEmpty { break }
        }
        
        return count
    }
}
