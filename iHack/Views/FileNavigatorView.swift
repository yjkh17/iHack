//
//  FileNavigatorView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI

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
            } else if item.isPlist {
                onSelect(item)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}