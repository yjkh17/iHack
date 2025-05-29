//
//  XCPrivacyEditorView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import Foundation

struct XCPrivacyEditorView: View {
    @Binding var data: [String: Any]
    @Binding var isModified: Bool
    let onSave: () -> Void
    let onRestore: () -> Void
    
    @State private var searchText = ""
    @State private var showingAddKey = false
    @State private var newKey = ""
    @State private var newValueType: XCPrivacyValueType = .string
    @State private var newStringValue = ""
    @State private var newBoolValue = false
    @State private var newArrayItems: [String] = [""]
    
    enum XCPrivacyValueType: String, CaseIterable {
        case string = "String"
        case boolean = "Boolean"
        case array = "Array"
        
        var displayName: String { rawValue }
    }
    
    var filteredKeys: [String] {
        let keys = Array(data.keys).sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { key in
            key.localizedCaseInsensitiveContains(searchText) ||
            String(describing: data[key] ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Privacy Manifest Editor")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Restore") {
                        onRestore()
                    }
                    .buttonStyle(.bordered)
                    .disabled(data.isEmpty)
                    
                    Button("Save") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isModified)
                }
            }
            .padding()
            .background(.regularMaterial)
            
            // Search and Add Controls
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search keys and values...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.gray.opacity(0.2))
                .cornerRadius(8)
                
                Button(showingAddKey ? "Cancel Add" : "Add Key") {
                    showingAddKey.toggle()
                    if !showingAddKey {
                        resetAddKeyForm()
                    }
                }
                .buttonStyle(.bordered)
                .tint(showingAddKey ? .red : .green)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.05))
            
            // Add Key Form
            if showingAddKey {
                AddXCPrivacyKeyView(
                    newKey: $newKey,
                    newValueType: $newValueType,
                    newStringValue: $newStringValue,
                    newBoolValue: $newBoolValue,
                    newArrayItems: $newArrayItems,
                    onAdd: addNewKey,
                    onCancel: {
                        showingAddKey = false
                        resetAddKeyForm()
                    }
                )
            }
            
            // Key-Value List
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredKeys, id: \.self) { key in
                        XCPrivacyRowView(
                            key: key,
                            value: Binding(
                                get: { data[key] ?? "" },
                                set: { data[key] = $0; isModified = true }
                            ),
                            onDelete: {
                                data.removeValue(forKey: key)
                                isModified = true
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Footer
            HStack {
                Text("\(data.count) privacy manifest entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text("\(filteredKeys.count) shown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func addNewKey() {
        guard !newKey.isEmpty else { return }
        
        let value: Any
        switch newValueType {
        case .string:
            value = newStringValue
        case .boolean:
            value = newBoolValue
        case .array:
            value = newArrayItems.filter { !$0.isEmpty }
        }
        
        data[newKey] = value
        isModified = true
        showingAddKey = false
        resetAddKeyForm()
    }
    
    private func resetAddKeyForm() {
        newKey = ""
        newValueType = .string
        newStringValue = ""
        newBoolValue = false
        newArrayItems = [""]
    }
}

struct AddXCPrivacyKeyView: View {
    @Binding var newKey: String
    @Binding var newValueType: XCPrivacyEditorView.XCPrivacyValueType
    @Binding var newStringValue: String
    @Binding var newBoolValue: Bool
    @Binding var newArrayItems: [String]
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("NSPrivacyAccessedAPIType", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Type", selection: $newValueType) {
                        ForEach(XCPrivacyEditorView.XCPrivacyValueType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Group {
                        switch newValueType {
                        case .string:
                            TextField("Value", text: $newStringValue)
                                .textFieldStyle(.roundedBorder)
                        case .boolean:
                            Toggle("", isOn: $newBoolValue)
                                .toggleStyle(.switch)
                        case .array:
                            HStack {
                                Text("[\(newArrayItems.filter { !$0.isEmpty }.count) items]")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Button("Edit Array") {
                                    // TODO: Array editor
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .frame(minWidth: 150)
                }
            }
            
            HStack {
                Button("Add Key") {
                    onAdd()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(newKey.isEmpty)
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.green.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct XCPrivacyRowView: View {
    let key: String
    @Binding var value: Any
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingValue = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Key
            VStack(alignment: .leading, spacing: 2) {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(getPrivacyKeyDescription(key))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 200, alignment: .leading)
            
            // Type
            Text(getValueType(value))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getTypeColor(value).opacity(0.2))
                .foregroundColor(getTypeColor(value))
                .cornerRadius(4)
                .frame(width: 80)
            
            // Value
            Group {
                if isEditing {
                    TextField("Value", text: $editingValue)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            saveEdit()
                        }
                } else {
                    Text(getDisplayValue(value))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            startEditing()
                        }
                }
            }
            
            // Actions
            if isHovered {
                HStack(spacing: 4) {
                    if isEditing {
                        Button("Save") {
                            saveEdit()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.green)
                        
                        Button("Cancel") {
                            cancelEdit()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button(action: startEditing) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
            if !hovering && isEditing {
                cancelEdit()
            }
        }
    }
    
    private func getValueType(_ value: Any) -> String {
        switch value {
        case is String: return "String"
        case is Bool: return "Boolean"
        case is Array<Any>: return "Array"
        case is Dictionary<String, Any>: return "Dictionary"
        default: return "Unknown"
        }
    }
    
    private func getTypeColor(_ value: Any) -> Color {
        switch value {
        case is String: return .green
        case is Bool: return .orange
        case is Array<Any>: return .blue
        case is Dictionary<String, Any>: return .purple
        default: return .gray
        }
    }
    
    private func getDisplayValue(_ value: Any) -> String {
        switch value {
        case let str as String:
            return str.isEmpty ? "[Empty String]" : str
        case let bool as Bool:
            return bool ? "true" : "false"
        case let array as Array<Any>:
            return "[\(array.count) items]"
        case let dict as Dictionary<String, Any>:
            return "{\(dict.count) keys}"
        default:
            return String(describing: value)
        }
    }
    
    private func getPrivacyKeyDescription(_ key: String) -> String {
        switch key {
        case "NSPrivacyAccessedAPIType":
            return "API type being accessed"
        case "NSPrivacyAccessedAPITypeReasons":
            return "Reasons for API access"
        case "NSPrivacyCollectedDataTypes":
            return "Types of data collected"
        case "NSPrivacyTrackingDomains":
            return "Domains used for tracking"
        case "NSPrivacyTracking":
            return "Whether app tracks users"
        default:
            return "Privacy manifest key"
        }
    }
    
    private func startEditing() {
        editingValue = getDisplayValue(value)
        isEditing = true
    }
    
    private func saveEdit() {
        // Convert edited value back to appropriate type
        if value is Bool {
            value = editingValue.lowercased() == "true"
        } else if value is String {
            value = editingValue
        }
        isEditing = false
    }
    
    private func cancelEdit() {
        isEditing = false
        editingValue = ""
    }
}