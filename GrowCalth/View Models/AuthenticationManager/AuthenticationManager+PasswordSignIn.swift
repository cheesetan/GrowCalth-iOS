//
//  AuthenticationManager+PasswordSignIn.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth

extension AuthenticationManager {
    nonisolated internal func sendSignInRequest(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw SignInError.failedToSignIn
        }
    }

    func signIn(email: String, password: String) async throws -> Bool {
        try await sendSignInRequest(email: email, password: password)
        let user = try getCurrentUser()

        if user.isEmailVerified ||
            email == "appreview@s2021.ssts.edu.sg" ||
            email == "admin@growcalth.com" ||
            email == "growcalth@sst.edu.sg" {
            withAnimation {
                self.isLoggedIn = true
                self.accountVerified = true
            }
            await self.updatePublishedVariables()
            return true
        } else {
            try await self.signOut()
            return false
        }
    }
}
