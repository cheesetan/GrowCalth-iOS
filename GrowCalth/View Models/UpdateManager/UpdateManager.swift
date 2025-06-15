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
        do {
            try isUpdateAvailable()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func isUpdateAvailable() throws {
        guard let info = Bundle.main.infoDictionary,
            let currentVersion = info["CFBundleShortVersionString"] as? String,
            let identifier = info["CFBundleIdentifier"] as? String,
            let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                throw UpdateError.invalidBundleInfo
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error }
                guard let data = data else { throw UpdateError.invalidResponse }
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String else {
                    throw UpdateError.invalidResponse
                }
                Task {   
                    let versionSeparated = version.components(separatedBy: ".")
                    let currentVersionSeparated = currentVersion.components(separatedBy: ".")
                   
                    var versionNumberCode = 0
                    var versionMultiplier = 10000000000
                    versionSeparated.forEach { number in
                        versionNumberCode = versionNumberCode + ((Int(number) ?? 0) * versionMultiplier)
                        versionMultiplier = versionMultiplier / 100000
                    }
                    
                    print("versionNumberCode: \(versionNumberCode)")
                    
                    var currentVersionNumberCode = 0
                    var currentVersionMultiplier = 10000000000
                    currentVersionSeparated.forEach { number in
                        currentVersionNumberCode = currentVersionNumberCode + ((Int(number) ?? 0) * currentVersionMultiplier)
                        currentVersionMultiplier = currentVersionMultiplier / 100000
                    }
                    
                    print("currentVersionNumberCode: \(currentVersionNumberCode)")
                    
                    withAnimation {
                        if currentVersionNumberCode < versionNumberCode {
                            self.updateAvailable = true
                        } else {
                            self.updateAvailable = false
                        }
                    }
                }
            } catch {
                withAnimation {
                    self.updateAvailable = nil
                }
            }
        }
        task.resume()
    }
}


