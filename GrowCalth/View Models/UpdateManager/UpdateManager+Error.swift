//
//  UpdateError.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

extension UpdateManager {
    internal enum UpdateError: LocalizedError {
        case invalidResponse
        case invalidBundleInfo
        case networkError(Error)
        case jsonParsingError(Error)
        case invalidVersionFormat
        case missingAppStoreData

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Received an invalid response. Please try again later."
            case .invalidBundleInfo:
                return "Could not validate your bundle information. Please try again later."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .jsonParsingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            case .invalidVersionFormat:
                return "Invalid version format received from App Store."
            case .missingAppStoreData:
                return "App Store data not found for this application."
            }
        }
    }
}
