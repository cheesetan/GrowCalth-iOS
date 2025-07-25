//
//  APNSError.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import Foundation

enum APNSError: LocalizedError, Sendable {
    case failedToFetchPrivateKeyFromFirestore
    case failedToDecodePrivateKey
    case jwtSigningError
    case httpError(Int, String?)
    case failedToParseTokenResponse
    case failedToFetchFCMTokensFromFirestore
    case errorFindingSpecifiedFCMToken
    case errorDeletingSpecifiedFCMToken
    case errorUpdatingFCMToken
    case invalidResponse
    case fcmError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .failedToFetchPrivateKeyFromFirestore:
            return "Failed to fetch private key from Firestore. Please try again later."
        case .failedToDecodePrivateKey:
            return "Failed to decode private key. Please try again later."
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message ?? "Unknown error"). Please try again later."
        case .jwtSigningError:
            return "Failed to sign JWT. Please try again later."
        case .failedToParseTokenResponse:
            return "Failed to parse token response. Please try again later."
        case .failedToFetchFCMTokensFromFirestore:
            return "Failed to fetch FCM Tokens from Firestore. Please try again later."
        case .errorFindingSpecifiedFCMToken:
            return "Failed to fetch specified FCM Token. Please try again later."
        case .errorDeletingSpecifiedFCMToken:
            return "Failed to delete specified FCM Token. Please try again later."
        case .errorUpdatingFCMToken:
            return "Failed to update your FCM Token. Please try again later."
        case .invalidResponse:
            return "Invalid response received. Please try again later."
        case .fcmError(let code, let message):
            return "FCM Error (\(code)): \(message)"
        }
    }
}
