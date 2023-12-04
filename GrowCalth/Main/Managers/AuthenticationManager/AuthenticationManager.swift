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
    
    @AppStorage("emailToSignInWithMagicLink") internal var emailToSignInWithMagicLink: String?
    
    init() {
        verifyAuthenticationState()
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
    
    internal func updatePublishedVariables() {
        email = Auth.auth().currentUser?.email
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
    }
    
    func fetchUsersHouse(_ completion: @escaping ((Result<String, Error>) -> Void)) {
        Firestore.firestore().collection("users").document(Auth.auth().currentUser?.uid ?? "").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    completion(.success(documentData["house"] as! String))
                }
            }
        }
    }
}
