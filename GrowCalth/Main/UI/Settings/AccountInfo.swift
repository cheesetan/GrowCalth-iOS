//
//  AccountInfo.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/10/23.
//

import SwiftUI
import FirebaseAuth

struct AccountInfo: View {
    
    @State var isLoading = false
    
    @State var newPassword = ""
    @State var currentPassword = ""
    
    @State var showingNewPassword = false
    @State var showingCurrentPassword = false
    
    @State var showingAlert = false
    @State var showingAlertWithConfirmation = false
    @State var alertHeader = ""
    @State var alertMessage = ""
    
    @FocusState var newPasswordFocused: Bool
    @FocusState var currentPasswordFocused: Bool
    
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
        .alert(alertHeader, isPresented: $showingAlertWithConfirmation) {
            Button("Change Password", role: .destructive) {
                isLoading = true
                authManager.updatePassword(from: currentPassword, to: newPassword) { result in
                    switch result {
                    case .success(_):
                        isLoading = false
                        currentPassword = ""
                        newPassword = ""
                        alertHeader = "Password Changed"
                        alertMessage = "Your password has been successfully changed."
                        showingAlert = true
                    case .failure(let failure):
                        isLoading = false
                        alertHeader = "Error"
                        alertMessage = "\(failure.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    var changePassword: some View {
        VStack {
            List {
                if showingCurrentPassword {
                    HStack {
                        TextField("Current Password", text: $currentPassword)
                            .focused($currentPasswordFocused)
                        toggleCurrentPassword
                    }
                } else {
                    HStack {
                        SecureField("Current Password", text: $currentPassword)
                            .focused($currentPasswordFocused)
                        toggleCurrentPassword
                    }
                }
                
                if showingNewPassword {
                    HStack {
                        TextField("New Password", text: $newPassword)
                            .focused($newPasswordFocused)
                        toggleNewPassword
                    }
                } else {
                    HStack {
                        SecureField("New Password", text: $newPassword)
                            .focused($newPasswordFocused)
                        toggleNewPassword
                    }
                }
                
                if isLoading {
                    ProgressView()
                } else {
                    Button {
                        alertHeader = "Change Password"
                        alertMessage = "Are you sure you want to change your password?"
                        showingAlertWithConfirmation = true
                    } label: {
                        Text("Change Password")
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Change Password")
        }
    }
    
    var toggleNewPassword: some View {
        Button {
            showingNewPassword.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                newPasswordFocused = true
            }
        } label: {
            Image(systemName: showingNewPassword ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
    
    var toggleCurrentPassword: some View {
        Button {
            showingCurrentPassword.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                currentPasswordFocused = true
            }
        } label: {
            Image(systemName: showingCurrentPassword ? "eye.slash" : "eye")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AccountInfo()
}
