//
//  SignInView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct SignInView: View {
    
    @Binding var signInView: Bool
    
    @State var email = ""
    @State var password = ""
    @State var forgottenPasswordEmail = ""
    @State var showingForgotPassword = false
    @State var showingEmailSent = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        VStack {
            Text("The House You Need.")
                .fontWeight(.black)
                .font(.system(size: 35))
            
            VStack {
                infoFields
                forgotPassword
                loginButton
                bottomText
            }
            .padding(.horizontal)
        }
    }
    
    var infoFields: some View {
        VStack {
            TextField("Email Address", text: $email)
                .padding()
                .background(.ultraThickMaterial)
                .cornerRadius(16)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .padding()
                .background(.ultraThickMaterial)
                .cornerRadius(16)
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
        .font(.subheadline)
        .buttonStyle(.plain)
        .padding(.bottom, 5)
        .alert("Forgot Password", isPresented: $showingForgotPassword) {
            TextField("Email Address", text: $forgottenPasswordEmail)
                .keyboardType(.emailAddress)
            Button(role: .destructive) {
                authManager.forgotPassword(email: email)
                showingForgotPassword = false
                showingEmailSent = true
            } label: {
                Text("Reset Password")
            }
            .disabled(forgottenPasswordEmail.isEmpty)
        }
        .alert("Email sent", isPresented: $showingEmailSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your inbox for the password reset link.")
        }
    }
    
    var loginButton: some View {
        Button {
            if !email.isEmpty && !password.isEmpty {
                authManager.signIn(email: email, password: password)
            }
        } label: {
            Text("Login")
                .padding()
                .frame(maxWidth: 300)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .background(Color(hex: 0xDB5461))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(email.isEmpty || password.isEmpty)
    }
    
    var bottomText: some View {
        VStack {
            HStack {
                Text("Dont have an account yet?")
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
            .font(.subheadline)
            .padding(.top, 5)
            
            Text("Your house is waiting for ya!")
                .font(.subheadline)
        }
    }
}

#Preview {
    SignInView(signInView: .constant(true))
}
