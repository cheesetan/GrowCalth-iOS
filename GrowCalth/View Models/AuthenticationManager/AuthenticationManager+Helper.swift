//
//  AuthenticationManager+Helper.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension AuthenticationManager {
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw SignOutError.failedToSignOut
        }

        await updatePublishedVariables()
        verifyAuthenticationState()
        verifyVerificationState()
    }

    func verifyEmail(user: User) async throws {
        do {
            try await user.sendEmailVerification()
        } catch {
            throw VerificationError.failedToSendVerificationEmail
        }
    }

    func getCurrentUser() throws -> User {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.noCurrentUser
        }
        return currentUser
    }

    func fetchUsersHouse() async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.failedToGetUserUid
        }

        do {
            let document = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard document.exists else {
                throw FirestoreError.documentDoesNotExist
            }
            guard let documentData = document.data() else {
                throw FirestoreError.documentHasNoData
            }
            guard let house = documentData["house"] as? String else {
                throw FirestoreError.failedToGetSpecifiedField
            }
            return house
        } catch {
            throw error
        }
    }

    internal func reauthenticate(user: User, credential: AuthCredential) async throws {
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw ReauthenticationError.failedToReauthenticate
        }
    }
}
