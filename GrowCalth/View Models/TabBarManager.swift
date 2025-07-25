//
//  TabBarManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import SwiftUI

@MainActor
final class TabBarManager: ObservableObject {
    @Published var tabSelected: TabValue = .home

    let tabs: [TabItem] = [
        TabItem(title: "Home", systemImage: "house", selectedImage: "house.fill", value: .home),
        TabItem(title: "Announcements", systemImage: "megaphone", selectedImage: "megaphone.fill", value: .announcements),
        TabItem(title: "Challenges", systemImage: "flag.checkered", selectedImage: "flag.checkered", value: .challenges),
        TabItem(title: "NAPFA", systemImage: "figure.run", selectedImage: "figure.run", value: .napfa),
        TabItem(title: "Settings", systemImage: "gearshape", selectedImage: "gearshape.fill", value: .settings)
    ]
}
