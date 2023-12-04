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
    
    @AppStorage("emailToSignInWithMagicLink") private var emailToSignInWithMagicLink: String?
    
    init() {
        verifyAuthenticationState()
        updatePublishedVariables()
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
    
    private func updatePublishedVariables() {
        email = Auth.auth().currentUser?.email
    }
    
    func signIn(email: String, password: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
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
    
    func sendMagicLink(email: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) async {
        if emailProvidedIsSSTEmail(email: email) {
            let actionCodeSettings = ActionCodeSettings()
            actionCodeSettings.handleCodeInApp = true
            actionCodeSettings.url = URL(string: "https://growcalth.page.link/magic-link-login")
            do {
                try await Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
                DispatchQueue.main.sync {
                    emailToSignInWithMagicLink = email
                }
                completion(.success(true))
            } catch {
                completion(.failure(error))
            }
        } else {
            completion(.failure(AccountCreationError.emailIsNotSSTEmail))
        }
    }
    
    func handleMagicLink(url: URL, _ completion: @escaping ((Result<Bool, Error>) -> Void)) async {
        guard let email = emailToSignInWithMagicLink else {
            completion(.failure(MagicLinkHandlerError.noPersistedEmailInSignInFlow))
            return
        }
        
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
            do {
                try await Auth.auth().signIn(withEmail: email, link: link)
                DispatchQueue.main.sync {
                    emailToSignInWithMagicLink = nil
                    withAnimation {
                        self.isLoggedIn = true
                    }
                    updatePublishedVariables()
                }
            } catch {
                completion(.failure(error))
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
        
        updatePublishedVariables()
        verifyAuthenticationState()
    }
    
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
//                            "password": password,
                            "points": 0,
                            "steps": 0
                        ]) { err in
                            if let err = err {
                                completion(.failure(err))
                            } else {
                                completion(.success(true))
                            }
                        }
                    }
                    self.updatePublishedVariables()
                    self.verifyAuthenticationState()
                }
            }
        } else {
            completion(.failure(AccountCreationError.emailIsNotSSTEmail))
        }
    }
    
    private func emailProvidedIsSSTEmail(email: String) -> Bool {
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
//                        Firestore.firestore().collection("users").whereField("email", isEqualTo: Auth.auth().currentUser?.email ?? "").getDocuments() { (querySnapshot, err) in
//                            if let err = err {
//                                completion(.failure(err))
//                            } else {
//                                for document in querySnapshot!.documents {
//                                    print("\(document.documentID) => \(document.data())")
//                                    
//                                    Firestore.firestore().collection("users").document("\(document.documentID)").updateData([
//                                        "password": newPassword
//                                    ]) { err in
//                                        if let err = err {
//                                            completion(.failure(err))
//                                        } else {
                                            completion(.success(true))
//                                        }
//                                    }
//                                }
//                            }
//                        }
                    }
                }
            }
        }
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
