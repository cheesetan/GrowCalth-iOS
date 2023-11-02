//
//  SignInView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct SignInView: View {
    
    @Binding var signInView: Bool
    
    @State var isLoading = false
    
    @State var email = ""
    @State var password = ""
    @State var showingPassword = false
    @State var forgottenPasswordEmail = ""
    @State var showingForgotPassword = false
    @State var showingAlert = false
    
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @FocusState var passwordFieldFocused: Bool
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("The House You\nNeed.")
                .fontWeight(.black)
                .font(.system(size: 35))
                .padding(.horizontal)
            
            VStack {
                infoFields
                forgotPassword
                loginButton
                bottomText
            }
            .padding(.horizontal)
        }
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    var infoFields: some View {
        VStack(spacing: 10) {
            TextField("Email Address", text: $email)
                .padding()
                .background(.ultraThickMaterial)
                .cornerRadius(16)
                .keyboardType(.emailAddress)
                .textContentType(.username)
            
            passwordField
        }
    }
    
    var passwordField: some View {
        ZStack(alignment: .trailing) {
            if showingPassword {
                TextField("Password", text: $password)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                    .textContentType(.password)
                    .focused($passwordFieldFocused)
            } else {
                SecureField("Password", text: $password)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                    .textContentType(.password)
                    .focused($passwordFieldFocused)
            }
            Button {
                showingPassword.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    passwordFieldFocused = true
                }
            } label: {
                Image(systemName: showingPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .minimumScaleFactor(0.1)
            .buttonStyle(.plain)
            .padding(.trailing, 20)
        }
    }
    
    var forgotPassword: some View {
        Button {
            forgottenPasswordEmail = email
            showingForgotPassword.toggle()
        } label: {
            Text("Forgot Password?")
                .underline()
        }
        .foregroundColor(.gray)
        .minimumScaleFactor(0.1)
        .buttonStyle(.plain)
        .padding(.bottom, 5)
        .alert("Forgot Password", isPresented: $showingForgotPassword) {
            TextField("Email Address", text: $forgottenPasswordEmail)
                .keyboardType(.emailAddress)
            Button(role: .destructive) {
                authManager.forgotPassword(email: email) { result in
                    switch result {
                    case .success(_):
                        alertHeader = "Email sent"
                        alertMessage = "Check your inbox for the password reset link."
                        showingForgotPassword = false
                        showingAlert = true
                    case .failure(let failure):
                        alertHeader = "Error"
                        alertMessage = "\(failure.localizedDescription)"
                        showingAlert = true
                    }
                }
            } label: {
                Text("Reset Password")
            }
            .disabled(forgottenPasswordEmail.isEmpty)
        }
    }
    
    var loginButton: some View {
        Button {
            if !email.isEmpty && !password.isEmpty {
                isLoading = true
                authManager.signIn(email: email, password: password) { result in
                    switch result {
                    case .success(_):
                        isLoading = false
                    case .failure(let failure):
                        isLoading = false
                        alertHeader = "Error"
                        alertMessage = "\(failure.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        } label: {
            Text("Login")
                .padding()
                .frame(maxWidth: 300)
                .foregroundColor(isLoading ? .clear : .white)
                .fontWeight(.semibold)
                .background(Color(hex: 0xDB5461))
                .cornerRadius(16)
                .overlay {
                    if isLoading {
                        ProgressView()
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(email.isEmpty || password.isEmpty || isLoading)
    }
    
    var bottomText: some View {
        VStack {
            HStack {
                Text("Dont have an account yet?")
                    .minimumScaleFactor(0.1)
                Button {
                    withAnimation {
                        signInView.toggle()
                    }
                } label: {
                    Text("Sign Up")
                        .foregroundColor(Color(hex: 0xDB5461))
                        .underline()
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            .minimumScaleFactor(0.1)
            .padding(.top, 5)
            
            Text("Your house is waiting for ya!")
                .minimumScaleFactor(0.1)
                .font(.subheadline)
        }
    }
}

#Preview {
    SignInView(signInView: .constant(true))
}
