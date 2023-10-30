//
//  AuthenticationManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class AuthenticationManager: ObservableObject {
    static let shared: AuthenticationManager = .init()
    
    @Published var isLoggedIn: Bool = false
    @Published var email: String?
    
    init() {
        verifyAuthenticationState()
        email = Auth.auth().currentUser?.email
    }
    
    private func verifyAuthenticationState() {
        if Auth.auth().currentUser != nil {
            withAnimation {
                self.isLoggedIn = true
            }
        } else {
            withAnimation {
                self.isLoggedIn = false
            }
        }
    }
    
    func signIn(email: String, password: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let err = error {
                completion(.failure(err))
            } else {
                withAnimation {
                    self.isLoggedIn = true
                }
                completion(.success(true))
            }
        }
    }
    
    func signOut(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Error signing out: ", signOutError)
            completion(.failure(signOutError))
        }
        
        verifyAuthenticationState()
    }
    
    func forgotPassword(email: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let err = error {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    
    func createAccount(email: String, password: String, house: Houses, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let err = error {
                completion(.failure(err))
            } else {
                Firestore.firestore().collection("users").document().setData([
                    "email": email,
                    "house": house.rawValue,
                    "password": password,
                    "points": 0,
                    "steps": 0
                ]) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(true))
                    }
                }
                self.verifyAuthenticationState()
            }
        }
    }
    
    func updatePassword(from oldPassword: String, to newPassword: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        let credential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser?.email ?? "", password: oldPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        Firestore.firestore().collection("users").whereField("email", isEqualTo: Auth.auth().currentUser?.email ?? "").getDocuments() { (querySnapshot, err) in
                            if let err = err {
                                completion(.failure(err))
                            } else {
                                for document in querySnapshot!.documents {
                                    print("\(document.documentID) => \(document.data())")
                                    
                                    Firestore.firestore().collection("users").document("\(document.documentID)").updateData([
                                        "password": newPassword
                                    ]) { err in
                                        if let err = err {
                                            completion(.failure(err))
                                        } else {
                                            completion(.success(true))
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
    
    func fetchUsersHouse(_ completion: @escaping ((Result<String, Error>) -> Void)) {
        Firestore.firestore().collection("users").whereField("email", isEqualTo: Auth.auth().currentUser?.email ?? "").getDocuments() { (querySnapshot, err) in
            if let err = err {
                completion(.failure(err))
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    
                    Firestore.firestore().collection("users").document("\(document.documentID)").getDocument { (document, error) in
                        if let document = document, document.exists {
                            if let documentData = document.data() {
                                completion(.success(documentData["house"] as! String))
                            }
                        }
                    }
                }
            }
        }
    }
}
