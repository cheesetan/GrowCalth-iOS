//
//  UpdateManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 7/2/24.
//


import SwiftUI

enum UpdateError: Error {
    case invalidResponse, invalidBundleInfo
}


class UpdateManager: ObservableObject {
    static let shared: UpdateManager = .init()
    
    @Published var updateAvailable: Bool?
    
    init() {
        do {
            try isUpdateAvailable()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func isUpdateAvailable() throws -> URLSessionDataTask {
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
                DispatchQueue.main.async {   
                    withAnimation {
                        self.updateAvailable = version != currentVersion
                    }
                }
            } catch {
                withAnimation {
                    self.updateAvailable = nil
                }
            }
        }
        task.resume()
        return task
    }
}
