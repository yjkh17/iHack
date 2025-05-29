//
//  PlistEditorView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI

struct XcodePlistTableView: View {
    @Binding var data: [String: Any]
    @Binding var isModified: Bool
    let onSave: () -> Void
    let onRestore: () -> Void
    @State private var searchText = ""
    @State private var showingAddKey = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newValueType: PlistValueType = .string
    @State private var expandedKeys: Set<String> = []
    
    var filteredItems: [PlistItem] {
        let items = createPlistItems(from: data, path: "")
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.key.localizedCaseInsensitiveContains(searchText) ||
            item.displayValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            
            // Add Key Form (when showing)
            if showingAddKey {
                VStack(spacing: 12) {
                    HStack {
                        Text("Add New Key")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            cancelAddKey()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Key name", text: $newKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 200)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Type", selection: $newValueType) {
                                ForEach(PlistValueType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(minWidth: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if newValueType == .boolean {
                                Picker("Boolean Value", selection: $newValue) {
                                    Text("YES").tag("YES")
                                    Text("NO").tag("NO")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                            } else {
                                TextField(newValueType.placeholder, text: $newValue)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("")
                                .font(.caption)
                            Button("Add") {
                                addNewKey()
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .disabled(newKey.isEmpty)
                        }
                    }
                }
                .padding(16)
                .background(.green.opacity(0.05))
                .border(.green.opacity(0.3))
            }
            
            // Main content with hierarchical structure
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(getFlattenedItems(filteredItems), id: \.id) { item in
                        HierarchicalPlistRowView(
                            item: item,
                            isExpanded: expandedKeys.contains(item.path),
                            onToggleExpansion: {
                                if expandedKeys.contains(item.path) {
                                    expandedKeys.remove(item.path)
                                } else {
                                    expandedKeys.insert(item.path)
                                }
                            },
                            onValueChange: { newValue in
                                updateValue(at: item.path, with: newValue)
                                isModified = true
                            },
                            onDelete: {
                                deleteItem(at: item.path)
                                isModified = true
                            }
                        )
                        
                        Rectangle()
                            .fill(.separator.opacity(0.5))
                            .frame(height: 0.5)
                    }
                }
            }
            
            // Bottom toolbar
            HStack {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.bordered)
                .disabled(!isModified)
                
                Button("Restore Backup") {
                    onRestore()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(showingAddKey ? "Cancel Add" : "Add Key") {
                    if showingAddKey {
                        cancelAddKey()
                    } else {
                        showAddKey()
                    }
                }
                .buttonStyle(.bordered)
                .tint(showingAddKey ? .red : .green)
                
                Spacer()
                
                Text("\(data.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.05))
        }
    }
    
    // MARK: - Hierarchical Data Functions
    
    func createPlistItems(from dict: [String: Any], path: String, depth: Int = 0) -> [PlistItem] {
        return dict.keys.sorted().map { key in
            let currentPath = path.isEmpty ? key : "\(path).\(key)"
            let value = dict[key] ?? ""
            
            var children: [PlistItem] = []
            if let childDict = value as? [String: Any] {
                children = createPlistItems(from: childDict, path: currentPath, depth: depth + 1)
            } else if let childArray = value as? [Any] {
                children = createArrayItems(from: childArray, path: currentPath, depth: depth + 1)
            }
            
            return PlistItem(
                key: key,
                value: value,
                path: currentPath,
                depth: depth,
                children: children
            )
        }
    }
    
    func createArrayItems(from array: [Any], path: String, depth: Int) -> [PlistItem] {
        return array.enumerated().map { index, value in
            let currentPath = "\(path)[\(index)]"
            
            var children: [PlistItem] = []
            if let childDict = value as? [String: Any] {
                children = createPlistItems(from: childDict, path: currentPath, depth: depth + 1)
            } else if let childArray = value as? [Any] {
                children = createArrayItems(from: childArray, path: currentPath, depth: depth + 1)
            }
            
            return PlistItem(
                key: "Item \(index)",
                value: value,
                path: currentPath,
                depth: depth,
                children: children
            )
        }
    }
    
    func getFlattenedItems(_ items: [PlistItem]) -> [PlistItem] {
        var result: [PlistItem] = []
        
        for item in items {
            result.append(item)
            if expandedKeys.contains(item.path) && !item.children.isEmpty {
                result.append(contentsOf: getFlattenedItems(item.children))
            }
        }
        
        return result
    }
    
    func updateValue(at path: String, with newValue: Any) {
        // This is a simplified version - in a real implementation,
        // you'd need to navigate the nested structure to update the value
        let components = path.components(separatedBy: ".")
        if components.count == 1 {
            data[components[0]] = newValue
        }
        // TODO: Handle nested updates for complex paths
    }
    
    func deleteItem(at path: String) {
        let components = path.components(separatedBy: ".")
        if components.count == 1 {
            data.removeValue(forKey: components[0])
        }
        // TODO: Handle nested deletions for complex paths
    }
    
    // MARK: - Add Key Functions
    
    func showAddKey() {
        showingAddKey = true
        newKey = ""
        newValue = ""
        newValueType = .string
    }
    
    func cancelAddKey() {
        showingAddKey = false
        newKey = ""
        newValue = ""
        newValueType = .string
    }
    
    func addNewKey() {
        guard !newKey.isEmpty else { return }
        
        let value: Any
        switch newValueType {
        case .string:
            value = newValue
        case .number:
            value = Double(newValue) ?? 0.0
        case .boolean:
            value = newValue == "YES"
        case .array:
            value = [String]() // Empty array
        case .dictionary:
            value = [String: Any]() // Empty dictionary
        }
        
        data[newKey] = value
        isModified = true
        cancelAddKey()
    }
}

// MARK: - Data Models

struct PlistItem: Identifiable {
    let id = UUID()
    let key: String
    let value: Any
    let path: String
    let depth: Int
    let children: [PlistItem]
    
    var valueType: String {
        if value is String { return "String" }
        if value is NSNumber { 
            // Check if it's actually a boolean
            if let number = value as? NSNumber {
                if number === kCFBooleanTrue || number === kCFBooleanFalse {
                    return "Boolean"
                }
            }
            return "Number" 
        }
        if value is Bool { return "Boolean" }
        if value is [Any] { return "Array" }
        if value is [String: Any] { return "Dictionary" }
        return "Unknown"
    }
    
    var displayValue: String {
        if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            // Check if it's actually a boolean
            if number === kCFBooleanTrue || number === kCFBooleanFalse {
                return number.boolValue ? "YES" : "NO"
            }
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
    
    var hasChildren: Bool {
        return !children.isEmpty
    }
}

struct HierarchicalPlistRowView: View {
    let item: PlistItem
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    let onValueChange: (Any) -> Void
    let onDelete: () -> Void
    
    @State private var editingValue = ""
    @State private var isEditing = false
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            // Indentation + Disclosure Triangle
            HStack(spacing: 4) {
                // Indentation
                ForEach(0..<item.depth, id: \.self) { _ in
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 16)
                }
                
                // Disclosure triangle
                if item.hasChildren {
                    Button(action: onToggleExpansion) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 16, height: 16)
                }
                
                Text(item.key)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            .frame(minWidth: 200, alignment: .leading)
            
            Text(item.valueType)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            
            if isEditing && !item.hasChildren {
                TextField("Value", text: $editingValue)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        commitEdit()
                    }
            } else {
                Text(item.displayValue)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        if !item.hasChildren {
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
                    .disabled(item.hasChildren)
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
    
    func startEditing() {
        editingValue = item.displayValue
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

// MARK: - Value Type Enum

enum PlistValueType: String, CaseIterable {
    case string = "String"
    case number = "Number"
    case boolean = "Boolean"
    case array = "Array"
    case dictionary = "Dictionary"
    
    var displayName: String {
        return self.rawValue
    }
    
    var placeholder: String {
        switch self {
        case .string:
            return "Enter text value"
        case .number:
            return "Enter number (e.g., 1.0)"
        case .boolean:
            return "YES or NO"
        case .array:
            return "Creates empty array"
        case .dictionary:
            return "Creates empty dictionary"
        }
    }
}

// Legacy row view for compatibility
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
