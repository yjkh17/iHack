import SwiftUI
import Foundation
import AppKit

// MARK: - UI Components

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .blue.opacity(0.1) : .clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct CarFileInfoView: View {
    let carInfo: CarFileInfo
    let fileURL: URL?
    let extractedAssets: [CarAsset]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("File Information")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        CarInfoRow(label: "File Size", value: carInfo.fileSize)
                        CarInfoRow(label: "Format", value: "Compiled Asset Catalog")
                        CarInfoRow(label: "Magic Number", value: carInfo.magicNumber)
                        if !carInfo.headerInfo.isEmpty {
                            CarInfoRow(label: "Header", value: carInfo.headerInfo)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if !carInfo.estimatedAssetCount.isEmpty {
                            CarInfoRow(label: "Detected Assets", value: carInfo.estimatedAssetCount)
                        }
                        if !carInfo.detectedFileTypes.isEmpty {
                            CarInfoRow(label: "Asset Types", value: carInfo.detectedFileTypes)
                        }
                        CarInfoRow(label: "Compression", value: carInfo.compressionInfo)
                        CarInfoRow(label: "Format", value: "Compiled Asset Catalog (.car)")
                        CarInfoRow(label: "Optimization", value: "Runtime-optimized binary format")
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Analysis Tools")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 12) {
                            ToolRow(
                                name: "assetutil (Xcode)",
                                command: "xcrun --sdk iphoneos assetutil --info \"\(fileURL?.path ?? "")\"",
                                description: "Official Apple tool for .car analysis",
                                onRun: {
                                    runAssetUtil()
                                }
                            )
                            
                            ToolRow(
                                name: "Asset Catalog Tinkerer",
                                command: "Third-party GUI app",
                                description: "Visual tool for browsing .car contents",
                                onRun: nil
                            )
                            
                            ToolRow(
                                name: "cartool",
                                command: "cartool \"\(fileURL?.path ?? "")\" /output/directory",
                                description: "Command-line tool to extract assets",
                                onRun: nil
                            )
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Extract Assets")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Click 'Extract Assets' above to see thumbnails and export individual assets from this .car file.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func runAssetUtil() {
        guard let url = fileURL else { return }
        
        let script = """
        tell application "Terminal"
            activate
            do script "xcrun --sdk macosx assetutil --info '\(url.path)'"
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
}

struct CarAssetsView: View {
    let filteredAssets: [CarAsset]
    @Binding var searchText: String
    @Binding var selectedAssetType: CarViewerView.AssetType
    let extractedAssets: [CarAsset]
    let onPreview: (CarAsset) -> Void
    let onExport: (CarAsset) -> Void
    let onExportAll: () -> Void
    
    @State private var selectedAsset: CarAsset?
    
    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar - Asset list (like Xcode navigator)
            VStack(spacing: 0) {
                // Search and filter bar
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        TextField("Search assets...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.gray.opacity(0.15))
                    .cornerRadius(6)
                    
                    Picker("Filter", selection: $selectedAssetType) {
                        ForEach(CarViewerView.AssetType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(width: 100)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                Divider()
                
                // Asset list
                List(filteredAssets, id: \.id, selection: $selectedAsset) { asset in
                    AssetListRowView(asset: asset) {
                        selectedAsset = asset
                        onPreview(asset)
                    } onExport: {
                        onExport(asset)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                
                // Bottom toolbar
                HStack(spacing: 8) {
                    Text("\(filteredAssets.count) assets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Export All") {
                        onExportAll()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(extractedAssets.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
            .frame(width: 320)
            
            Divider()
            
            // Right panel - Preview area
            VStack(spacing: 0) {
                if let selectedAsset = selectedAsset {
                    AssetDetailPreviewView(asset: selectedAsset, onExport: {
                        onExport(selectedAsset)
                    })
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No Asset Selected")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Select an asset from the list to preview")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial.opacity(0.3))
                }
            }
        }
    }
}

struct AssetListRowView: View {
    let asset: CarAsset
    let onSelect: () -> Void
    let onExport: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let thumbnail = asset.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: asset.type.systemImage)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Asset info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(asset.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if asset.isIconSet {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 8) {
                    if asset.isIconSet {
                        Text("\(asset.iconSetVariants.count) variants")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text(asset.scale)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(asset.size)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Export button (shown on hover)
            if isHovered {
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovered ? .gray.opacity(0.1) : .clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            print("🔍 Asset clicked: \(asset.name)")
            print("   - Type: \(asset.type)")
            print("   - Size: \(asset.size)")
            print("   - Scale: \(asset.scale)")
            print("   - Has thumbnail: \(asset.thumbnail != nil)")
            print("   - URL: \(asset.url?.path ?? "nil")")
            print("   - Is icon set: \(asset.isIconSet)")
            
            if let url = asset.url {
                let exists = FileManager.default.fileExists(atPath: url.path)
                print("   - File exists: \(exists)")
                
                if exists {
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                       let fileSize = attributes[.size] as? Int64 {
                        print("   - Actual file size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                    }
                    
                    if let data = try? Data(contentsOf: url) {
                        let firstBytes = data.prefix(16)
                        let hex = firstBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                        print("   - File signature: \(hex)")
                        
                        let canLoadAsImage = NSImage(contentsOf: url) != nil
                        print("   - Can load as NSImage: \(canLoadAsImage)")
                    }
                }
            }
            print("---")
            
            onSelect()
        }
    }
}

struct AssetDetailPreviewView: View {
    let asset: CarAsset
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(asset.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(asset.isIconSet ? "Icon Set" : asset.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Export") {
                    onExport()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(asset.url == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Content area
            ScrollView {
                VStack(spacing: 24) {
                    // Preview content
                    if asset.isIconSet {
                        XcodeStyleIconSetView(asset: asset)
                            .padding(.horizontal, 20)
                    } else if let thumbnail = asset.thumbnail {
                        VStack(spacing: 16) {
                            if thumbnail.isValid {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 320, maxHeight: 320)
                                    .background(.quaternary.opacity(0.3))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .onAppear {
                                        print("📸 Displaying thumbnail for: \(asset.name)")
                                        print("   - Thumbnail size: \(thumbnail.size)")
                                        print("   - Thumbnail is valid: \(thumbnail.isValid)")
                                        print("   - Thumbnail representations count: \(thumbnail.representations.count)")
                                        if let rep = thumbnail.representations.first {
                                            print("   - First rep size: \(rep.pixelsWide)×\(rep.pixelsHigh)")
                                            print("   - First rep class: \(type(of: rep))")
                                        }
                                    }
                            } else {
                                Group {
                                    if let assetURL = asset.url, let reloadedImage = NSImage(contentsOf: assetURL) {
                                        Image(nsImage: reloadedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 320, maxHeight: 320)
                                            .background(.quaternary.opacity(0.3))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            .onAppear {
                                                print("🔄 Reloaded image from URL for: \(asset.name)")
                                                print("   - Reloaded size: \(reloadedImage.size)")
                                            }
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.exclamationmark")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(.orange.opacity(0.6))
                                            
                                            Text("Invalid Thumbnail")
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text("The thumbnail data appears to be corrupted")
                                                .font(.callout)
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: 320, maxHeight: 200)
                                        .background(.orange.opacity(0.1))
                                        .cornerRadius(12)
                                        .onAppear {
                                            print("⚠️ Invalid thumbnail for: \(asset.name)")
                                        }
                                    }
                                }
                            }
                            
                            if let imageRep = thumbnail.representations.first {
                                Text("\(imageRep.pixelsWide) × \(imageRep.pixelsHigh) pixels")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else if let assetURL = asset.url {
                        VStack(spacing: 16) {
                            if asset.name.lowercased().hasSuffix(".svg") {
                                Group {
                                    if let svgImage = createSVGImage(from: assetURL) {
                                        Image(nsImage: svgImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 320, maxHeight: 320)
                                            .background(.quaternary.opacity(0.3))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            .onAppear {
                                                print("✅ SVG loaded successfully for: \(asset.name)")
                                                print("   - SVG size: \(svgImage.size)")
                                            }
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "doc.richtext")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(.purple.opacity(0.6))
                                            
                                            VStack(spacing: 6) {
                                                Text("SVG Vector")
                                                    .font(.title3)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                
                                                Text("This SVG file cannot be previewed but can be exported")
                                                    .font(.callout)
                                                    .foregroundColor(.secondary)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 20)
                                            }
                                        }
                                        .frame(maxWidth: 320, maxHeight: 200)
                                        .background(.purple.opacity(0.1))
                                        .cornerRadius(12)
                                        .onAppear {
                                            print("📄 SVG file detected but cannot preview: \(asset.name)")
                                        }
                                    }
                                }
                            } else {
                                AsyncImage(url: assetURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 320, maxHeight: 320)
                                        .background(.quaternary.opacity(0.3))
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .onAppear {
                                            print("✅ AsyncImage loaded successfully for: \(asset.name)")
                                        }
                                } placeholder: {
                                    Group {
                                        if let nsImage = NSImage(contentsOf: assetURL) {
                                            Image(nsImage: nsImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: 320, maxHeight: 320)
                                                .background(.quaternary.opacity(0.3))
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                .onAppear {
                                                    print("✅ NSImage fallback loaded for: \(asset.name)")
                                                    print("   - NSImage size: \(nsImage.size)")
                                                }
                                        } else {
                                            VStack(spacing: 12) {
                                                Image(systemName: "doc.text")
                                                    .font(.system(size: 40, weight: .light))
                                                    .foregroundColor(.secondary.opacity(0.6))
                                                
                                                VStack(spacing: 6) {
                                                    Text("Binary Asset")
                                                        .font(.title3)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    
                                                    Text("This asset contains binary data that cannot be previewed as an image")
                                                        .font(.callout)
                                                        .foregroundColor(.secondary)
                                                        .multilineTextAlignment(.center)
                                                        .padding(.horizontal, 20)
                                                }
                                            }
                                            .frame(maxWidth: 320, maxHeight: 200)
                                            .background(.quaternary.opacity(0.2))
                                            .cornerRadius(12)
                                            .onAppear {
                                                print("❌ Could not load as image: \(asset.name)")
                                                print("   - File path: \(assetURL.path)")
                                                
                                                if let data = try? Data(contentsOf: assetURL) {
                                                    let firstBytes = data.prefix(8)
                                                    let hex = firstBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                                                    print("   - File starts with: \(hex)")
                                                    print("   - Data length: \(data.count) bytes")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: assetURL.path),
                               let fileSize = fileAttributes[.size] as? Int64 {
                                Text("\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .onAppear {
                            print("🖼️ Attempting to preview asset: \(asset.name)")
                            print("   - URL: \(assetURL.path)")
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.secondary.opacity(0.6))
                            
                            VStack(spacing: 6) {
                                Text("No Preview Available")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("This asset uses proprietary compression and couldn't be extracted")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .frame(maxWidth: 320, maxHeight: 200)
                        .background(.quaternary.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .onAppear {
                            print("⚠️ No preview available for: \(asset.name)")
                            print("   - No URL available for this asset")
                        }
                    }
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(label: "Type", value: asset.isIconSet ? "Icon Set" : asset.type.rawValue)
                            
                            if asset.isIconSet {
                                DetailRow(label: "Variants", value: "\(asset.iconSetVariants.count)")
                                if !asset.iconSetVariants.isEmpty {
                                    DetailRow(label: "Sizes", value: asset.iconSetVariants.joined(separator: ", "))
                                }
                            } else {
                                DetailRow(label: "Scale", value: asset.scale)
                            }
                            
                            DetailRow(label: "Size", value: asset.size)
                            DetailRow(label: "Status", value: asset.url != nil ? "Extracted" : "Metadata only")
                            
                            if let assetURL = asset.url {
                                DetailRow(label: "Path", value: assetURL.lastPathComponent)
                            }
                        }
                        .padding(16)
                        .background(.quaternary.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func createSVGImage(from url: URL) -> NSImage? {
        do {
            let data = try Data(contentsOf: url)
            
            if let image = NSImage(data: data), image.isValid {
                print("✅ NSImage created SVG successfully")
                return image
            }
            
            if let pdfRep = NSPDFImageRep(data: data) {
                let image = NSImage(size: pdfRep.bounds.size)
                image.addRepresentation(pdfRep)
                if image.isValid {
                    print("✅ SVG loaded via PDF representation")
                    return image
                }
            }
            
            if let svgString = String(data: data, encoding: .utf8),
               svgString.contains("<svg") {
                
                let htmlContent = """
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body { margin: 0; padding: 0; background: transparent; }
                        svg { max-width: 512px; max-height: 512px; }
                    </style>
                </head>
                <body>
                    \(svgString)
                </body>
                </html>
                """
                
                if htmlContent.data(using: .utf8) != nil {
                    print("📄 SVG HTML wrapper created, but WebKit rendering not implemented")
                }
            }
            
            if let svgString = String(data: data, encoding: .utf8),
               svgString.contains("viewBox") || svgString.contains("width") {
                
                let image = NSImage(size: NSSize(width: 256, height: 256))
                image.lockFocus()
                
                NSColor.systemGray.withAlphaComponent(0.1).setFill()
                NSRect(origin: .zero, size: NSSize(width: 256, height: 256)).fill()
                
                if let symbolImage = NSImage(systemSymbolName: "doc.richtext.fill", accessibilityDescription: nil) {
                    symbolImage.size = NSSize(width: 64, height: 64)
                    let rect = NSRect(x: 96, y: 96, width: 64, height: 64)
                    symbolImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.6)
                }
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: NSColor.labelColor
                ]
                let svgText = NSAttributedString(string: "SVG", attributes: attributes)
                let textSize = svgText.size()
                let textRect = NSRect(
                    x: (256 - textSize.width) / 2,
                    y: 50,
                    width: textSize.width,
                    height: textSize.height
                )
                svgText.draw(in: textRect)
                
                image.unlockFocus()
                
                if image.isValid {
                    print("✅ Created custom SVG preview image")
                    return image
                }
            }
            
        } catch {
            print("❌ Failed to load SVG data: \(error)")
        }
        
        return nil
    }
}

struct XcodeStyleIconSetView: View {
    let asset: CarAsset
    
    private let iconSizes = [
        (size: "16pt", scale1x: 16, scale2x: 32),
        (size: "32pt", scale1x: 32, scale2x: 64),
        (size: "128pt", scale1x: 128, scale2x: 256),
        (size: "256pt", scale1x: 256, scale2x: 512),
        (size: "512pt", scale1x: 512, scale2x: 1024)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("App Icon")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 40) {
                ForEach(iconSizes, id: \.size) { iconSize in
                    createIconSizeGroup(iconSize)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            
            HStack {
                Text("\(asset.iconSetVariants.count) icon variants")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Total size: \(asset.size)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: 800, maxHeight: 250)
        .padding(.vertical, 16)
        .background(.gray.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func createIconSizeGroup(_ iconSize: (size: String, scale1x: Int, scale2x: Int)) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                createIconPlaceholder(size: CGFloat(min(iconSize.scale1x, 32)))
                
                Text("1x")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("macOS")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                Text(iconSize.size)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                createIconPlaceholder(size: CGFloat(min(iconSize.scale2x / 2, 32)))
                
                Text("2x")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("macOS")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                Text(iconSize.size)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func createIconPlaceholder(size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                .fill(Color.secondary.opacity(0.05))
                .frame(width: size, height: size)
            
            Image(systemName: "photo.badge.plus")
                .font(.system(size: size * 0.25, weight: .light))
                .foregroundColor(.secondary.opacity(0.4))
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct CarInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct ToolRow: View {
    let name: String
    let command: String
    let description: String
    let onRun: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let onRun = onRun {
                    Button("Run Command") {
                        onRun()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.green)
                }
                
                Button("Copy Command") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.blue)
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
                .cornerRadius(4)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(6)
    }
}
