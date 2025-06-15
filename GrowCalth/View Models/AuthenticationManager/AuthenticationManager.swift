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
        email = Auth.auth().currentUser?.email

        if let house = try? await self.fetchUsersHouse() {
            await MainActor.run {
                self.usersHouse = house
            }
        }

        let year = Calendar.current.component(.year, from: Date())
        if let email {
            if email == "appreview@s2021.ssts.edu.sg" || email == "admin@growcalth.com" || email == "growcalth@sst.edu.sg" {
                await MainActor.run {
                    self.accountType = .special
                }
            } else if GLOBAL_ADMIN_EMAILS.contains(email) {
                await MainActor.run {
                    self.accountType = .admin
                }
            } else {
                let domain = email.components(separatedBy: "@")[1]
                if domain == "sst.edu.sg" {
                    await MainActor.run {
                        self.accountType = .teacher
                    }
                } else {
                    let emailYear = Int(domain.components(separatedBy: ".")[0].suffix(4)) ?? 0
                    if emailYear <= year-4 {
                        await MainActor.run {
                            self.accountType = .alumnus
                        }
                    } else {
                        await MainActor.run {
                            self.accountType = .student
                        }
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
        returnResult = predicateSSTaff.evaluate(with: email)
        
        if !returnResult {
            throw EmailError.emailIsNotSSTEmail
        }
    }
}
