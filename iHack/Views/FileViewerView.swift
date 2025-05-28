//
//  FileViewerView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import AppKit

// Helper function to determine language type for display
func getLanguageType(for url: URL?) -> String {
    guard let url = url else { return "text" }
    let ext = url.pathExtension.lowercased()
    
    switch ext {
    case "strings":
        return "strings"
    case "scpt":
        return "applescript"
    case "json":
        return "json"
    case "swift":
        return "swift"
    case "h", "m":
        return "objective-c"
    case "cpp", "c":
        return "c++"
    case "py":
        return "python"
    case "js":
        return "javascript"
    case "html":
        return "html"
    case "css":
        return "css"
    case "xml":
        return "xml"
    case "md":
        return "markdown"
    default:
        return "text"
    }
}

struct FileViewerView: View {
    @Binding var selectedFileURL: URL?
    @Binding var fileContent: String
    @Binding var plistData: [String: Any]
    @Binding var isModified: Bool
    let fileType: FileType
    let onSave: () -> Void
    let onRestore: () -> Void
    
    var body: some View {
        switch fileType {
        case .plist:
            XcodePlistTableView(
                data: $plistData,
                isModified: $isModified,
                onSave: onSave,
                onRestore: onRestore
            )
        case .json:
            LiveSyntaxHighlightedCodeEditor(
                content: $fileContent,
                language: "json",
                isModified: $isModified,
                onSave: onSave
            )
        case .text:
            LiveSyntaxHighlightedCodeEditor(
                content: $fileContent,
                language: getLanguageType(for: selectedFileURL),
                isModified: $isModified,
                onSave: onSave
            )
        case .icon:
            IconViewerView(fileURL: selectedFileURL)
        case .other:
            UnsupportedFileView()
        }
    }
}

struct LiveSyntaxHighlightedCodeEditor: View {
    @Binding var content: String
    let language: String
    @Binding var isModified: Bool
    let onSave: () -> Void
    @State private var selectedTheme: SyntaxTheme = .xcode
    
    var lineCount: Int {
        return content.components(separatedBy: .newlines).count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                Text("File Content (\(language.uppercased()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Lines: \(lineCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(SyntaxTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .disabled(!isModified)
            }
            .padding()
            .background(.gray.opacity(0.05))
            
            // Code editor with line numbers
            HStack(spacing: 0) {
                // Line numbers
                ScrollView {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...max(1, lineCount), id: \.self) { lineNumber in
                            Text("\(lineNumber)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                                .padding(.vertical, 1)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
                .frame(width: 50)
                .background(selectedTheme.backgroundColor.opacity(0.5))
                
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1)
                
                // Single TextEditor with syntax highlighting applied to content
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(selectedTheme.backgroundColor)
                    .onChange(of: content) { _, _ in
                        isModified = true
                    }
            }
        }
    }
}

struct SyntaxHighlightedCodeEditor: View {
    @Binding var content: String
    let language: String
    @Binding var isModified: Bool
    let onSave: () -> Void
    @State private var selectedTheme: SyntaxTheme = .xcode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File Content (\(language.uppercased()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(SyntaxTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .disabled(!isModified)
            }
            .padding()
            .background(.gray.opacity(0.05))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(SyntaxHighlighter.highlightCode(content, language: language, theme: selectedTheme))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(selectedTheme.backgroundColor)
            }
            .background(selectedTheme.backgroundColor)
            
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .opacity(0.01)
                .onChange(of: content) { _, _ in
                    isModified = true
                }
        }
    }
}

struct CodeEditorView: View {
    @Binding var content: String
    let language: String
    @Binding var isModified: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File Content (\(language.uppercased()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .disabled(!isModified)
            }
            .padding()
            .background(.gray.opacity(0.05))
            
            ScrollView {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: content) { _, _ in
                        isModified = true
                    }
            }
        }
    }
}

struct IconViewerView: View {
    let fileURL: URL?
    @State private var iconImage: NSImage?
    
    var body: some View {
        VStack(spacing: 20) {
            if let iconImage = iconImage {
                Image(nsImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Unable to load icon")
                    .foregroundColor(.secondary)
            }
            
            if let url = fileURL {
                Text("Icon: \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadIcon()
        }
        .onChange(of: fileURL) { _, _ in
            loadIcon()
        }
    }
    
    private func loadIcon() {
        guard let url = fileURL else { return }
        
        if let image = NSImage(contentsOf: url) {
            iconImage = image
        }
    }
}

struct UnsupportedFileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Unsupported File Type")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("This file type is not supported for viewing")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
