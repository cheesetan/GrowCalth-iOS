//
//  AccountInfo.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/10/23.
//

import SwiftUI

struct AccountInfo: View {
    
    @State var newPassword = ""
    @State var currentPassword = ""
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
                SecureField("New Password", text: $newPassword)
                Button {
                    authManager.updatePassword(to: newPassword)
                    currentPassword = ""
                    newPassword = ""
                    passwordSuccessfullyChanged = true
                } label: {
                    Text("Change Password")
                }
            }
        }
        .navigationTitle("Account info")
        .alert("Change Password", isPresented: $passwordSuccessfullyChanged) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password has been successfully changed.")
        }
    }
}

#Preview {
    AccountInfo()
}
