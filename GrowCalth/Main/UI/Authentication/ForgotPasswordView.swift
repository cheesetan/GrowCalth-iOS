//
//  ForgotPasswordView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @State var email: String
    @State var forgotPasswordLoading = false
    @Binding var showingForgotPassword: Bool
    
    @State var showingAlert = false
    @State var showingErrorAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @FocusState var emailFocused: Bool
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Spacer()
                Text("Enter the email address you want to reset the password for.")
                    .multilineTextAlignment(.center)
                    .fontWeight(.semibold)
                TextField("Email Address", text: $email)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused($emailFocused)
                    .onSubmit {
                        if !forgotPasswordLoading && !email.isEmpty {
                            sendForgotPasswordRequest()
                        }
                    }
                
                Button(role: .destructive) {
                    sendForgotPasswordRequest()
                } label: {
                    VStack {
                        if forgotPasswordLoading {
                            ProgressView()
                        } else {
                            Text("Reset Password")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty ? .red.opacity(0.5) : forgotPasswordLoading ? .red.opacity(0.5) : .red)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .font(.headline)
                    .cornerRadius(16)
                }
                .disabled(email.isEmpty || forgotPasswordLoading)
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertHeader, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    showingForgotPassword = false
                }
            } message: {
                Text(alertMessage)
            }
            .alert(alertHeader, isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func sendForgotPasswordRequest() {
        emailFocused = false
        forgotPasswordLoading = true
        authManager.forgotPassword(email: email) { result in
            switch result {
            case .success(_):
                forgotPasswordLoading = false
                alertHeader = "Email sent"
                alertMessage = "Check your inbox for the password reset link."
                showingAlert = true
            case .failure(let failure):
                forgotPasswordLoading = false
                alertHeader = "Error"
                alertMessage = "\(failure.localizedDescription)"
                showingErrorAlert = true
            }
        }
    }
}
