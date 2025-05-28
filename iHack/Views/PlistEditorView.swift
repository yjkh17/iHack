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
    
    var filteredKeys: [String] {
        let keys = Array(data.keys).sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
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
            
            // Main content
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
                
                Text("\(filteredKeys.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.05))
        }
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
