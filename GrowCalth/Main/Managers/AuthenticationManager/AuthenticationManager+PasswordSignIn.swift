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
                if let user = Auth.auth().currentUser, user.isEmailVerified || email == "appreview@s2021.ssts.edu.sg" || email == "admin@growcalth.com" || email == "growcalth@sst.edu.sg" {
                    withAnimation {
                        self.isLoggedIn = true
                        self.accountVerified = true
                    }
                    self.updatePublishedVariables()
                    completion(.success(true))
                } else {
                    self.verifyEmail { result in
                        switch result {
                        case .success(_):
                            completion(.success(false))
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                        self.signOut { result in
                            switch result {
                            case .success(_): break
                            case .failure(_): break
                            }
                        }
                    }
                }
            }
        }
    }
}
