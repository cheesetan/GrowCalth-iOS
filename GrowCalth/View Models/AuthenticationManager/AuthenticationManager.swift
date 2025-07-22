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
