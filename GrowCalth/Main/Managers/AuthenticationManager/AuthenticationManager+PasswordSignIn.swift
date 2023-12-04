//
//  AuthenticationManager+PasswordSignIn.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth

extension AuthenticationManager {
    func signIn(
        email: String,
                password: String,
                _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let err = error {
                completion(.failure(err))
            } else {
                withAnimation {
                    self.isLoggedIn = true
                }
                self.updatePublishedVariables()
                completion(.success(true))
            }
        }
    }
}
