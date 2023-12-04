//
//  AuthenticationManager+SignUp.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension AuthenticationManager {
    func createAccount(
        email: String,
        password: String,
        house: Houses,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        if emailProvidedIsSSTEmail(email: email) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let err = error {
                    completion(.failure(err))
                } else {
                    if let currentUserUID = Auth.auth().currentUser?.uid {
                        Firestore.firestore().collection("users").document(currentUserUID).setData([
                            "email": email,
                            "house": house.rawValue,
                            "points": 0,
                            "steps": 0
                        ]) { err in
                            if let err = err {
                                completion(.failure(err))
                            } else {
                                self.verifyEmail { result in
                                    switch result {
                                    case .success(_):
                                        completion(.success(true))
                                    case .failure(let failure):
                                        completion(.failure(failure))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            completion(.failure(AccountCreationError.emailIsNotSSTEmail))
        }
    }
}
