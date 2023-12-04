//
//  AuthenticationManager+MagicLinkSignIn.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth

extension AuthenticationManager {
    func sendMagicLink(
        email: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) async {
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
    
    func handleMagicLink(
        url: URL,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) async {
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
}
