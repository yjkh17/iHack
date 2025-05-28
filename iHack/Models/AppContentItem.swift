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
    case other
}

class AppContentItem: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let isPlist: Bool
    let fileType: FileType
    let depth: Int
    @Published var isExpanded: Bool = false
    var children: [AppContentItem] = []
    
    init(name: String, url: URL, isDirectory: Bool, isPlist: Bool, depth: Int) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isPlist = isPlist
        self.depth = depth
        
        // Determine file type based on extension and special files
        let ext = url.pathExtension.lowercased()
        let fileName = url.lastPathComponent
        
        switch ext {
        case "plist":
            self.fileType = .plist
        case "json":
            self.fileType = .json
        case "txt", "md", "swift", "h", "m", "cpp", "c", "py", "js", "html", "css", "xml", "strings", "scpt", "provisionprofile":
            self.fileType = .text
        case "icns", "png", "jpg", "jpeg", "gif", "bmp", "tiff":
            self.fileType = .icon
        default:
            // Handle special files without extensions
            if fileName == "PkgInfo" || fileName == "CodeResources" || fileName.hasPrefix("._") {
                self.fileType = .text
            } else {
                self.fileType = .other
            }
        }
        
        print("Created item: \(name), isDirectory: \(isDirectory), fileType: \(fileType), children: \(children.count)")
    }
}
