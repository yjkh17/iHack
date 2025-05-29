import Foundation
import AppKit

// MARK: - Thumbnail Generation

class CarThumbnailGenerator {
    
    static func createPlaceholderThumbnail(for assetName: String) -> NSImage? {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let lowerName = assetName.lowercased()
        let (gradientColors, iconName): ([NSColor], String) = {
            if lowerName.contains("appicon") {
                return ([NSColor.systemBlue.withAlphaComponent(0.4), NSColor.systemBlue.withAlphaComponent(0.1)], "app.fill")
            } else if lowerName.contains("icon") {
                return ([NSColor.systemOrange.withAlphaComponent(0.4), NSColor.systemOrange.withAlphaComponent(0.1)], "star.fill")
            } else if lowerName.contains("packedasset") || lowerName.contains("packed") {
                return ([NSColor.systemPurple.withAlphaComponent(0.4), NSColor.systemPurple.withAlphaComponent(0.1)], "cube.box.fill")
            } else if lowerName.contains("gamut") {
                return ([NSColor.systemGreen.withAlphaComponent(0.4), NSColor.systemGreen.withAlphaComponent(0.1)], "paintpalette.fill")
            } else if lowerName.contains("alex") || lowerName.contains("cool") {
                return ([NSColor.systemTeal.withAlphaComponent(0.4), NSColor.systemTeal.withAlphaComponent(0.1)], "person.crop.circle.fill")
            } else {
                return ([NSColor.systemGray.withAlphaComponent(0.4), NSColor.systemGray.withAlphaComponent(0.1)], "photo.fill")
            }
        }()
        
        let gradient = NSGradient(colors: gradientColors)
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        if let symbol = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            let iconSize = NSSize(width: 32, height: 32)
            let iconRect = NSRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2,
                width: iconSize.width,
                height: iconSize.height
            )
            
            gradientColors[0].withAlphaComponent(0.8).set()
            symbol.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        image.unlockFocus()
        return image
    }
}