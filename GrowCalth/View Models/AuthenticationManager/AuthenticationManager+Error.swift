//
//  AuthenticationManager+Error.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth

enum FirestoreError: LocalizedError, Sendable {
    case documentDoesNotExist
    case documentHasNoData
    case failedToGetSpecifiedField

    var errorDescription: String? {
        switch self {
        case .documentDoesNotExist: "Document does not exist."
        case .documentHasNoData: "Document has no data."
        case .failedToGetSpecifiedField: "Failed to get specified field within document."
        }
    }
}

enum AuthenticationError: LocalizedError, Sendable {
    case failedToGetUserUid
    case noCurrentUser

    var errorDescription: String? {
        switch self {
        case .failedToGetUserUid: "Failed to retrieve user uid. Please sign out and sign back in again."
        case .noCurrentUser: "There is no current user. Please sign out and sign back in again."
        }
    }
}

extension AuthenticationManager {
    internal enum EmailError: LocalizedError, Sendable {
        case emailIsNotSSTEmail
        var errorDescription: String? {
            switch self {
            case .emailIsNotSSTEmail:
                return "Enter a valid SST Email address."
            }
        }
    }

    internal enum DeleteAccountError: LocalizedError, Sendable {
        case failedToDeleteFromFirestore
        case failedToDeleteAccount

        var errorDescription: String? {
            switch self {
            case .failedToDeleteFromFirestore, .failedToDeleteAccount:
                return "An error has occurred while attempting to delete your account. Please try again."
            }
        }
    }

    internal enum VerificationError: LocalizedError, Sendable {
        case failedToSendVerificationEmail

        var errorDescription: String? {
            switch self {
            case .failedToSendVerificationEmail:
                return "We've already sent you a verification email. To prevent multiple requests in a short time, please try again later."
            }
        }
    }

    internal enum CreateAccountError: LocalizedError, Sendable {
        case emailAlreadyInUse
        case passwordMustBe6Characters
        case genericAccountCreationFailed
        case failedToCreateFirestoreForNewAccount

        var errorDescription: String? {
            switch self {
            case .emailAlreadyInUse:
                return "An account with this email already exists. Please log in instead."
            case .passwordMustBe6Characters:
                return "Failed to create account. Your password must be at least 6 characters long."
            case .genericAccountCreationFailed:
                return "An error has occurred while attempting to create your account. Please try again."
            case .failedToCreateFirestoreForNewAccount:
                return "An error has occurred while attempting to create your account. Please try again."
            }
        }
    }

    internal enum SignInError: LocalizedError, Sendable {
        case failedToSignIn

        var errorDescription: String? {
            switch self {
            case .failedToSignIn:
                return "Invalid email address or incorrect password entered."
            }
        }
    }

    internal enum SignOutError: LocalizedError, Sendable {
        case failedToSignOut

        var errorDescription: String? {
            switch self {
            case .failedToSignOut:
                return "An error has occurred while attempting to sign out of your account. Please try again."
            }
        }
    }

    internal enum PasswordChangeError: LocalizedError, Sendable {
        case failedToSendPasswordChangeRequestLinkToEmail
        case failedToChangePassword

        var errorDescription: String? {
            switch self {
            case .failedToSendPasswordChangeRequestLinkToEmail:
                return "An error has occurred while attempting to send password change request to the requested email address."
            case .failedToChangePassword:
                return "An error has occurred while attempting to change your password. Your new password has to be at least 6 characters long."
            }
        }
    }

    internal enum ReauthenticationError: LocalizedError, Sendable {
        case failedToReauthenticate

        var errorDescription: String? {
            switch self {
            case .failedToReauthenticate: "Failed to reauthenticate account. The password entered may be incorrect."
            }
        }
    }
}
