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
    
    // TODO: - doesnt add house if its a new account

    @Published var isLoggedIn: Bool = false
    @Published var accountVerified: Bool = false
    @Published var email: String?
    @Published var usersHouse: String?
        
    init() {
        verifyAuthenticationState()
        verifyVerificationState()
        updatePublishedVariables()
    }
    
    internal func verifyAuthenticationState() {
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
    
    internal func verifyVerificationState() {
        if let user = Auth.auth().currentUser {
            if user.email == "appreview@s2021.ssts.edu.sg" || user.email == "admin@growcalth.com" || user.email == "growcalth@sst.edu.sg" {
                self.accountVerified = true
            } else {
                self.accountVerified = user.isEmailVerified
            }
        } else {
            self.accountVerified = false
        }
    }
    
    internal func updatePublishedVariables() {
        email = Auth.auth().currentUser?.email
        self.fetchUsersHouse { result in
            switch result {
            case .success(let success):
                self.usersHouse = success
            case .failure(_):
                break
            }
        }
    }
    
    internal func emailProvidedIsSSTEmail(email: String) -> Bool {
        var returnResult = false
        
        let regexPatternSSTudent = "(.+)@s20\\d\\d.ssts.edu.sg"
        let predicateSSTudent = NSPredicate(format: "SELF MATCHES %@", regexPatternSSTudent)
        returnResult = predicateSSTudent.evaluate(with: email)
        
        if returnResult {
            return returnResult
        }
        
        let regexPatternSSTaff = "(.+)@sst.edu.sg"
        let predicateSSTaff = NSPredicate(format: "SELF MATCHES %@", regexPatternSSTaff)
        returnResult = predicateSSTaff.evaluate(with: email)
        return returnResult
    }
    
    func signOut(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        do {
            try Auth.auth().signOut()
        } catch let signOutError {
            print("Error signing out: ", signOutError)
            completion(.failure(signOutError))
        }
        
        updatePublishedVariables()
        verifyAuthenticationState()
        verifyVerificationState()
    }
    
    func fetchUsersHouse(_ completion: @escaping ((Result<String, Error>) -> Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    completion(.success(documentData["house"] as! String))
                }
            }
        }
    }
}
