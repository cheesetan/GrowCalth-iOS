//
//  AuthenticationManager+Error.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import Foundation

extension AuthenticationManager {
    enum AccountCreationError: LocalizedError {
        case emailIsNotSSTEmail
        var errorDescription: String? { return "Please use a valid SST Email address." }
    }

    enum MagicLinkHandlerError: LocalizedError {
        case noPersistedEmailInSignInFlow
        var errorDescription: String? { return "Invalid email address. The Magic Link you have used has most likely expired. Try signing in with a new Magic Link" }
    }

    enum DeleteAccountError: Error {
        case wrongPasswordToReauth
        case failedToDeleteFromFirestore
        case failedToDeleteAccount
        case failedToSignOut
        
        var localizedDescription: String {
            switch self {
            case .wrongPasswordToReauth:
                return NSLocalizedString("The password you have entered to delete your account is incorrect.", comment: "Wrong password")
            case .failedToDeleteFromFirestore:
                return NSLocalizedString("An error has occurred while attempting to delete your account.", comment: "Firestore error")
            case .failedToDeleteAccount:
                return NSLocalizedString("An error has occurred while attempting to delete your account.", comment: "Account error")
            case .failedToSignOut:
                return NSLocalizedString("An error has occurred while attempting to sign out of deleted account. Please sign out manually.", comment: "Sign out error")
            }
        }
    }
}
