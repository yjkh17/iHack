import Foundation
import AppKit

// MARK: - Data Models

struct CarAsset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: AssetType
    let size: String
    let scale: String
    let url: URL?
    let thumbnail: NSImage?
    let isIconSet: Bool
    let iconSetVariants: [String]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(size)
        hasher.combine(scale)
        hasher.combine(url)
        hasher.combine(isIconSet)
        hasher.combine(iconSetVariants)
    }
    
    static func == (lhs: CarAsset, rhs: CarAsset) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.size == rhs.size &&
               lhs.scale == rhs.scale &&
               lhs.url == rhs.url &&
               lhs.isIconSet == rhs.isIconSet &&
               lhs.iconSetVariants == rhs.iconSetVariants
    }
    
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
