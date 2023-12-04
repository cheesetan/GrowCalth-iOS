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
    func forgotPassword(
        email: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let err = error {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func updatePassword(
        from oldPassword: String,
        to newPassword: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser?.email ?? "", password: oldPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(true))
                    }
                }
            }
        }
    }
    
    func deleteAccount(password: String, _ completion: @escaping ((Result<Bool, DeleteAccountError>) -> Void)) {
        let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser?.email ?? "", password: password)
        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
            if error != nil {
                completion(.failure(DeleteAccountError.wrongPasswordToReauth))
            } else {
                if let uid = Auth.auth().currentUser?.uid {
                    Firestore.firestore().collection("users").document(uid).delete() { err in
                        if err != nil {
                            completion(.failure(DeleteAccountError.failedToDeleteFromFirestore))
                        } else {
                            let user = Auth.auth().currentUser
                            user?.delete { error in
                                if error != nil {
                                    completion(.failure(DeleteAccountError.failedToDeleteAccount))
                                } else {
                                    self.signOut { result in
                                        switch result {
                                        case .success(_):
                                            break
                                        case .failure(_):
                                            completion(.failure(DeleteAccountError.failedToSignOut))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
