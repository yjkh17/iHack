//
//  LaunchpadView.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI

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