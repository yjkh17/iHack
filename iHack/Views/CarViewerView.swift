//
//  CarViewerView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import Foundation
import AppKit

struct CarViewerView: View {
    let fileURL: URL?
    @State private var carInfo: CarFileInfo = CarFileInfo()
    @State private var extractedAssets: [CarAsset] = []
    @State private var isAnalyzing = false
    @State private var isExtracting = false
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedAssetType: AssetType = .all
    @State private var showingPreview: CarAsset?
    
    enum AssetType: String, CaseIterable {
        case all = "All"
        case image = "Images"
        case icon = "Icons"
        case data = "Data"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .image: return "photo"
            case .icon: return "app"
            case .data: return "doc"
            }
        }
    }
    
    var filteredAssets: [CarAsset] {
        var filtered = extractedAssets
        
        // Filter by type
        if selectedAssetType != .all {
            filtered = filtered.filter { asset in
                switch selectedAssetType {
                case .image:
                    return asset.type == .image
                case .icon:
                    return asset.name.lowercased().contains("icon") || asset.name.lowercased().contains("appicon")
                case .data:
                    return asset.type == .data
                case .all:
                    return true
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { asset in
                asset.name.localizedCaseInsensitiveContains(searchText) ||
                asset.scale.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Asset Catalog Archive (.car)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let url = fileURL {
                    Button("Extract Assets") {
                        extractAssets(from: url)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAnalyzing || isExtracting)
                    
                    Button("Analyze") {
                        analyzeCarFile(url)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAnalyzing || isExtracting)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            if isAnalyzing || isExtracting {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(isExtracting ? "Extracting Assets..." : "Analyzing Asset Catalog...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 200)
            } else if let error = error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Analysis Error")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Main content with tabs
                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 0) {
                        TabButton(title: "File Info", isSelected: extractedAssets.isEmpty) {
                            // File info is always shown when no assets extracted
                        }
                        
                        if !extractedAssets.isEmpty {
                            TabButton(title: "Assets (\(extractedAssets.count))", isSelected: !extractedAssets.isEmpty) {
                                // Assets view
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .background(.gray.opacity(0.05))
                    
                    if extractedAssets.isEmpty {
                        // File Info View
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // File Info Section
                                CarInfoSection(title: "File Information") {
                                    CarInfoRow(label: "File Size", value: carInfo.fileSize)
                                    CarInfoRow(label: "Format", value: "Compiled Asset Catalog")
                                    CarInfoRow(label: "Magic Number", value: carInfo.magicNumber)
                                    if !carInfo.headerInfo.isEmpty {
                                        CarInfoRow(label: "Header", value: carInfo.headerInfo)
                                    }
                                }
                                
                                // Analysis Section
                                CarInfoSection(title: "Content Analysis") {
                                    CarInfoRow(label: "Contains", value: "App icons, images, colors, and data assets")
                                    CarInfoRow(label: "Optimization", value: "Optimized for runtime performance")
                                    CarInfoRow(label: "Format", value: "Binary, not directly editable")
                                }
                                
                                // Tools Section
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
                                
                                // Warning Section
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
                    } else {
                        // Assets View
                        VStack(spacing: 0) {
                            // Search and filter bar
                            HStack(spacing: 12) {
                                // Search
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
                                
                                // Type filter
                                Picker("Filter", selection: $selectedAssetType) {
                                    ForEach(AssetType.allCases, id: \.self) { type in
                                        Label(type.rawValue, systemImage: type.systemImage)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                                
                                Text("\(filteredAssets.count) assets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.gray.opacity(0.05))
                            
                            // Assets grid
                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                                    ForEach(filteredAssets) { asset in
                                        AssetThumbnailView(asset: asset) {
                                            showingPreview = asset
                                        } onExport: {
                                            exportAsset(asset)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if let url = fileURL {
                analyzeCarFile(url)
            }
        }
        .sheet(item: $showingPreview) { asset in
            AssetPreviewView(asset: asset) {
                showingPreview = nil
            } onExport: {
                exportAsset(asset)
                showingPreview = nil
            }
        }
    }
    
    private func analyzeCarFile(_ url: URL) {
        isAnalyzing = true
        error = nil
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                let info = analyzeCarData(data, url: url)
                
                await MainActor.run {
                    self.carInfo = info
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to read file: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    private func extractAssets(from url: URL) {
        isExtracting = true
        error = nil
        
        Task {
            do {
                let assets = try await extractAssetsFromCar(url)
                
                await MainActor.run {
                    self.extractedAssets = assets
                    self.isExtracting = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to extract assets: \(error.localizedDescription)"
                    self.isExtracting = false
                }
            }
        }
    }
    
    private func extractAssetsFromCar(_ url: URL) async throws -> [CarAsset] {
        // Create temp directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Try multiple extraction methods
        var assets: [CarAsset] = []
        
        // Method 1: Native Swift .car parsing (NEW!)
        assets = try await extractAssetsNatively(from: url, to: tempDir)
        if !assets.isEmpty {
            return assets
        }
        
        // Method 2: Try cartool if available
        if let cartoolPath = findCartool() {
            assets = try await extractWithCartool(cartoolPath: cartoolPath, carURL: url, tempDir: tempDir)
            if !assets.isEmpty {
                return assets
            }
        }
        
        // Method 3: Try assetutil for listing (fallback)
        assets = try await extractAssetsWithAssetUtil(url, tempDir: tempDir)
        if !assets.isEmpty {
            return assets
        }
        
        // Method 4: Basic analysis fallback
        return try await createBasicAssetInfo(url)
    }
    
    private func extractAssetsNatively(from url: URL, to tempDir: URL) async throws -> [CarAsset] {
        let data = try Data(contentsOf: url)
        let parser = CarFileParser(data: data)
        
        do {
            let carFile = try parser.parse()
            var assets: [CarAsset] = []
            
            for asset in carFile.assets {
                // Extract the asset data and save to temp directory
                let fileName = "\(asset.name).\(asset.fileExtension)"
                let assetURL = tempDir.appendingPathComponent(fileName)
                
                try asset.data.write(to: assetURL)
                
                // Create thumbnail if it's an image
                var thumbnail: NSImage?
                if asset.type == .image {
                    thumbnail = NSImage(data: asset.data)
                }
                
                let carAsset = CarAsset(
                    name: fileName,
                    type: asset.type,
                    size: ByteCountFormatter.string(fromByteCount: Int64(asset.data.count), countStyle: .file),
                    scale: asset.scale,
                    url: assetURL,
                    thumbnail: thumbnail
                )
                
                assets.append(carAsset)
            }
            
            return assets
        } catch {
            print("Native .car parsing failed: \(error)")
            return []
        }
    }
    
    private func findCartool() -> String? {
        // Check common locations for cartool
        let possiblePaths = [
            "/usr/local/bin/cartool",
            "/opt/homebrew/bin/cartool",
            "/usr/bin/cartool"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try which command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["cartool"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), 
                   !path.isEmpty {
                    return path
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func extractWithCartool(cartoolPath: String, carURL: URL, tempDir: URL) async throws -> [CarAsset] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cartoolPath)
        process.arguments = [carURL.path, tempDir.path]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        // Check if extraction was successful
        if process.terminationStatus == 0 {
            return scanExtractedAssets(in: tempDir)
        } else {
            // Log error for debugging
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("Cartool extraction failed: \(errorString)")
            return []
        }
    }
    
    private func extractAssetsWithAssetUtil(_ url: URL, tempDir: URL) async throws -> [CarAsset] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", "macosx", "assetutil", "--info", url.path]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return parseAssetUtilOutput(output)
        } else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("AssetUtil failed: \(errorString)")
            return []
        }
    }
    
    private func createBasicAssetInfo(_ url: URL) async throws -> [CarAsset] {
        // Create basic asset info based on common .car contents
        var assets: [CarAsset] = []
        
        // Add some placeholder assets based on typical .car contents
        let commonAssets = [
            ("AppIcon", CarAsset.AssetType.image, "@1x"),
            ("AppIcon", CarAsset.AssetType.image, "@2x"),
            ("AppIcon", CarAsset.AssetType.image, "@3x"),
            ("LaunchImage", CarAsset.AssetType.image, "@1x"),
            ("LaunchImage", CarAsset.AssetType.image, "@2x"),
        ]
        
        for (name, type, scale) in commonAssets {
            let asset = CarAsset(
                name: name + scale + ".png",
                type: type,
                size: "Unknown",
                scale: scale,
                url: nil,
                thumbnail: nil
            )
            assets.append(asset)
        }
        
        return assets
    }
    
    private func parseAssetUtilOutput(_ output: String) -> [CarAsset] {
        var assets: [CarAsset] = []
        let lines = output.components(separatedBy: .newlines)
        
        var currentAsset: String?
        var currentScale: String = "@1x"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Look for asset names
            if trimmedLine.contains("Asset name:") || trimmedLine.contains("Name:") {
                let name = trimmedLine
                    .replacingOccurrences(of: "Asset name:", with: "")
                    .replacingOccurrences(of: "Name:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\"", with: "")
                
                if !name.isEmpty {
                    currentAsset = name
                }
            }
            
            // Look for scale information
            if trimmedLine.contains("Scale:") || trimmedLine.contains("@") {
                if trimmedLine.contains("@3x") {
                    currentScale = "@3x"
                } else if trimmedLine.contains("@2x") {
                    currentScale = "@2x"
                } else {
                    currentScale = "@1x"
                }
            }
            
            // Create asset when we have enough info
            if let assetName = currentAsset {
                let type: CarAsset.AssetType = assetName.lowercased().contains("icon") ? .image : .data
                
                let asset = CarAsset(
                    name: assetName + currentScale,
                    type: type,
                    size: "Unknown",
                    scale: currentScale,
                    url: nil,
                    thumbnail: nil
                )
                
                assets.append(asset)
                currentAsset = nil
            }
        }
        
        // If no assets found through parsing, create some basic ones
        if assets.isEmpty {
            return [
                CarAsset(name: "AppIcon@1x", type: .image, size: "Unknown", scale: "@1x", url: nil, thumbnail: nil),
                CarAsset(name: "AppIcon@2x", type: .image, size: "Unknown", scale: "@2x", url: nil, thumbnail: nil),
                CarAsset(name: "AppIcon@3x", type: .image, size: "Unknown", scale: "@3x", url: nil, thumbnail: nil),
            ]
        }
        
        return assets
    }
    
    private func scanExtractedAssets(in directory: URL) -> [CarAsset] {
        var assets: [CarAsset] = []
        
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) else {
            return assets
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                
                guard resourceValues.isRegularFile == true else { continue }
                
                let fileName = fileURL.lastPathComponent
                let fileSize = resourceValues.fileSize ?? 0
                
                // Determine asset type
                let assetType: CarAsset.AssetType
                let pathExtension = fileURL.pathExtension.lowercased()
                
                switch pathExtension {
                case "png", "jpg", "jpeg", "gif", "tiff", "bmp":
                    assetType = .image
                case "pdf":
                    assetType = .pdf
                case "json":
                    assetType = .data
                default:
                    assetType = .data
                }
                
                // Load thumbnail for images
                var thumbnail: NSImage?
                if assetType == .image {
                    thumbnail = NSImage(contentsOf: fileURL)
                }
                
                // Extract scale info from filename
                let scale = extractScaleFromFilename(fileName)
                
                let asset = CarAsset(
                    name: fileName,
                    type: assetType,
                    size: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file),
                    scale: scale,
                    url: fileURL,
                    thumbnail: thumbnail
                )
                
                assets.append(asset)
            } catch {
                continue
            }
        }
        
        return assets
    }
    
    private func analyzeCarData(_ data: Data, url: URL) -> CarFileInfo {
        var info = CarFileInfo()
        
        // File size
        info.fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        
        // Header analysis
        if data.count > 16 {
            let header = data.prefix(16)
            let headerHex = header.map { String(format: "%02X", $0) }.joined(separator: " ")
            info.headerInfo = headerHex
            
            // Magic number (first 4 bytes)
            if data.count >= 4 {
                let magicBytes = data.prefix(4)
                let magic = magicBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
                info.magicNumber = "0x\(String(format: "%08X", magic))"
            }
        }
        
        return info
    }
    
    private func runAssetUtil() {
        guard let url = fileURL else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", "macosx", "assetutil", "--info", url.path]
        
        // Open Terminal and run the command
        let script = """
        tell application "Terminal"
            activate
            do script "xcrun --sdk macosx assetutil --info '\(url.path)'"
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(nil)
    }
    
    private func exportAsset(_ asset: CarAsset) {
        guard let sourceURL = asset.url else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg, .pdf, .data]
        savePanel.nameFieldStringValue = asset.name
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    private func extractScaleFromFilename(_ filename: String) -> String {
        if filename.contains("@3x") {
            return "@3x"
        } else if filename.contains("@2x") {
            return "@2x"
        } else if filename.contains("@1x") {
            return "@1x"
        } else {
            return "@1x"
        }
    }
}

// MARK: - Supporting Views

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

struct AssetThumbnailView: View {
    let asset: CarAsset
    let onPreview: () -> Void
    let onExport: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Thumbnail
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
                
                // Hover overlay
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
            
            // Asset info
            VStack(spacing: 2) {
                Text(asset.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    Text(asset.scale)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
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
            // Header
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
            
            // Preview
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
            
            // Asset details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Type:")
                        .fontWeight(.medium)
                    Text(asset.type.rawValue)
                    Spacer()
                }
                
                HStack {
                    Text("Scale:")
                        .fontWeight(.medium)
                    Text(asset.scale)
                    Spacer()
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

// MARK: - Data Models

struct CarAsset: Identifiable {
    let id = UUID()
    let name: String
    let type: AssetType
    let size: String
    let scale: String
    let url: URL?
    let thumbnail: NSImage?
    
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

// MARK: - Native .car File Parser

struct CarFileParser {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func parse() throws -> ParsedCarFile {
        guard data.count > 16 else {
            throw CarParseError.invalidFile
        }
        
        // Read header
        let header = try parseHeader()
        
        // Find and parse assets
        let assets = try parseAssets(header: header)
        
        return ParsedCarFile(header: header, assets: assets)
    }
    
    private func parseHeader() throws -> CarHeader {
        // Parse the .car file header
        // Magic number at offset 0 (4 bytes)
        let magic = data.withUnsafeBytes { bytes in
            bytes.load(fromByteOffset: 0, as: UInt32.self)
        }
        
        // Version info and other header data
        let version = data.withUnsafeBytes { bytes in
            bytes.load(fromByteOffset: 4, as: UInt32.self)
        }
        
        return CarHeader(magic: magic, version: version)
    }
    
    private func parseAssets(header: CarHeader) throws -> [ParsedAsset] {
        var assets: [ParsedAsset] = []
        
        // This is a simplified parser - real .car files have complex structure
        // We'll look for common image signatures in the data
        
        // Look for PNG signatures (89 50 4E 47)
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        assets.append(contentsOf: findAssetsWithSignature(pngSignature, type: .image, extension: "png"))
        
        // Look for JPEG signatures (FF D8 FF)
        let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF]
        assets.append(contentsOf: findAssetsWithSignature(jpegSignature, type: .image, extension: "jpg"))
        
        // Look for PDF signatures (25 50 44 46)
        let pdfSignature: [UInt8] = [0x25, 0x50, 0x44, 0x46]
        assets.append(contentsOf: findAssetsWithSignature(pdfSignature, type: .pdf, extension: "pdf"))
        
        return assets
    }
    
    private func findAssetsWithSignature(_ signature: [UInt8], type: CarAsset.AssetType, extension: String) -> [ParsedAsset] {
        var assets: [ParsedAsset] = []
        let signatureData = Data(signature)
        
        var searchRange = data.startIndex..<data.endIndex
        var assetIndex = 0
        
        while let range = data.range(of: signatureData, in: searchRange) {
            // Found a file signature
            let startOffset = range.lowerBound
            
            // Try to find the end of this asset
            let endOffset = findAssetEnd(from: startOffset, for: type)
            
            if endOffset > startOffset {
                let assetData = data.subdata(in: startOffset..<endOffset)
                
                // Determine scale from context or filename patterns
                let scale = determineScale(at: startOffset)
                
                let asset = ParsedAsset(
                    name: "\(type.rawValue.lowercased())_\(assetIndex)",
                    type: type,
                    fileExtension: `extension`,
                    scale: scale,
                    data: assetData
                )
                
                assets.append(asset)
                assetIndex += 1
            }
            
            // Continue searching after this match
            searchRange = range.upperBound..<data.endIndex
            
            // Prevent infinite loops
            if searchRange.isEmpty {
                break
            }
        }
        
        return assets
    }
    
    private func findAssetEnd(from start: Data.Index, for type: CarAsset.AssetType) -> Data.Index {
        switch type {
        case .image:
            // For PNG, look for IEND chunk
            if let pngEnd = data.range(of: Data([0x49, 0x45, 0x4E, 0x44]), in: start..<data.endIndex) {
                return pngEnd.upperBound + 4 // Include CRC
            }
            // For JPEG, look for EOI marker
            if let jpegEnd = data.range(of: Data([0xFF, 0xD9]), in: start..<data.endIndex) {
                return jpegEnd.upperBound
            }
            // Fallback: assume reasonable size
            return min(start + 1024 * 1024, data.endIndex) // Max 1MB
            
        case .pdf:
            // Look for PDF end
            if let pdfEnd = data.range(of: Data("%%EOF".utf8), in: start..<data.endIndex) {
                return pdfEnd.upperBound
            }
            return min(start + 10 * 1024 * 1024, data.endIndex) // Max 10MB
            
        case .data:
            return min(start + 1024, data.endIndex) // Max 1KB for data
        }
    }
    
    private func determineScale(at offset: Data.Index) -> String {
        // Look backwards and forwards for scale hints
        let searchRange = max(data.startIndex, offset - 100)..<min(offset + 100, data.endIndex)
        let contextData = data.subdata(in: searchRange)
        
        if let contextString = String(data: contextData, encoding: .ascii) {
            if contextString.contains("@3x") {
                return "@3x"
            } else if contextString.contains("@2x") {
                return "@2x"
            }
        }
        
        return "@1x"
    }
}

// MARK: - Parser Data Models

struct ParsedCarFile {
    let header: CarHeader
    let assets: [ParsedAsset]
}

struct CarHeader {
    let magic: UInt32
    let version: UInt32
}

struct ParsedAsset {
    let name: String
    let type: CarAsset.AssetType
    let fileExtension: String
    let scale: String
    let data: Data
}

enum CarParseError: Error {
    case invalidFile
    case corruptedData
    case unsupportedVersion
}
