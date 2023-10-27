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
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            guard error == nil else { return }
            withAnimation {
                self.isLoggedIn = true
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        verifyAuthenticationState()
    }
    
    func forgotPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            guard error == nil else { return }
        }
    }
    
    
    func createAccount(email: String, password: String, house: Houses) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            guard error == nil else { return }
            
            Firestore.firestore().collection("users").document().setData([
                "email": email,
                "house": house.rawValue,
                "password": password,
                "points": 0,
                "steps": 0
            ]) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                }
            }
            
            self.verifyAuthenticationState()
        }
    }
    
    func updatePassword(to newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            guard error == nil else { return }
            
            Firestore.firestore().collection("users").whereField("email", isEqualTo: Auth.auth().currentUser?.email ?? "NOEMAIL").getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                    } else {
                        for document in querySnapshot!.documents {
                            print("\(document.documentID) => \(document.data())")
                            
                            Firestore.firestore().collection("users").document("\(document.documentID)").updateData([
                                "password": newPassword
                            ]) { err in
                                if let err = err {
                                    print("Error updating document: \(err)")
                                } else {
                                    print("Document successfully updated")
                                }
                            }
                        }
                    }
            }
        }
    }
}
