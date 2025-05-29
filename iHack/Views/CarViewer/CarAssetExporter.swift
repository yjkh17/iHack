import Foundation
import AppKit

// MARK: - Asset Export Engine

class CarAssetExporter {
    
    static func exportAsset(_ asset: CarAsset, estimatedAssetCount: Int) {
        guard let sourceURL = asset.url else {
            let alert = NSAlert()
            alert.messageText = "Cannot Export Asset"
            alert.informativeText = """
            This asset couldn't be fully extracted from the .car file.
            
            Possible reasons:
            • The asset uses proprietary compression
            • It's a color set or data asset (not an image)
            • The asset is embedded in a complex format
            
            Extracted: \(estimatedAssetCount) assets
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg, .pdf, .data]
        savePanel.nameFieldStringValue = asset.name
        savePanel.message = "Export extracted asset (\(asset.size))"
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = "Could not save asset: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
    
    static func exportAllAssets(_ assets: [CarAsset]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose directory to export all assets"
        
        panel.begin { response in
            if response == .OK, let exportDir = panel.url {
                Task {
                    var exportedCount = 0
                    
                    for asset in assets {
                        guard let sourceURL = asset.url else { continue }
                        
                        let destinationURL = exportDir.appendingPathComponent(asset.name)
                        
                        do {
                            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                            exportedCount += 1
                        } catch {
                            print("Failed to export \(asset.name): \(error)")
                        }
                    }
                    
                    let finalExportedCount = exportedCount
                    let totalAssets = assets.count
                    
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Export Complete"
                        alert.informativeText = "Successfully exported \(finalExportedCount) of \(totalAssets) assets"
                        alert.alertStyle = .informational
                        alert.runModal()
                    }
                }
            }
        }
    }
}
