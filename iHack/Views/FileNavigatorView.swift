import SwiftUI
import UniformTypeIdentifiers
import AppKit

// File type detection functions

func getFileTypeExtension(for url: URL) -> String {
    do {
        // Try to get the file type using system APIs
        let resourceValues = try url.resourceValues(forKeys: [.typeIdentifierKey, .localizedTypeDescriptionKey])
        
        if let typeIdentifier = resourceValues.typeIdentifier {
            // Convert UTI to file extension
            if let preferredExtension = UTType(typeIdentifier)?.preferredFilenameExtension {
                return preferredExtension
            }
            
            // Handle special cases based on UTI
            switch typeIdentifier {
            case "com.apple.application-bundle":
                return "app"
            case "com.apple.framework":
                return "framework"
            case "com.apple.bundle":
                return "bundle"
            case "com.apple.kernel-extension":
                return "kext"
            case "public.executable":
                return "exec"
            case "public.unix-executable":
                return "unix"
            case "com.apple.applescript.script":
                return "scpt"
            case "public.utf8-plain-text":
                // Check if it's actually a strings file
                if url.pathExtension.lowercased() == "strings" {
                    return "strings"
                }
                return "txt"
            default:
                break
            }
        }
    } catch {
        // Fall back to filename-based detection
        return getFileExtension(from: url.lastPathComponent)
    }
    
    return getFileExtension(from: url.lastPathComponent)
}

func getFileExtension(from fileName: String) -> String {
    // First try to get extension from URL pathExtension
    let url = URL(fileURLWithPath: fileName)
    let pathExtension = url.pathExtension
    
    // If pathExtension is not empty, use it
    if !pathExtension.isEmpty {
        return pathExtension
    }
    
    // If no extension found, try manual parsing
    if let dotIndex = fileName.lastIndex(of: ".") {
        let extensionStartIndex = fileName.index(after: dotIndex)
        let manualExtension = String(fileName[extensionStartIndex...])
        
        // Make sure we didn't get the whole filename
        if manualExtension != fileName && !manualExtension.isEmpty {
            return manualExtension
        }
    }
    
    // Try to detect common file types without extensions
    let lowercaseFileName = fileName.lowercased()
    
    // Check for common executable files
    if fileName == "PkgInfo" { return "pkginfo" }
    if fileName == "CodeResources" { return "xml" }
    if fileName.hasPrefix("._") { return "resource" }
    if lowercaseFileName.contains("executable") { return "exec" }
    
    // Check for strings and script files
    if fileName.hasSuffix(".strings") { return "strings" }
    if fileName.hasSuffix(".scpt") { return "scpt" }
    
    // For .app bundles and other known types
    if fileName.hasSuffix(".app") { return "app" }
    if fileName.hasSuffix(".framework") { return "framework" }
    if fileName.hasSuffix(".bundle") { return "bundle" }
    if fileName.hasSuffix(".kext") { return "kext" }
    
    // Return empty string if no extension can be determined
    return ""
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
            Group {
                if item.isDirectory && !item.children.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            item.isExpanded.toggle()
                            print("Tapped \(item.name), isExpanded now: \(item.isExpanded)")
                        }
                    }) {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 16, height: 16)
                }
            }
            
            // File icon
            let icon = NSWorkspace.shared.icon(forFile: item.url.path)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 16, height: 16)
            
            // File name
            Text(item.name)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // File extension display
            let fileExt = getFileTypeExtension(for: item.url)
            if !fileExt.isEmpty {
                Text(fileExt)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(isSelected ? .blue : (isHovered ? .gray.opacity(0.15) : .clear))
        .cornerRadius(4)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isDirectory {
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.isExpanded.toggle()
                    print("Tapped \(item.name), isExpanded now: \(item.isExpanded)")
                }
            } else {
                onSelect(item)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            
            Button("Copy Path") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(item.url.path, forType: .string)
            }
            
            Button("Copy Name") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(item.name, forType: .string)
            }
            
            Divider()
            
            Button("Open with Default App") {
                NSWorkspace.shared.open(item.url)
            }
        }
    }
}
