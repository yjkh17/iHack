import Foundation

// MARK: - Native .car File Parser

struct CarFileParser {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func parse() throws -> ParsedCarFile {
        guard data.count > 16 else {
            throw CarParseError.invalidFile
        }
        
        // Read header
        let header = try parseHeader()
        
        // Find and parse assets
        let assets = try parseAssets(header: header)
        
        return ParsedCarFile(header: header, assets: assets)
    }
    
    private func parseHeader() throws -> CarHeader {
        // Parse the .car file header
        // Magic number at offset 0 (4 bytes)
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // Version info and other header data
        let version = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) }
        
        return CarHeader(magic: magic, version: version)
    }
    
    private func parseAssets(header: CarHeader) throws -> [ParsedAsset] {
        var assets: [ParsedAsset] = []
        
        // This is a simplified parser - real .car files have complex structure
        // We'll look for common image signatures in the data
        
        // Look for PNG signatures
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        assets.append(contentsOf: findAssetsWithSignature(pngSignature, type: .image, extension: "png"))
        
        // Look for JPEG signatures
        let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF]
        assets.append(contentsOf: findAssetsWithSignature(jpegSignature, type: .image, extension: "jpg"))
        
        // Look for PDF signatures
        let pdfSignature: [UInt8] = [0x25, 0x50, 0x44, 0x46]
        assets.append(contentsOf: findAssetsWithSignature(pdfSignature, type: .pdf, extension: "pdf"))
        
        return assets
    }
    
    private func findAssetsWithSignature(_ signature: [UInt8], type: CarAsset.AssetType, extension: String) -> [ParsedAsset] {
        var assets: [ParsedAsset] = []
        let signatureData = Data(signature)
        
        var searchRange = data.startIndex..<data.endIndex
        var assetIndex = 0
        
        while let range = data.range(of: signatureData, in: searchRange) {
            // Found a file signature
            let startOffset = range.lowerBound
            
            // Try to find the end of this asset
            let endOffset = findAssetEnd(from: startOffset, for: type)
            
            if endOffset > startOffset {
                let assetData = data.subdata(in: startOffset..<endOffset)
                
                // Determine scale from context or filename patterns
                let scale = determineScale(at: startOffset)
                
                let asset = ParsedAsset(
                    name: "\(type.rawValue.lowercased())_\(assetIndex)",
                    type: type,
                    fileExtension: `extension`,
                    scale: scale,
                    data: assetData
                )
                
                assets.append(asset)
                assetIndex += 1
            }
            
            // Continue searching after this match
            searchRange = range.upperBound..<data.endIndex
            
            // Prevent infinite loops
            if searchRange.isEmpty {
                break
            }
        }
        
        return assets
    }
    
    private func findAssetEnd(from start: Data.Index, for type: CarAsset.AssetType) -> Data.Index {
        switch type {
        case .image:
            // For PNG, look for IEND chunk
            if let pngEnd = data.range(of: Data([0x49, 0x45, 0x4E, 0x44]), in: start..<data.endIndex) {
                return pngEnd.upperBound + 4 // Include CRC
            }
            // For JPEG, look for EOI marker
            if let jpegEnd = data.range(of: Data([0xFF, 0xD9]), in: start..<data.endIndex) {
                return jpegEnd.upperBound
            }
            // Fallback: assume reasonable size
            return min(start + 1024 * 1024, data.endIndex) // Max 1MB
            
        case .pdf:
            // Look for PDF end
            if let pdfEnd = data.range(of: Data("%%EOF".utf8), in: start..<data.endIndex) {
                return pdfEnd.upperBound
            }
            return min(start + 10 * 1024 * 1024, data.endIndex) // Max 10MB
            
        case .data:
            return min(start + 1024, data.endIndex) // Max 1KB for data
        }
    }
    
    private func determineScale(at offset: Data.Index) -> String {
        // Look backwards and forwards for scale hints
        let searchRange = max(data.startIndex, offset - 100)..<min(offset + 100, data.endIndex)
        let contextData = data.subdata(in: searchRange)
        
        if let contextString = String(data: contextData, encoding: .ascii) {
            if contextString.contains("@3x") {
                return "@3x"
            } else if contextString.contains("@2x") {
                return "@2x"
            }
        }
        
        return "@1x"
    }
}

// MARK: - Parser Data Models

struct ParsedCarFile {
    let header: CarHeader
    let assets: [ParsedAsset]
}

struct CarHeader {
    let magic: UInt32
    let version: UInt32
}

struct ParsedAsset {
    let name: String
    let type: CarAsset.AssetType
    let fileExtension: String
    let scale: String
    let data: Data
}

enum CarParseError: Error {
    case invalidFile
    case corruptedData
    case unsupportedVersion
}