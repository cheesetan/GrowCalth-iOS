//
//  ColorSchemeManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 29/10/23.
//

import SwiftUI

@MainActor
final class SettingsManager: ObservableObject, Sendable {
    @AppStorage("specularHighlightsEnabled", store: .standard) var specularHighlightsEnabled: Bool = true
    @Published var colorScheme: PreferredColorScheme = .automatic {
        didSet {
            Task {
                await save()
            }
        }
    }

    init() {
        Task {
            await load()
        }
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "preferredCSs.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("preferredCSs.json")
        }
    }

    private func save() async {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        do {
            let encodedData = try jsonEncoder.encode(colorScheme)
            try encodedData.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("Failed to save color scheme preference: \(error)")
        }
    }

    private func load() async {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        do {
            let data = try Data(contentsOf: archiveURL)
            let decodedColorScheme = try jsonDecoder.decode(PreferredColorScheme.self, from: data)
            colorScheme = decodedColorScheme
        } catch {
            print("Failed to load color scheme preference: \(error)")
            // Keep default value (.automatic) if loading fails
        }
    }
}
