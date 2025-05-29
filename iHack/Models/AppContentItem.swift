//
//  AppContentItem.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import Foundation

enum FileType {
    case plist
    case json
    case text
    case icon
    case xcprivacy
    case car
    case other
}

class AppContentItem: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let isPlist: Bool
    let depth: Int
    @Published var isExpanded: Bool = false
    var children: [AppContentItem] = []
    
    init(name: String, url: URL, isDirectory: Bool, isPlist: Bool, depth: Int) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isPlist = isPlist
        self.depth = depth
    }
    
    var fileType: FileType {
        if isPlist {
            return .plist
        }
        
        let ext = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent
        
        // Handle special files without extensions
        if fileName == "PkgInfo" || fileName == "CodeResources" || fileName.hasPrefix("._") {
            return .text
        }
        
        switch ext {
        case "xcprivacy":
            return .xcprivacy
        case "json":
            return .json
        case "car":
            return .car
        case "txt", "md", "swift", "h", "m", "cpp", "c", "py", "js", "html", "css", "xml", "strings", "scpt", "provisionprofile":
            return .text
        case "icns", "png", "jpg", "jpeg", "gif", "tiff", "bmp", "svg":
            return .icon
        default:
            return .other
        }
    }
}
