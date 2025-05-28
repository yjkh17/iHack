//
//  AppBundle.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import Foundation
import AppKit

struct AppBundle: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let infoPlistPath: String
    let icon: NSImage?

    init(name: String, path: String, infoPlistPath: String) {
        self.name = name
        self.path = path
        self.infoPlistPath = infoPlistPath
        self.icon = NSWorkspace.shared.icon(forFile: path)
    }
}