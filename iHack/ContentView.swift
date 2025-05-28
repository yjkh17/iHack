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
    @State private var refreshTrigger = false

    var body: some View {
        Group {
            if showingEditor {
                NavigationSplitView {
                    VStack(spacing: 0) {
                        HStack {
                            Button("← Apps") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingEditor = false
                                    showingAppBrowser = false
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
                                    .onReceive(item.objectWillChange) { _ in
                                        refreshTrigger.toggle()
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .id(refreshTrigger)
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
                                onSave: saveFile,
                                onRestore: restoreFromBackup
                            )
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else if showingAppBrowser {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack {
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

    // MARK: - Helper Functions
    
    func loadAppContents(for app: AppBundle) {
        selectedApp = app
        appContents = []

        let appBundleURL = URL(fileURLWithPath: app.path)

        func scanDirectory(_ url: URL, depth: Int = 0) -> [AppContentItem] {
            var items: [AppContentItem] = []

            guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey]) else {
                return items
            }

            for itemURL in contents.sorted(by: { url1, url2 in
                let isDir1 = (try? url1.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let isDir2 = (try? url2.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                
                if isDir1 && !isDir2 {
                    return true  // Directory comes before file
                } else if !isDir1 && isDir2 {
                    return false // File comes after directory
                } else {
                    return url1.lastPathComponent.localizedCaseInsensitiveCompare(url2.lastPathComponent) == .orderedAscending
                }
            }) {
                let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

                let item = AppContentItem(
                    name: itemURL.lastPathComponent,
                    url: itemURL,
                    isDirectory: isDirectory,
                    isPlist: itemURL.pathExtension.lowercased() == "plist",
                    depth: depth
                )
                
                if isDirectory && depth < 4 {
                    item.children = scanDirectory(itemURL, depth: depth + 1)
                }
                
                items.append(item)
            }

            return items
        }

        appContents = scanDirectory(appBundleURL)
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
            print("Adding item: \(item.name), isExpanded: \(item.isExpanded), children: \(item.children.count)")
            if item.isDirectory && item.isExpanded {
                let childItems = getFlattenedItems(item.children)
                result.append(contentsOf: childItems)
                print("Added \(childItems.count) children for \(item.name)")
            }
        }
        
        print("Total flattened items: \(result.count)")
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
        
        print("Attempting to save file at: \(url.path)")
        
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            print("Current file attributes: \(attributes)")
        } catch {
            print("Failed to get file attributes: \(error)")
        }
        
        let parentDir = url.deletingLastPathComponent()
        do {
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: parentDir.path)
            print("Made directory writable: \(parentDir.path)")
        } catch {
            print("Failed to make directory writable: \(error)")
        }
        
        let backupURL = url.appendingPathExtension("backup")
        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: url, to: backupURL)
            print("Backup created at: \(backupURL.path)")
        } catch {
            print("Backup creation failed: \(error.localizedDescription)")
        }
        
        let data: Data
        do {
            data = try PropertyListSerialization.data(
                fromPropertyList: plistData,
                format: .xml,
                options: 0
            )
        } catch {
            statusMessage = "Serialization error: \(error.localizedDescription)"
            print("Serialization error: \(error)")
            return
        }
        
        do {
            if !fileManager.isWritableFile(atPath: url.path) {
                try fileManager.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
                print("Made file writable: \(url.path)")
            }
            
            try data.write(to: url)
            statusMessage = "Saved successfully to \(url.lastPathComponent)"
            isModified = false
            print("Successfully saved to: \(url.path)")
            
        } catch {
            print("Direct save failed: \(error)")
            
            do {
                let tempURL = url.appendingPathExtension("tmp")
                try data.write(to: tempURL)
                
                try fileManager.removeItem(at: url)
                try fileManager.moveItem(at: tempURL, to: url)
                
                statusMessage = "Saved successfully to \(url.lastPathComponent) (via temp file)"
                isModified = false
                print("Successfully saved via temp file to: \(url.path)")
                
            } catch {
                statusMessage = "Save error: \(error.localizedDescription)"
                print("Save error (both methods failed): \(error)")
            }
        }
    }
    
    func restoreFromBackup() {
        guard let url = selectedFileURL else { return }
        
        let backupURL = url.appendingPathExtension("backup")
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            statusMessage = "No backup file found for \(url.lastPathComponent)"
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)
                try FileManager.default.removeItem(at: url)
            }
            
            try FileManager.default.copyItem(at: backupURL, to: url)
            
            loadPlistFile(from: url)
            
            statusMessage = "Successfully restored from backup"
            print("Restored from backup: \(backupURL.path) -> \(url.path)")
            
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
            print("Restore error: \(error)")
        }
    }
    
}

// MARK: - Supporting Views

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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? .gray.opacity(0.1) : .clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ContentView()
}
