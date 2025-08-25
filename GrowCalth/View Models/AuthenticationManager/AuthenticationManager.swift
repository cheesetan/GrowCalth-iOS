//
//  AuthenticationManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@MainActor
final class AuthenticationManager: ObservableObject {

    @Published var isLoggedIn: Bool = false

    @Published var name: String?
    @Published var email: String?
    @Published var house: String?
    @Published var schoolCode: String?
    @Published var schoolName: String?

//    @Published var accountType: AccountType = .unknown

    init() {
        checkAuthenticationState()

        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let signInConfig = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.configuration = signInConfig
    }

    internal func checkAuthenticationState() {
        guard let user = Auth.auth().currentUser else {
            withAnimation {
                self.isLoggedIn = false
                self.name = nil
                self.email = nil
                self.house = nil
                self.schoolCode = nil
                self.schoolName = nil
            }
            return
        }

        let name = user.displayName
        let email = user.email
        withAnimation {
            self.name = name
            self.email = email
        }

        Task {
            do {
                try await self.checkAndCreateAccountInFirestore()

                let schoolCode = try await self.fetchSchoolCode()
                withAnimation {
                    self.schoolCode = schoolCode
                }

                let house = try await self.fetchUsersHouse()
                withAnimation {
                    self.house = house
                }
            } catch {
                throw error
            }

            do {
                let schoolName = try await self.fetchSchoolName()
                withAnimation {
                    self.schoolName = schoolName
                }
            } catch {
                throw error
            }
        }

        withAnimation {
            self.isLoggedIn = true
        }
    }

    func signIn() async throws {
        guard let presentingController = getPresenter() else { return }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingController)

        let user = result.user
        guard let idToken = user.idToken?.tokenString else { return }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )

        Task {
            do {
                try await Auth.auth().signIn(with: credential)
            } catch {
                throw error
            }
            self.checkAuthenticationState()
        }

    }

    internal func getPresenter() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window,
              let presentingController = window?.rootViewController else {
            print("Could not get presenting uiviewcontroller")
            return nil
        }

        return presentingController
    }
}
