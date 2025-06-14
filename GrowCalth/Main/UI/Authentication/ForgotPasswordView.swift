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
        if #available(iOS 16.0, *) {
            NavigationStack {
                main
            }
        } else {
            NavigationView {
                main
            }
            .navigationViewStyle(.stack)
        }
    }

    var main: some View {
        VStack(spacing: 15) {
            Spacer()
            emailField
            resetPasswordButton
            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle("Forgot Password?")
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

    var emailField: some View {
        Group {
            if #available(iOS 26.0, *) {
                TextField("Email Address", text: $email)
                    .padding()
                    .glassEffect()
            } else {
                TextField("Email Address", text: $email)
                    .padding()
                    .background(.ultraThickMaterial)
                    .mask(RoundedRectangle(cornerRadius: 16))
            }
        }
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
    }

    var resetPasswordButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button(role: .destructive) {
                    sendForgotPasswordRequest()
                } label: {
                    VStack {
                        if forgotPasswordLoading {
                            ProgressView()
                        } else {
                            Text("Send Reset Password Email")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || forgotPasswordLoading)
                .glassEffect()
                .controlSize(.large)
            } else {
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
                    .font(.headline.weight(.bold))
                    .mask(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(email.isEmpty || forgotPasswordLoading)
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
