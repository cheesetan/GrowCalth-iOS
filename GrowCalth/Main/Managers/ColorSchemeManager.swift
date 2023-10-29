//
//  ColorSchemeManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 29/10/23.
//

import SwiftUI
import SwiftPersistence

enum PreferredColorScheme: Codable {
    case light, dark, automatic
}

class ColorSchemeManager: ObservableObject {
    static let shared: ColorSchemeManager = .init()
    
    @Published var colorScheme: PreferredColorScheme? = .automatic
    
    @Persistent("preferredColorSchemeAppStorage", store: .fileManager) private var preferredColorSchemeAppStorage: PreferredColorScheme = .automatic
    
    init() {
        refreshPublishedVariable()
    }
    
    func updatePreferredColorScheme(to newColorScheme: PreferredColorScheme?) {
        if let newColorScheme = newColorScheme {
            preferredColorSchemeAppStorage = newColorScheme
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.refreshPublishedVariable()
        }
    }
    
    private func refreshPublishedVariable() {
        self.colorScheme = preferredColorSchemeAppStorage
    }
}
