//
//  CarViewerView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import Foundation

struct CarViewerView: View {
    let fileURL: URL?
    @State private var carInfo: CarFileInfo = CarFileInfo()
    @State private var isAnalyzing = false
    @State private var error: String?
    
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
                    Button("Analyze") {
                        analyzeCarFile(url)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAnalyzing)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            if isAnalyzing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Analyzing Asset Catalog...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                    description: "Official Apple tool for .car analysis"
                                )
                                
                                ToolRow(
                                    name: "Asset Catalog Tinkerer",
                                    command: "Third-party GUI app",
                                    description: "Visual tool for browsing .car contents"
                                )
                                
                                ToolRow(
                                    name: "cartool",
                                    command: "cartool /path/to/Assets.car /output/directory",
                                    description: "Command-line tool to extract assets"
                                )
                            }
                        }
                        
                        // Warning Section
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Important Note")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(".car files are compiled binary formats that cannot be directly edited. To modify app assets, you need to edit the original .xcassets files in Xcode and recompile the project.")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
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