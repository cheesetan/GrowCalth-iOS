//
//  ColorSchemeManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 29/10/23.
//

import SwiftUI

enum PreferredColorScheme: Codable {
    case light, dark, automatic
}

class ColorSchemeManager: ObservableObject {
    static let shared: ColorSchemeManager = .init()

    @Published var colorScheme: PreferredColorScheme = .automatic {
        didSet {
            save()
        }
    }

    init() {
        load()
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "preferredCSs.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("preferredCSs.json")
        }
    }

    private func save() {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let encodedPreferredColorSchemes = try? jsonEncoder.encode(colorScheme)
        try? encodedPreferredColorSchemes?.write(to: archiveURL, options: .noFileProtection)
    }

    private func load() {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        if let retrievedPreferredColorSchemeData = try? Data(contentsOf: archiveURL),
           let preferredCSsDecoded = try? jsonDecoder.decode(PreferredColorScheme.self, from: retrievedPreferredColorSchemeData) {
            colorScheme = preferredCSsDecoded
        }
    }
}
