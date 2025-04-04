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
    
    @State var showingDeleteAccountAlert = false
    @State var deleteAccountPassword = ""
    @State var isDeletingAccount = false
    
    @FocusState var isFieldFocus: FieldToFocus?
    
    internal enum FieldToFocus {
        case currentSecureField, currentTextField, newSecureField, newTextField
    }
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        List {
            Section("Account Information") {
                LabeledContent("Name") {
                    VStack {
                        if let email = authManager.email {
                            Text(email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased())
                        } else {
                            Text("?")
                        }
                    }
                    .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Email") {
                    VStack {
                        if let email = authManager.email {
                            Text(email)
                        } else {
                            Text("?")
                        }
                    }
                    .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("House") {
                    VStack {
                        if let house = authManager.usersHouse {
                            Text(house)
                        } else {
                            Text("?")
                        }
                    }
                    .multilineTextAlignment(.trailing)
                }

                LabeledContent("Account Type") {
                    VStack {
                        Text(authManager.accountType.name)
                    }
                    .multilineTextAlignment(.trailing)
                }
            }
            
            Section {
                NavigationLink {
                    changePassword
                } label: {
                    Text("Change Password")
                }
            }
            
            Section {
                Button {
                    showingDeleteAccountAlert.toggle()
                } label: {
                    if isDeletingAccount {
                        ProgressView()
                    } else {
                        Text("Delete account")
                    }
                }
                .tint(.red)
                .disabled(isDeletingAccount)
            }
        }
        .navigationTitle("Account")
        .alert("Delete account", isPresented: $showingDeleteAccountAlert) {
            SecureField("Current Password", text: $deleteAccountPassword)
            Button("Delete", role: .destructive) {
                isDeletingAccount = true
                authManager.deleteAccount(password: deleteAccountPassword) { result in
                    isDeletingAccount = false
                    switch result {
                    case .success(_):
                        break
                    case .failure(let failure):
                        alertHeader = "Error"
                        alertMessage = failure.localizedDescription
                        showingAlert.toggle()
                    }
                }
                deleteAccountPassword = ""
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
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
                Section {
                    VStack {
                        if showingCurrentPassword {
                            HStack {
                                TextField("Current Password", text: $currentPassword)
                                    .focused($isFieldFocus, equals: .currentTextField)
                                toggleCurrentPassword
                            }
                        } else {
                            HStack {
                                SecureField("Current Password", text: $currentPassword)
                                    .focused($isFieldFocus, equals: .currentSecureField)
                                toggleCurrentPassword
                            }
                        }
                    }
                    .textContentType(.password)
                    .keyboardType(.alphabet)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                    
                    VStack {
                        if showingNewPassword {
                            HStack {
                                TextField("New Password", text: $newPassword)
                                    .focused($isFieldFocus, equals: .newTextField)
                                toggleNewPassword
                            }
                        } else {
                            HStack {
                                SecureField("New Password", text: $newPassword)
                                    .focused($isFieldFocus, equals: .newSecureField)
                                toggleNewPassword
                            }
                        }
                    }
                    .textContentType(.newPassword)
                    .keyboardType(.alphabet)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                } header: {
                    Text("Password")
                } footer: {
                    Text("Your new password must be at least 6 characters long.")
                }
                
                Section {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button {
                            if !isLoading && !currentPassword.isEmpty && !newPassword.isEmpty {
                                alertHeader = "Change Password"
                                alertMessage = "Are you sure you want to change your password?"
                                showingAlertWithConfirmation = true
                            }
                        } label: {
                            Text("Change Password")
                        }
                        .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty)
                    }
                }
            }
            .navigationTitle("Change Password")
        }
    }
    
    var toggleNewPassword: some View {
        Button {
            showingNewPassword.toggle()
        } label: {
            Image(systemName: showingNewPassword ? "eye.slash" : "eye")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .onChange(of: showingNewPassword) { newValue in
            if newValue == true {
                isFieldFocus = .newTextField
            } else {
                isFieldFocus = .newSecureField
            }
        }
    }
    
    var toggleCurrentPassword: some View {
        Button {
            showingCurrentPassword.toggle()
        } label: {
            Image(systemName: showingCurrentPassword ? "eye.slash" : "eye")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .onChange(of: showingCurrentPassword) { newValue in
            if newValue == true {
                isFieldFocus = .currentTextField
            } else {
                isFieldFocus = .currentSecureField
            }
        }
    }
}

#Preview {
    AccountInfo()
}
