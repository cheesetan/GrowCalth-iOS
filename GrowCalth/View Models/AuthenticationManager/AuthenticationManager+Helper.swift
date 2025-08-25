//
//  AuthenticationManager+Helper.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

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

    nonisolated func fetchSchoolName() async throws -> String {
        guard let schoolCode = await self.schoolCode, !schoolCode.isEmpty else {
            throw FirestoreError.failedToGetSpecifiedField
        }

        let document = try await Firestore.firestore()
            .collection("schools")
            .document(schoolCode)
            .getDocument()
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let documentData = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let schoolCode = documentData["schoolName"] as? String else {
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

    nonisolated func getSchoolCode(fromJoinCode code: String) async throws {
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

    nonisolated internal func setUserHouse(houseId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthenticationError.failedToGetUserUid
        }

        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData([
                "house": houseId
            ])
        await checkAuthenticationState()
    }

    nonisolated internal func deleteAccountFromFirestore(uid: String) async throws {
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .delete()
        } catch {
            throw DeleteAccountError.failedToDeleteFromFirestore
        }
    }

    nonisolated internal func sendDeleteAccountRequest(user: User) async throws {
        do {
            try await user.delete()
        } catch {
            throw DeleteAccountError.failedToDeleteAccount
        }
    }

    nonisolated func getCurrentUser() throws -> User {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.noCurrentUser
        }
        return currentUser
    }

    nonisolated internal func reauthenticate(user: User, credential: AuthCredential) async throws {
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw ReauthenticationError.failedToReauthenticate
        }
    }

    func deleteAccount() async throws {
        let user = try getCurrentUser()
        guard let presentingController = getPresenter() else { return }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingController)
        let googleUser = result.user
        guard let idToken = googleUser.idToken?.tokenString else { return }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: googleUser.accessToken.tokenString
        )

        try await reauthenticate(user: user, credential: credential)
        try await deleteAccountFromFirestore(uid: user.uid)
        try await sendDeleteAccountRequest(user: user)
        try await signOut()
    }

    func checkAndCreateAccountInFirestore() async throws {
        guard let uid = Auth.auth().currentUser?.uid, let email = self.email else {
            throw AuthenticationError.failedToGetUserUid
        }

        let document = try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument()

        if !document.exists {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData([
                    "email": email
                ])
        }
    }
}
