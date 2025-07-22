//
//  AuthenticationManager+SignUp.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth
@preconcurrency import FirebaseFirestore

extension AuthenticationManager {
    nonisolated internal func sendCreateAccountRequest(email: String, password: String) async throws {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            if error.localizedDescription == "The password must be 6 characters long or more." {
                throw CreateAccountError.passwordMustBe6Characters
            } else if error.localizedDescription == "The email address is already in use by another account." {
                throw CreateAccountError.emailAlreadyInUse
            } else {
                throw CreateAccountError.genericAccountCreationFailed
            }
        }
    }

    nonisolated internal func createFirestoreAccount(email: String, house: Houses, uid: String) async throws {
        do {
            try await Firestore.firestore().collection("users").document(uid).setData([
                "email": email,
                "house": house.rawValue,
                "points": 0,
                "steps": 0
            ])
        } catch {
            throw CreateAccountError.failedToCreateFirestoreForNewAccount
        }
    }

    func createAccount(email: String, password: String, house: Houses) async throws {
        try emailProvidedIsSSTEmail(email: email)
        try await sendCreateAccountRequest(email: email, password: password)
        let user = try getCurrentUser()
        try await createFirestoreAccount(email: email, house: house, uid: user.uid)
        try await verifyEmail(user: user)
    }
}
