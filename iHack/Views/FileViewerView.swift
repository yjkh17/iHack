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
    let zoomLevel: Double
    
    var body: some View {
        Group {
            switch fileType {
            case .plist, .xcprivacy:
                XcodePlistTableView(
                    data: $plistData,
                    isModified: $isModified,
                    onSave: onSave,
                    onRestore: onRestore
                )
            case .json:
                SyntaxHighlightedTextEditor(
                    content: $fileContent,
                    language: "json",
                    isModified: $isModified,
                    onSave: onSave
                )
            case .text:
                SyntaxHighlightedTextEditor(
                    content: $fileContent,
                    language: getLanguageType(for: selectedFileURL),
                    isModified: $isModified,
                    onSave: onSave
                )
            case .icon:
                IconViewerView(fileURL: selectedFileURL)
            case .car:  
                CarViewerView(fileURL: selectedFileURL)
            case .other:
                UnsupportedFileView()
            }
        }
        .scaleEffect(zoomLevel)
    }
}

struct SyntaxHighlightedTextEditor: View {
    @Binding var content: String
    let language: String
    @Binding var isModified: Bool
    let onSave: () -> Void
    @State private var selectedTheme: SyntaxTheme = .xcode
    @State private var showingFindReplace = false
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var currentMatchIndex = 0
    @State private var totalMatches = 0
    @State private var caseSensitive = false
    @State private var useRegex = false
    @State private var matches: [Range<String.Index>] = []
    
    var lineCount: Int {
        return content.components(separatedBy: .newlines).count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("File Content (\(language.uppercased()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Lines: \(lineCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Find") {
                    showingFindReplace.toggle()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("f", modifiers: .command)
                
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
            
            if showingFindReplace {
                FindReplaceView(
                    findText: $findText,
                    replaceText: $replaceText,
                    content: $content,
                    isModified: $isModified,
                    currentMatchIndex: $currentMatchIndex,
                    totalMatches: $totalMatches,
                    caseSensitive: $caseSensitive,
                    useRegex: $useRegex,
                    matches: $matches,
                    onClose: {
                        showingFindReplace = false
                        findText = ""
                        replaceText = ""
                        matches = []
                        currentMatchIndex = 0
                        totalMatches = 0
                    }
                )
            }
            
            HStack(spacing: 0) {
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
                
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(selectedTheme.backgroundColor)
                    .onChange(of: content) { _, _ in
                        isModified = true
                        if showingFindReplace && !findText.isEmpty {
                            updateMatches()
                        }
                    }
            }
        }
        .onChange(of: findText) { _, _ in
            updateMatches()
        }
        .onChange(of: caseSensitive) { _, _ in
            updateMatches()
        }
        .onChange(of: useRegex) { _, _ in
            updateMatches()
        }
    }
    
    private func updateMatches() {
        guard !findText.isEmpty else {
            matches = []
            totalMatches = 0
            currentMatchIndex = 0
            return
        }
        
        let searchOptions: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
        matches = []
        
        if useRegex {
            do {
                let regex = try NSRegularExpression(pattern: findText, options: caseSensitive ? [] : [.caseInsensitive])
                let nsRange = NSRange(content.startIndex..<content.endIndex, in: content)
                let results = regex.matches(in: content, range: nsRange)
                
                matches = results.compactMap { result in
                    Range(result.range, in: content)
                }
            } catch {
                matches = findLiteralMatches(searchOptions: searchOptions)
            }
        } else {
            matches = findLiteralMatches(searchOptions: searchOptions)
        }
        
        totalMatches = matches.count
        currentMatchIndex = totalMatches > 0 ? 1 : 0
    }
    
    private func findLiteralMatches(searchOptions: String.CompareOptions) -> [Range<String.Index>] {
        var results: [Range<String.Index>] = []
        var searchRange = content.startIndex..<content.endIndex
        
        while let range = content.range(of: findText, options: searchOptions, range: searchRange) {
            results.append(range)
            searchRange = range.upperBound..<content.endIndex
        }
        
        return results
    }
}

struct FindReplaceView: View {
    @Binding var findText: String
    @Binding var replaceText: String
    @Binding var content: String
    @Binding var isModified: Bool
    @Binding var currentMatchIndex: Int
    @Binding var totalMatches: Int
    @Binding var caseSensitive: Bool
    @Binding var useRegex: Bool
    @Binding var matches: [Range<String.Index>]
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    TextField("Find", text: $findText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            findNext()
                        }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.gray.opacity(0.2))
                .cornerRadius(6)
                
                Button(action: findPrevious) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.bordered)
                .disabled(totalMatches == 0)
                .controlSize(.small)
                
                Button(action: findNext) {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.bordered)
                .disabled(totalMatches == 0)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: [])
                
                Text(totalMatches > 0 ? "\(currentMatchIndex)/\(totalMatches)" : "0/0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 40)
                
                Spacer()
                
                Button("✕") {
                    onClose()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            HStack {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.gray.opacity(0.2))
                .cornerRadius(6)
                
                Button("Replace") {
                    replaceCurrent()
                }
                .buttonStyle(.bordered)
                .disabled(totalMatches == 0)
                .controlSize(.small)
                
                Button("Replace All") {
                    replaceAll()
                }
                .buttonStyle(.bordered)
                .disabled(totalMatches == 0)
                .controlSize(.small)
                
                Spacer()
                
                Toggle("Aa", isOn: $caseSensitive)
                    .help("Case Sensitive")
                    .toggleStyle(.button)
                    .controlSize(.small)
                
                Toggle(".*", isOn: $useRegex)
                    .help("Use Regular Expression")
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
        .padding(.horizontal)
        .shadow(radius: 4)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            }
        }
    }
    
    private func findNext() {
        guard totalMatches > 0 else { return }
        currentMatchIndex = currentMatchIndex < totalMatches ? currentMatchIndex + 1 : 1
    }
    
    private func findPrevious() {
        guard totalMatches > 0 else { return }
        currentMatchIndex = currentMatchIndex > 1 ? currentMatchIndex - 1 : totalMatches
    }
    
    private func replaceCurrent() {
        guard totalMatches > 0, currentMatchIndex > 0, currentMatchIndex <= matches.count else { return }
        
        let matchRange = matches[currentMatchIndex - 1]
        content.replaceSubrange(matchRange, with: replaceText)
        isModified = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        }
    }
    
    private func replaceAll() {
        guard totalMatches > 0 else { return }
        
        for match in matches.reversed() {
            content.replaceSubrange(match, with: replaceText)
        }
        
        isModified = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
