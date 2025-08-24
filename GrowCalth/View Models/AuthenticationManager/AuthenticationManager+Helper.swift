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
        self.checkAuthenticationState()
    }

    nonisolated func fetchSchoolCode() async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.failedToGetUserUid
        }

        let document = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let documentData = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let schoolCode = documentData["schoolCode"] as? String else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        return schoolCode
    }

    nonisolated func fetchUsersHouse() async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.failedToGetUserUid
        }
        
        let document = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()
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
    }

    nonisolated func getSchoolCode(fromReferralCode code: String) async throws {
        let documents = try await Firestore.firestore()
            .collection("schools")
            .whereField("joinCode", isEqualTo: code)
            .getDocuments()

        let document = documents.documents.first
        guard let document, document.exists else {
            throw FirestoreError.documentDoesNotExist
        }

        let documentData = document.data()
        guard let schoolCode = documentData["schoolCode"] as? String else {
            throw FirestoreError.failedToGetSpecifiedField
        }

        try await setUserSchoolCode(code: schoolCode)
    }

    nonisolated internal func setUserSchoolCode(code: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.failedToGetUserUid
        }

        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData([
                "schoolCode": code
            ])
        await checkAuthenticationState()
    }
}
