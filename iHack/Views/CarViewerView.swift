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
        case iconSet = "Icon Sets"
        case data = "Data"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .image: return "photo"
            case .icon: return "app"
            case .iconSet: return "app.badge"
            case .data: return "doc"
            }
        }
    }
    
    var filteredAssets: [CarAsset] {
        var filtered = extractedAssets
        
        if selectedAssetType != .all {
            filtered = filtered.filter { asset in
                switch selectedAssetType {
                case .image:
                    return asset.type == .image && !asset.name.lowercased().contains("appicon")
                case .icon:
                    return asset.name.lowercased().contains("icon") || asset.name.lowercased().contains("appicon")
                case .iconSet:
                    return asset.isIconSet == true
                case .data:
                    return asset.type == .data
                case .all:
                    return true
                }
            }
        }
        
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
                        .scaleEffect(1.0)
                        .frame(width: 40, height: 40)
                    
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
                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 0) {
                        TabButton(title: "File Info", isSelected: extractedAssets.isEmpty) {
                            // File info view
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
                        CarFileInfoView(carInfo: carInfo, fileURL: fileURL, extractedAssets: extractedAssets)
                    } else {
                        CarAssetsView(
                            filteredAssets: filteredAssets,
                            searchText: $searchText,
                            selectedAssetType: $selectedAssetType,
                            extractedAssets: extractedAssets,
                            onPreview: { asset in
                                showingPreview = asset
                            },
                            onExport: { asset in
                                exportAsset(asset)
                            },
                            onExportAll: {
                                exportAllAssets()
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            if let url = fileURL {
                analyzeCarFile(url)
            }
        }
    }
    
    private func analyzeCarFile(_ url: URL) {
        isAnalyzing = true
        error = nil
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                let info = await CarFileAnalyzer.analyzeCarDataEnhanced(data, url: url)
                
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
                let assets = try await CarAssetExtractor.extractAssets(from: url)
                
                await MainActor.run {
                    self.extractedAssets = assets
                    self.isExtracting = false
                    
                    if !assets.isEmpty {
                        let totalSize = assets.compactMap { asset in
                            guard let url = asset.url else { return Int64(0) }
                            let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int64 ?? 0
                            return size
                        }.reduce(Int64(0), +)
                        let sizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                        print("Extracted \(assets.count) assets (\(sizeString) total)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to extract assets: \(error.localizedDescription)"
                    self.isExtracting = false
                }
            }
        }
    }
    
    private func exportAsset(_ asset: CarAsset) {
        CarAssetExporter.exportAsset(asset, estimatedAssetCount: extractedAssets.count)
    }
    
    private func exportAllAssets() {
        CarAssetExporter.exportAllAssets(extractedAssets)
    }
}
