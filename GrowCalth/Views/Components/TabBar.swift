//
//  TabBar.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import SwiftUI

struct TabBar: View {

    @EnvironmentObject private var tabBarManager: TabBarManager
    @EnvironmentObject private var motionManager: MotionManager
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(tabBarManager.tabs.enumerated()), id: \.offset) { index, tab in
                tabButton(
                    tab,
                    iconSize: 18,
                    fontSize: 9
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background {
            Capsule()
                .fill(
                    .ultraThinMaterial
                        .opacity(0.98)
                        .shadow(
                            .drop(
                                color: .black.opacity(0.15),
                                radius: 20,
                                x: 0,
                                y: 8
                            )
                        )
                )
                .specularHighlight(motionManager: motionManager)
        }
        .mask(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        .padding([.horizontal, .bottom])
    }

    @ViewBuilder
    func tabButton(
        _ item: TabItem,
        iconSize: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let isSelected = tabBarManager.tabSelected == item.value

        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                tabBarManager.tabSelected = item.value
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? item.selectedImage : item.systemImage)
                    .font(.system(size: iconSize, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .accent : .primary.opacity(0.7))
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.4) : .clear,
                        radius: 12,
                        x: 0,
                        y: 2
                    )
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.2) : .clear,
                        radius: 4,
                        x: 0,
                        y: 1
                    )

                Text(item.title)
                    .font(.system(size: fontSize, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .accent : .primary.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
