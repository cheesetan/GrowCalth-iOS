//
//  UpdateError.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

extension UpdateManager {
    internal enum UpdateError: LocalizedError {
        case invalidResponse, invalidBundleInfo
        var errorDescription: String? {
            switch self {
            case .invalidResponse: "Received an invalid response. Please try again later."
            case .invalidBundleInfo: "Could not validate your bundle information. Please try again later."
            }
        }
    }
}
