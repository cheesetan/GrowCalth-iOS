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
    @State var isDeletingAccount = false

    @FocusState var isFieldFocus: FieldToFocus?

    internal enum FieldToFocus {
        case currentSecureField, currentTextField, newSecureField, newTextField
    }
    
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            List {
                Section("Personal Information") {
                    CustomLabeledContent("Name") {
                        VStack {
                            if let email = authManager.email {
                                Text(email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased())
                            } else {
                                Text("?")
                            }
                        }
                        .multilineTextAlignment(.trailing)
                    }

                    CustomLabeledContent("Email") {
                        VStack {
                            if let email = authManager.email {
                                Text(email)
                            } else {
                                Text("?")
                            }
                        }
                        .multilineTextAlignment(.trailing)
                    }

                    CustomLabeledContent("School") {
                        VStack {
                            if let schoolName = authManager.schoolName {
                                Text(schoolName)
                            } else {
                                Text("?")
                            }
                        }
                        .multilineTextAlignment(.trailing)
                    }

                    CustomLabeledContent("House") {
                        VStack {
                            if let house = authManager.house {
                                Text(house.capitalized)
                            } else {
                                Text("?")
                            }
                        }
                        .multilineTextAlignment(.trailing)
                    }

//                    CustomLabeledContent("Account Type") {
//                        VStack {
//                            Text(authManager.accountType.name)
//                        }
//                        .multilineTextAlignment(.trailing)
//                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteAccountAlert.toggle()
                    } label: {
                        if isDeletingAccount {
                            ProgressView()
                        } else {
                            Text("Delete account")
                                .tint(.red)
                        }
                    }
                    .disabled(isDeletingAccount)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Account")
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                isDeletingAccount = true
                Task {
                    do {
                        try await authManager.deleteAccount()
                    } catch {
                        alertHeader = "Error"
                        alertMessage = error.localizedDescription
                        showingAlert.toggle()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    AccountInfo()
}
