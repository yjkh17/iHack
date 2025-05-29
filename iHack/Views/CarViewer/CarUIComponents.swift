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
                CarInfoSection(title: "File Information") {
                    CarInfoRow(label: "File Size", value: carInfo.fileSize)
                    CarInfoRow(label: "Format", value: "Compiled Asset Catalog")
                    CarInfoRow(label: "Magic Number", value: carInfo.magicNumber)
                    if !carInfo.headerInfo.isEmpty {
                        CarInfoRow(label: "Header", value: carInfo.headerInfo)
                    }
                }
                
                CarInfoSection(title: "Content Analysis") {
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
                
                CarInfoSection(title: "Analysis Tools") {
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search assets...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.2))
                .cornerRadius(8)
                
                Picker("Filter", selection: $selectedAssetType) {
                    ForEach(CarViewerView.AssetType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.systemImage)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Text("\(filteredAssets.count) assets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Export All") {
                    onExportAll()
                }
                .buttonStyle(.bordered)
                .disabled(extractedAssets.isEmpty)
            }
            .padding()
            .background(.gray.opacity(0.05))
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(filteredAssets) { asset in
                        AssetThumbnailView(asset: asset) {
                            onPreview(asset)
                        } onExport: {
                            onExport(asset)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct AssetThumbnailView: View {
    let asset: CarAsset
    let onPreview: () -> Void
    let onExport: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                
                if let thumbnail = asset.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 76, maxHeight: 76)
                        .cornerRadius(6)
                } else {
                    Image(systemName: asset.type.systemImage)
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
                
                if asset.isIconSet {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 20, height: 20)
                                )
                        }
                    }
                    .padding(4)
                }
                
                if isHovered {
                    Rectangle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    
                    HStack(spacing: 12) {
                        Button(action: onPreview) {
                            Image(systemName: "eye")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onExport) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                onPreview()
            }
            
            VStack(spacing: 2) {
                Text(asset.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    if asset.isIconSet {
                        Text("\(asset.iconSetVariants.count) sizes")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    } else {
                        Text(asset.scale)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    Text(asset.size)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 100)
        .padding(8)
        .background(isHovered ? .blue.opacity(0.1) : .clear)
        .cornerRadius(8)
    }
}

struct AssetPreviewView: View {
    let asset: CarAsset
    let onClose: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(asset.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Export") {
                    onExport()
                }
                .buttonStyle(.bordered)
                
                Button("Close") {
                    onClose()
                }
                .buttonStyle(.borderless)
            }
            
            if let thumbnail = asset.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: asset.type.systemImage)
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Preview Available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 300, height: 200)
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Type:")
                        .fontWeight(.medium)
                    Text(asset.isIconSet ? "Icon Set" : asset.type.rawValue)
                    Spacer()
                }
                
                if asset.isIconSet {
                    HStack {
                        Text("Variants:")
                            .fontWeight(.medium)
                        Text(asset.iconSetVariants.joined(separator: ", "))
                        Spacer()
                    }
                } else {
                    HStack {
                        Text("Scale:")
                            .fontWeight(.medium)
                        Text(asset.scale)
                        Spacer()
                    }
                }
                
                HStack {
                    Text("Size:")
                        .fontWeight(.medium)
                    Text(asset.size)
                    Spacer()
                }
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct CarInfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
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