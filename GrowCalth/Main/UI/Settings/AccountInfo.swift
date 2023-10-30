//
//  AccountInfo.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/10/23.
//

import SwiftUI
import FirebaseAuth

struct AccountInfo: View {
    
    @State var newPassword = ""
    @State var currentPassword = ""
    
    @State var showingAlert = false
    @State var alertHeader = ""
    @State var alertMessage = ""
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        List {
            Section("Email") {
                if let email = authManager.email {
                    Text(email)
                } else {
                    Text("Could not retrieve your email.")
                }
            }
            
            Section {
                NavigationLink {
                    changePassword
                } label: {
                    Text("Change Password")
                }
            }
        }
        .navigationTitle("Account")
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    var changePassword: some View {
        VStack {
            List {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                Button {
                    authManager.updatePassword(from: currentPassword, to: newPassword) { result in
                        switch result {
                        case .success(_):
                            currentPassword = ""
                            newPassword = ""
                            alertHeader = "Password Changed"
                            alertMessage = "Your password has been successfully changed."
                            showingAlert = true
                        case .failure(let failure):
                            alertHeader = "Error"
                            alertMessage = "\(failure.localizedDescription)"
                            showingAlert = true
                        }
                    }
                } label: {
                    Text("Change Password")
                }
            }
            .navigationTitle("Change Password")
        }
    }
}

#Preview {
    AccountInfo()
}
