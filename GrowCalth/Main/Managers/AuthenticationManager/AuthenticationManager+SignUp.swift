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
                if let error {
                    if error.localizedDescription == "The password must be 6 characters long or more." {
                        completion(.failure(CreateAccountError.passwordMustBe6Characters))
                    } else if error.localizedDescription == "The email address is already in use by another account." {
                        completion(.failure(CreateAccountError.emailAlreadyInUse))
                    } else {
                        completion(.failure(CreateAccountError.genericAccountCreationFailed))
                    }
                } else {
                    if let currentUserUID = Auth.auth().currentUser?.uid {
                        Firestore.firestore().collection("users").document(currentUserUID).setData([
                            "email": email,
                            "house": house.rawValue,
                            "points": 0,
                            "steps": 0
                        ]) { err in
                            if err != nil {
                                completion(.failure(CreateAccountError.failedToCreateFirestoreForNewAccount))
                            } else {
                                self.verifyEmail { result in
                                    switch result {
                                    case .success(_):
                                        completion(.success(true))
                                    case .failure(_):
                                        completion(.failure(VerificationError.failedToSendVerificationEmail))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            completion(.failure(EmailError.emailIsNotSSTEmail))
        }
    }
}
