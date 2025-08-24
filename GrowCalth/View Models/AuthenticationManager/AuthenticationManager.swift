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

@MainActor
final class AuthenticationManager: ObservableObject {

    // TODO: - doesnt add house if its a new account
    @Published var isLoggedIn: Bool = false
    @Published var accountVerified: Bool = false
    @Published var email: String?
    @Published var usersHouse: String?
    @Published var accountType: AccountType = .unknown

    init() {
        verifyAuthenticationState()
        verifyVerificationState()
        Task {
            await updatePublishedVariables()
        }
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

    internal func updatePublishedVariables() async {
        let currentEmail = Auth.auth().currentUser?.email
        let house = try? await self.fetchUsersHouse()

        // Update all published properties on MainActor
        self.email = currentEmail
        if let house = house {
            self.usersHouse = house
        }

        let year = Calendar.current.component(.year, from: Date())
        if let currentEmail = currentEmail {
            if currentEmail == "appreview@s2021.ssts.edu.sg" || currentEmail == "admin@growcalth.com" || currentEmail == "growcalth@sst.edu.sg" {
                self.accountType = .special
            } else if GLOBAL_ADMIN_EMAILS.contains(currentEmail) {
                self.accountType = .admin
            } else {
                let domain = currentEmail.components(separatedBy: "@")[1]
                if domain == "sst.edu.sg" {
                    self.accountType = .teacher
                } else {
                    let emailYear = Int(domain.components(separatedBy: ".")[0].suffix(4)) ?? 0
                    if emailYear <= year-4 {
                        self.accountType = .alumnus
                    } else {
                        self.accountType = .student
                    }
                }
            }
        } else {
            self.accountType = .unknown
        }
    }

    internal func emailProvidedIsSSTEmail(email: String) throws {
        var returnResult = false

        let regexPatternSSTudent = "(.+)@s20\\d\\d.ssts.edu.sg"
        let predicateSSTudent = NSPredicate(format: "SELF MATCHES %@", regexPatternSSTudent)
        returnResult = predicateSSTudent.evaluate(with: email)

        let regexPatternSSTaff = "(.+)@sst.edu.sg"
        let predicateSSTaff = NSPredicate(format: "SELF MATCHES %@", regexPatternSSTaff)
        returnResult = returnResult || predicateSSTaff.evaluate(with: email)

        if !returnResult {
            throw EmailError.emailIsNotSSTEmail
        }
    }
}

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AuthenticationManager: ObservableObject {

    @Published var isLoggedIn: Bool?

    @Published var givenName: String?
    @Published var familyName: String?
    @Published var fullName: String?
    @Published var email: String?
    @Published var profilePicUrl: String?
    @Published var errorMessage: String?

    private init() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let signInConfig = GIDConfiguration(clientID: clientID)

        // load the email
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            self.email = email
        }

        GIDSignIn.sharedInstance.configuration = signInConfig
        restoreSignIn()
    }

    func checkStatus() {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            self.givenName = nil
            self.familyName = nil
            self.fullName = nil
            self.email = nil
            self.profilePicUrl = nil
            self.isLoggedIn = false
            return
        }

        let givenName = user.profile?.givenName
        let familyName = user.profile?.familyName
        let fullName = user.profile?.name
        let email = user.profile?.email
        let profilePicUrl = user.profile!.imageURL(withDimension: 100)!.absoluteString
        self.givenName = givenName
        self.familyName = familyName
        self.fullName = fullName
        self.email = email
        self.profilePicUrl = profilePicUrl
        self.isLoggedIn = true

        // save the email
        if let email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
    }

    private func restoreSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { _, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                self.errorMessage = "error: \(error.localizedDescription)"
            }

            self.checkStatus()
        }
    }

    func signIn() {
        guard let presentingController = getPresenter() else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingController) { [unowned self] result, error in
            guard error == nil else {
                self.errorMessage = "error: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                self.errorMessage = "error: \(error.localizedDescription)"
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { result, error in
              // At this point, our user is signed in
            }

            self.checkStatus()
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        UserDefaults.standard.removeObject(forKey: "userEmail")
        self.checkStatus()
    }

    func getPresenter() -> UIViewController? {
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
