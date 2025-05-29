import Foundation
import AppKit

// MARK: - Icon Set Builder

class CarIconSetBuilder {
    
    static func createIconSet(from assets: [CarAsset], name: String) -> CarAsset {
        let totalSize = assets.compactMap { asset in
            if let sizeString = asset.size.components(separatedBy: " ").first,
               let size = Double(sizeString.replacingOccurrences(of: ",", with: "")) {
                return size
            }
            if asset.size.contains("KB") {
                let number = asset.size.replacingOccurrences(of: " KB", with: "").replacingOccurrences(of: ",", with: "")
                if let kb = Double(number) {
                    return kb * 1024.0
                }
            }
            return 0.0
        }.reduce(0.0, +)
        
        let sizeString = ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        let scales = Set(assets.map { $0.scale }).sorted()
        let scaleString = scales.joined(separator: ", ")
        
        let sizeVariants = assets.compactMap { asset -> String? in
            if let sizeMatch = asset.name.range(of: #"\((\d+×\d+)\)"#, options: .regularExpression) {
                return String(asset.name[sizeMatch]).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
            }
            return nil
        }
        let uniqueSizes = Array(Set(sizeVariants)).sorted()
        
        return CarAsset(
            name: "\(name) Icon Set (\(assets.count) variants)",
            type: .image,
            size: sizeString,
            scale: scaleString,
            url: nil,
            thumbnail: createIconSetThumbnail(from: assets),
            isIconSet: true,
            iconSetVariants: uniqueSizes
        )
    }
    
    static func createIconSetThumbnail(from assets: [CarAsset]) -> NSImage? {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let iconColors = [
            NSColor.systemBlue.withAlphaComponent(0.9),
            NSColor.systemBlue.withAlphaComponent(0.7),
            NSColor.systemBlue.withAlphaComponent(0.5)
        ]
        
        for (index, color) in iconColors.enumerated() {
            let offset = CGFloat(index * 4)
            let iconRect = NSRect(
                x: offset,
                y: offset,
                width: size.width - offset * 2,
                height: size.height - offset * 2
            )
            
            let path = NSBezierPath(roundedRect: iconRect, xRadius: 8, yRadius: 8)
            color.setFill()
            path.fill()
            
            NSColor.white.withAlphaComponent(0.3).setStroke()
            path.lineWidth = 1
            path.stroke()
        }
        
        if let symbol = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) {
            let symbolSize = NSSize(width: 24, height: 24)
            let symbolRect = NSRect(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2,
                width: symbolSize.width,
                height: symbolSize.height
            )
            
            NSColor.white.set()
            symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        let countText = "\(assets.count)"
        let font = NSFont.systemFont(ofSize: 8, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        
        let textSize = countText.size(withAttributes: attributes)
        let textRect = NSRect(
            x: size.width - textSize.width - 4,
            y: 2,
            width: textSize.width,
            height: textSize.height
        )
        
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: textRect.minX - 2,
            y: textRect.minY - 1,
            width: textSize.width + 4,
            height: textSize.height + 2
        ))
        NSColor.systemRed.setFill()
        circlePath.fill()
        
        countText.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        return image
    }
}
