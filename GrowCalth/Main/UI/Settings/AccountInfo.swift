//
//  AccountInfo.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/10/23.
//

import SwiftUI

struct AccountInfo: View {
    
    @State var errorMessage = String()
    
    @State var newPassword = ""
    @State var currentPassword = ""
    @State var passwordChangeFailed = false
    @State var passwordSuccessfullyChanged = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        List {
            Section("Your Email") {
                if let email = authManager.email {
                    Text(email)
                } else {
                    Text("Could not retrieve your email.")
                }
            }
            
            Section("Change Password") {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                Button {
                    authManager.updatePassword(from: currentPassword, to: newPassword) { result in
                        switch result {
                        case .success(_):
                            currentPassword = ""
                            newPassword = ""
                            passwordSuccessfullyChanged = true
                        case .failure(let failure):
                            errorMessage = failure.localizedDescription
                            passwordChangeFailed = true
                            print(failure)
                        }
                    }
                } label: {
                    Text("Change Password")
                }
            }
        }
        .navigationTitle("Account Information")
        .alert("Change Password", isPresented: $passwordSuccessfullyChanged) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password has been successfully changed.")
        }
        .alert("Error", isPresented: $passwordChangeFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    AccountInfo()
}
