//
//  UpdateManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 7/2/24.
//

import SwiftUI

class UpdateManager: ObservableObject {

    @Published var updateAvailable: Bool?

    init() {
        Task {
            do {
                try await isUpdateAvailable()
            } catch {
                print("Update check failed: \(error.localizedDescription)")
                self.updateAvailable = nil
            }
        }
    }

    func isUpdateAvailable() async throws {
        guard let info = Bundle.main.infoDictionary,
              let currentVersion = info["CFBundleShortVersionString"] as? String,
              let identifier = info["CFBundleIdentifier"] as? String,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
            throw UpdateError.invalidBundleInfo
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]

            guard let results = json?["results"] as? [Any],
                  let firstResult = results.first as? [String: Any],
                  let appStoreVersion = firstResult["version"] as? String else {
                throw UpdateError.missingAppStoreData
            }

            let isUpdateNeeded = try compareVersions(current: currentVersion, appStore: appStoreVersion)

            withAnimation {
                self.updateAvailable = isUpdateNeeded
            }

        } catch let error as UpdateError {
            withAnimation {
                self.updateAvailable = nil
            }
            throw error
        } catch {
            withAnimation {
                self.updateAvailable = nil
            }

            if error is DecodingError {
                throw UpdateError.jsonParsingError(error)
            } else {
                throw UpdateError.networkError(error)
            }
        }
    }

    private func compareVersions(current: String, appStore: String) throws -> Bool {
        let appStoreComponents = appStore.components(separatedBy: ".")
        let currentComponents = current.components(separatedBy: ".")

        // Validate version format
        guard !appStoreComponents.isEmpty && !currentComponents.isEmpty,
              appStoreComponents.allSatisfy({ Int($0) != nil }),
              currentComponents.allSatisfy({ Int($0) != nil }) else {
            throw UpdateError.invalidVersionFormat
        }

        let appStoreVersionCode = calculateVersionCode(from: appStoreComponents)
        let currentVersionCode = calculateVersionCode(from: currentComponents)

        print("App Store version code: \(appStoreVersionCode)")
        print("Current version code: \(currentVersionCode)")

        return currentVersionCode < appStoreVersionCode
    }

    private func calculateVersionCode(from components: [String]) -> Int {
        var versionCode = 0
        var multiplier = 10_000_000_000

        for component in components {
            let number = Int(component) ?? 0
            versionCode += number * multiplier
            multiplier /= 100_000
        }

        return versionCode
    }
}
