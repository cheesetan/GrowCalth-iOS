//
//  AuthenticationManager+AccountChanges.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension AuthenticationManager {
    internal func sendForgotPasswordRequest(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw PasswordChangeError.failedToSendPasswordChangeRequestLinkToEmail
        }
    }

    func forgotPassword(email: String) async throws {
        try emailProvidedIsSSTEmail(email: email)
        try await sendForgotPasswordRequest(email: email)
    }
}

extension AuthenticationManager {
    internal func sendUpdatePasswordRequest(user: User, to newPassword: String) async throws {
        do {
            try await user.updatePassword(to: newPassword)
        } catch {
            throw PasswordChangeError.failedToChangePassword
        }
    }

    func updatePassword(from oldPassword: String, to newPassword: String) async throws {
        let user = try getCurrentUser()
        let credential = EmailAuthProvider.credential(
            withEmail: user.email ?? "",
            password: oldPassword
        )
        try await reauthenticate(user: user, credential: credential)
        try await sendUpdatePasswordRequest(user: user, to: newPassword)
    }
}

extension AuthenticationManager {
    internal func deleteAccountFromFirestore(uid: String) async throws {
        do {
            try await Firestore.firestore().collection("users").document(uid).delete()
        } catch {
            throw DeleteAccountError.failedToDeleteFromFirestore
        }
    }

    internal func sendDeleteAccountRequest(user: User) async throws {
        do {
            try await user.delete()
        } catch {
            throw DeleteAccountError.failedToDeleteAccount
        }
    }
    
    func deleteAccount(password: String) async throws {
        let user = try getCurrentUser()
        let credential = EmailAuthProvider.credential(
            withEmail: user.email ?? "",
            password: password
        )
        try await reauthenticate(user: user, credential: credential)
        try await deleteAccountFromFirestore(uid: user.uid)
        try await sendDeleteAccountRequest(user: user)
        try await signOut()
    }
}
