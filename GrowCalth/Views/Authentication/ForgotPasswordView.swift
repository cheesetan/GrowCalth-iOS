//
//  ForgotPasswordView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI

struct ForgotPasswordView: View {

    let alert_success_title = "Password Reset Email Sent"

    @State var email: String
    @State var forgotPasswordLoading = false
    @Binding var showingForgotPassword: Bool
    
    @State var showingAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @FocusState var emailFocused: Bool

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var authManager: AuthenticationManager

    var buttonDisabled: Bool {
        email.isEmpty || forgotPasswordLoading
    }

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
                if alertHeader == alert_success_title {
                    dismiss.callAsFunction()
                    showingForgotPassword = false
                }
            }
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
                Button {
                    sendForgotPasswordRequest()
                } label: {
                    Text("Reset Password")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(forgotPasswordLoading ? .clear : buttonDisabled ? .primary : .white)
                        .font(.body.weight(.semibold))
                        .overlay {
                            if forgotPasswordLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .disabled(buttonDisabled)
                .glassEffect()
            } else {
                Button {
                    sendForgotPasswordRequest()
                } label: {
                    Text("Reset Password")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(forgotPasswordLoading ? .clear : .white)
                        .font(.body.weight(.semibold))
                        .background(.accent)
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            if forgotPasswordLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(buttonDisabled)
            }
        }
    }

    func sendForgotPasswordRequest() {
        emailFocused = false
        forgotPasswordLoading = true
        Task {
            do {
                try await authManager.forgotPassword(email: email)
                alertHeader = alert_success_title
                alertMessage = "We've sent a password reset link to your email. If you don't see it in your inbox, be sure to check your junk or spam folder as well."
            } catch {
                alertHeader = "Error"
                alertMessage = "\(error.localizedDescription)"
            }
            showingAlert = true
            forgotPasswordLoading = false
        }
    }
}
