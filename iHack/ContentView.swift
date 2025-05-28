//
//  ContentView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var selectedFileURL: URL?
    @State private var plistData: [String: Any] = [:]
    @State private var showingFilePicker = false
    @State private var statusMessage = "Select an app to browse its contents"
    @State private var isModified = false
    @State private var searchText = ""
    @State private var apps: [AppBundle] = []
    @State private var isLoadingApps = false
    @State private var showingEditor = false
    @State private var showingAppBrowser = false
    @State private var selectedApp: AppBundle?
    @State private var appContents: [AppContentItem] = []

    var body: some View {
        Group {
            if showingEditor {
                NavigationSplitView {
                    VStack(spacing: 0) {
                        HStack {
                            Button("← Apps") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingEditor = false
                                    showingAppBrowser = true
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let app = selectedApp {
                                Text(app.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.1))
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(getFlattenedItems(appContents)) { item in
                                    XcodeFileRowView(
                                        item: item,
                                        selectedURL: selectedFileURL,
                                        onSelect: { selectedItem in
                                            if selectedItem.isPlist {
                                                loadPlistFile(from: selectedItem.url)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .frame(minWidth: 250)
                } detail: {
                    VStack(spacing: 0) {
                        HStack {
                            if let app = selectedApp {
                                HStack(spacing: 4) {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text(app.name)
                                        .foregroundColor(.primary)
                                    
                                    if selectedFileURL != nil {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption2)
                                        Text("Contents")
                                            .foregroundColor(.primary)
                                        
                                        if let url = selectedFileURL {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                                .font(.caption2)
                                            Text(url.lastPathComponent)
                                                .foregroundColor(.primary)
                                        }
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption2)
                                        Text("No Selection")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .font(.caption)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.gray.opacity(0.05))
                        
                        Rectangle()
                            .fill(.separator)
                            .frame(height: 0.5)
                        
                        if plistData.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No Selection")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("Select a plist file from the navigator")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            XcodePlistTableView(
                                data: $plistData,
                                isModified: $isModified,
                                onSave: saveFile
                            )
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else if showingAppBrowser {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            Button("← Apps") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingAppBrowser = false
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)

                            Spacer()

                            if let app = selectedApp {
                                HStack(spacing: 12) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .cornerRadius(6)
                                    }

                                    Text(app.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.black)

                        Rectangle()
                            .fill(.green.opacity(0.3))
                            .frame(height: 1)
                    }

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(appContents) { item in
                                AppContentRowView(
                                    item: item,
                                    onSelect: { selectedItem in
                                        if selectedItem.isPlist {
                                            loadPlistFile(from: selectedItem.url)
                                            showingEditor = true
                                            showingAppBrowser = false
                                        }
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }

                    HStack {
                        Text("\(appContents.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.8))
                }
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "app.badge")
                                    .foregroundColor(.green)
                                    .font(.title2)

                                Text("iHack")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Text("\(apps.count) apps found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.black)

                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)

                                TextField("Search apps...", text: $searchText)
                                    .textFieldStyle(.plain)

                                if !searchText.isEmpty {
                                    Button("Clear") {
                                        searchText = ""
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.gray.opacity(0.2))
                            .cornerRadius(8)

                            Button("Refresh") {
                                withAnimation {
                                    loadApps()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(.gray.opacity(0.05))

                        Rectangle()
                            .fill(.green.opacity(0.3))
                            .frame(height: 1)
                    }

                    if isLoadingApps {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.green)

                            Text("Scanning applications...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        LaunchpadView(
                            apps: filteredApps,
                            onSelectApp: { app in
                                loadAppContents(for: app)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingEditor = true
                                }
                            }
                        )
                    }
                }
                .onAppear {
                    if apps.isEmpty {
                        loadApps()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.propertyList],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    func loadAppContents(for app: AppBundle) {
        selectedApp = app
        appContents = []

        let contentsURL = URL(fileURLWithPath: app.path).appendingPathComponent("Contents")

        func scanDirectory(_ url: URL, depth: Int = 0) -> [AppContentItem] {
            var items: [AppContentItem] = []

            guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) else {
                return items
            }

            for itemURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

                let item = AppContentItem(
                    name: itemURL.lastPathComponent,
                    url: itemURL,
                    isDirectory: isDirectory,
                    isPlist: itemURL.pathExtension.lowercased() == "plist",
                    depth: depth
                )
                
                if isDirectory && depth < 3 {
                    item.children = scanDirectory(itemURL, depth: depth + 1)
                }
                
                items.append(item)
            }

            return items
        }

        appContents = scanDirectory(contentsURL)
        statusMessage = "Loaded \(countAllItems(appContents)) items from \(app.name)"
    }
    
    func countAllItems(_ items: [AppContentItem]) -> Int {
        var count = items.count
        for item in items {
            count += countAllItems(item.children)
        }
        return count
    }
    
    func getFlattenedItems(_ items: [AppContentItem]) -> [AppContentItem] {
        var result: [AppContentItem] = []
        
        for item in items {
            result.append(item)
            if item.isDirectory && item.isExpanded {
                result.append(contentsOf: getFlattenedItems(item.children))
            }
        }
        
        return result
    }

    var filteredApps: [AppBundle] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadApps() {
        isLoadingApps = true
        apps = []
        
        Task {
            var foundApps: [AppBundle] = []
            
            let appPaths = [
                "/Applications",
                "/System/Applications",
                FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
            ]
            
            for appPath in appPaths {
                let url = URL(fileURLWithPath: appPath)
                if let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                    for appURL in contents where appURL.pathExtension == "app" {
                        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
                        if FileManager.default.fileExists(atPath: infoPlistURL.path) {
                            let app = AppBundle(
                                name: appURL.deletingPathExtension().lastPathComponent,
                                path: appURL.path,
                                infoPlistPath: infoPlistURL.path
                            )
                            foundApps.append(app)
                        }
                    }
                }
            }
            
            await MainActor.run {
                self.apps = foundApps.sorted { $0.name < $1.name }
                self.isLoadingApps = false
                self.statusMessage = "Found \(foundApps.count) apps"
            }
        }
    }
    
    func backupFile() {
        guard let url = selectedFileURL else { return }
        
        let backupURL = url.appendingPathExtension("backup")
        do {
            try FileManager.default.copyItem(at: url, to: backupURL)
            statusMessage = "Backup created: \(backupURL.lastPathComponent)"
        } catch {
            statusMessage = "Backup failed: \(error.localizedDescription)"
        }
    }
    
    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            loadPlistFile(from: url)
        case .failure(let error):
            statusMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    func loadPlistFile(from url: URL) {
        selectedFileURL = url
        
        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
            
            if let dict = plist as? [String: Any] {
                plistData = dict
                statusMessage = "Loaded \(dict.keys.count) keys from \(url.lastPathComponent)"
                isModified = false
            } else {
                statusMessage = "Error: Not a valid plist dictionary"
            }
        } catch {
            statusMessage = "Load error: \(error.localizedDescription)"
        }
    }
    
    func saveFile() {
        guard let url = selectedFileURL else { return }
        
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: plistData,
                format: .xml,
                options: 0
            )
            try data.write(to: url)
            statusMessage = "Saved successfully"
            isModified = false
        } catch {
            statusMessage = "Save error: \(error.localizedDescription)"
        }
    }
}

class AppContentItem: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let isPlist: Bool
    let depth: Int
    @Published var isExpanded: Bool = false
    var children: [AppContentItem] = []
    
    init(name: String, url: URL, isDirectory: Bool, isPlist: Bool, depth: Int) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isPlist = isPlist
        self.depth = depth
    }
}

struct XcodeFileRowView: View {
    @ObservedObject var item: AppContentItem
    let selectedURL: URL?
    let onSelect: (AppContentItem) -> Void
    @State private var isHovered = false
    
    var isSelected: Bool {
        selectedURL == item.url
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Indentation
            HStack(spacing: 0) {
                ForEach(0..<item.depth, id: \.self) { _ in
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 16)
                }
            }
            
            // Disclosure triangle
            if item.isDirectory && !item.children.isEmpty {
                Button(action: {
                    item.isExpanded.toggle()
                }) {
                    Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 12, height: 12)
            }
            
            // File icon
            Image(systemName: item.isDirectory ? "folder.fill" : (item.isPlist ? "doc.text.fill" : "doc.fill"))
                .foregroundColor(item.isDirectory ? .blue : (item.isPlist ? .green : .secondary))
                .font(.system(size: 14))
                .frame(width: 16)
            
            // File name
            Text(item.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(isSelected ? .blue : (isHovered ? .gray.opacity(0.2) : .clear))
        .cornerRadius(4)
        .onTapGesture {
            if !item.isDirectory {
                onSelect(item)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct XcodePlistTableView: View {
    @Binding var data: [String: Any]
    @Binding var isModified: Bool
    let onSave: () -> Void
    @State private var searchText = ""
    
    var filteredKeys: [String] {
        let keys = Array(data.keys).sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Key")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 200, alignment: .leading)
                
                Text("Type")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 80, alignment: .leading)
                
                Text("Value")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("")
                    .frame(width: 100)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.1))
            
            Rectangle()
                .fill(.separator)
                .frame(height: 0.5)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredKeys, id: \.self) { key in
                        XcodePlistRowView(
                            key: key,
                            value: data[key] ?? "",
                            onValueChange: { newValue in
                                data[key] = newValue
                                isModified = true
                            },
                            onDelete: {
                                data.removeValue(forKey: key)
                                isModified = true
                            }
                        )
                        
                        Rectangle()
                            .fill(.separator.opacity(0.5))
                            .frame(height: 0.5)
                    }
                }
            }
            
            HStack {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .disabled(!isModified)
                
                Spacer()
                
                Text("\(filteredKeys.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.05))
        }
    }
}

struct XcodePlistRowView: View {
    let key: String
    let value: Any
    let onValueChange: (Any) -> Void
    let onDelete: () -> Void
    
    @State private var editingValue = ""
    @State private var isEditing = false
    @State private var isHovered = false
    
    var valueType: String {
        if value is String { return "String" }
        if value is NSNumber { return "Number" }
        if value is Bool { return "Boolean" }
        if value is [Any] { return "Array" }
        if value is [String: Any] { return "Dictionary" }
        return "Unknown"
    }
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .frame(minWidth: 200, alignment: .leading)
            
            Text(valueType)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            
            if isEditing {
                TextField("Value", text: $editingValue)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(stringValue(from: value))
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        if !(value is [Any]) && !(value is [String: Any]) {
                            startEditing()
                        }
                    }
            }
            
            HStack(spacing: 4) {
                if isEditing {
                    Button("Save") {
                        commitEdit()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    
                    Button("Cancel") {
                        cancelEdit()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(value is [Any] || value is [String: Any])
                }
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundColor(.red)
            }
            .frame(width: 100)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isHovered ? .gray.opacity(0.1) : .clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    func stringValue(from value: Any) -> String {
        if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number.stringValue
        } else if let bool = value as? Bool {
            return bool ? "YES" : "NO"
        } else if let array = value as? [Any] {
            return "(\(array.count) items)"
        } else if let dict = value as? [String: Any] {
            return "(\(dict.keys.count) items)"
        }
        return "\(value)"
    }
    
    func startEditing() {
        editingValue = stringValue(from: value)
        isEditing = true
    }
    
    func commitEdit() {
        if let number = Double(editingValue) {
            onValueChange(number)
        } else if editingValue.lowercased() == "yes" || editingValue.lowercased() == "true" {
            onValueChange(true)
        } else if editingValue.lowercased() == "no" || editingValue.lowercased() == "false" {
            onValueChange(false)
        } else {
            onValueChange(editingValue)
        }
        isEditing = false
    }
    
    func cancelEdit() {
        isEditing = false
        editingValue = ""
    }
}

struct AppContentRowView: View {
    let item: AppContentItem
    let onSelect: (AppContentItem) -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isDirectory ? "folder.fill" : (item.isPlist ? "doc.text.fill" : "doc.fill"))
                .foregroundColor(item.isDirectory ? .blue : (item.isPlist ? .green : .secondary))
                .frame(width: 20)

            Text(item.name)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.isPlist {
                Button("Edit") {
                    onSelect(item)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovered ? .gray.opacity(0.1) : .clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct PlistEditorView: View {
    @Binding var data: [String: Any]
    @Binding var isModified: Bool
    let onSave: () -> Void
    @Binding var searchText: String

    var filteredKeys: [String] {
        let keys = Array(data.keys).sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)

                    TextField("Search keys...", text: $searchText)
                        .textFieldStyle(.plain)

                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.2))
                .cornerRadius(6)

                Spacer()

                Button("Save All Changes") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!isModified)
            }
            .padding(16)
            .background(.black.opacity(0.8))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredKeys, id: \.self) { key in
                        PlistRowView(
                            key: key,
                            value: data[key] ?? "",
                            onValueChange: { newValue in
                                data[key] = newValue
                                isModified = true
                            },
                            onDelete: {
                                data.removeValue(forKey: key)
                                isModified = true
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
    }
}

struct PlistRowView: View {
    let key: String
    let value: Any
    let onValueChange: (Any) -> Void
    let onDelete: () -> Void

    @State private var editingValue = ""
    @State private var isEditing = false
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
                .frame(width: 220, alignment: .leading)
                .fontWeight(.medium)

            if isEditing {
                TextField("Value", text: $editingValue)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(stringValue(from: value))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        startEditing()
                    }
            }

            HStack(spacing: 8) {
                if isEditing {
                    Button("Save") {
                        commitEdit()
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .controlSize(.small)

                    Button("Cancel") {
                        cancelEdit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
                }

                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(isHovered ? .gray.opacity(0.1) : .clear)
        .overlay(
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    func stringValue(from value: Any) -> String {
        if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number.stringValue
        } else if let bool = value as? Bool {
            return bool ? "true" : "false"
        } else if let array = value as? [Any] {
            return "Array (\(array.count) items)"
        } else if let dict = value as? [String: Any] {
            return "Dictionary (\(dict.keys.count) keys)"
        }
        return "\(value)"
    }

    func startEditing() {
        editingValue = stringValue(from: value)
        isEditing = true
    }

    func commitEdit() {
        if let number = Double(editingValue) {
            onValueChange(number)
        } else if editingValue.lowercased() == "true" {
            onValueChange(true)
        } else if editingValue.lowercased() == "false" {
            onValueChange(false)
        } else {
            onValueChange(editingValue)
        }
        isEditing = false
    }

    func cancelEdit() {
        isEditing = false
        editingValue = ""
    }
}

struct AppBundle: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let infoPlistPath: String
    let icon: NSImage?

    init(name: String, path: String, infoPlistPath: String) {
        self.name = name
        self.path = path
        self.infoPlistPath = infoPlistPath
        self.icon = NSWorkspace.shared.icon(forFile: path)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var disabled = false

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(title)
                    .foregroundColor(.green)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.green.opacity(disabled ? 0.3 : 1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct LaunchpadView: View {
    let apps: [AppBundle]
    let onSelectApp: (AppBundle) -> Void

    let columns = Array(repeating: GridItem(.flexible(), spacing: 40), count: 7)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(apps) { app in
                    LaunchpadAppView(app: app, onSelect: { onSelectApp(app) })
                }
            }
            .padding(40)
        }
    }
}

struct LaunchpadAppView: View {
    let app: AppBundle
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onSelect) {
                VStack(spacing: 8) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .scaleEffect(isHovered ? 1.05 : 1.0)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.green.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "app")
                                    .font(.title)
                                    .foregroundColor(.green)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .scaleEffect(isHovered ? 1.05 : 1.0)
                    }

                    Text(app.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 90)
                }
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .frame(width: 90, height: 110)
    }
}

#Preview {
    ContentView()
}
