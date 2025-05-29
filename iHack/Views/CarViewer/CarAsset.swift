import Foundation
import AppKit

// MARK: - Data Models

struct CarAsset: Identifiable {
    let id = UUID()
    let name: String
    let type: AssetType
    let size: String
    let scale: String
    let url: URL?
    let thumbnail: NSImage?
    let isIconSet: Bool
    let iconSetVariants: [String]
    
    init(name: String, type: AssetType, size: String, scale: String, url: URL?, thumbnail: NSImage?) {
        self.name = name
        self.type = type
        self.size = size
        self.scale = scale
        self.url = url
        self.thumbnail = thumbnail
        self.isIconSet = false
        self.iconSetVariants = []
    }
    
    init(name: String, type: AssetType, size: String, scale: String, url: URL?, thumbnail: NSImage?, isIconSet: Bool, iconSetVariants: [String] = []) {
        self.name = name
        self.type = type
        self.size = size
        self.scale = scale
        self.url = url
        self.thumbnail = thumbnail
        self.isIconSet = isIconSet
        self.iconSetVariants = iconSetVariants
    }
    
    enum AssetType: String, CaseIterable {
        case image = "Image"
        case pdf = "PDF"
        case data = "Data"
        
        var systemImage: String {
            switch self {
            case .image: return "photo"
            case .pdf: return "doc.richtext"
            case .data: return "doc"
            }
        }
    }
}

struct CarFileInfo {
    var fileSize: String = ""
    var magicNumber: String = ""
    var headerInfo: String = ""
    var estimatedAssetCount: String = ""
    var detectedFileTypes: String = ""
    var compressionInfo: String = ""
}