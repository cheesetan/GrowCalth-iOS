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
    
    @FocusState var isFieldFocus: FieldToFocus?
    
    internal enum FieldToFocus {
        case secureField, textField
    }
    
    @EnvironmentObject var authManager: AuthenticationManager

    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 26.0, *) {
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.accent)
                    .glassEffect()
            } else {
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.accent)
                    .background(.ultraThickMaterial)
                    .mask(RoundedRectangle(cornerRadius: 32))
            }
            VStack(spacing: 5) {
                Text("Welcome Back")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("The House You Need.")
                    .fontWeight(.black)
                    .font(.title)
                    .multilineTextAlignment(.center)

                Text("Sign in to contribute to your House")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                infoFields
                forgotPassword
            }
            loginButton
            bottomText
        }
        .padding(.horizontal)
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    var infoFields: some View {
        VStack(spacing: 10) {
            emailField
            passwordField
        }
    }

    var emailField: some View {
        Group {
            if #available(iOS 26.0, *) {
                TextField(text: $email) {
                    Label("School Email", systemImage: "envelope")
                }
                .padding()
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .glassEffect()

            } else {
                TextField(text: $email) {
                    Label("School Email", systemImage: "envelope")
                }
                .padding()
                .background(.ultraThickMaterial)
                .mask(RoundedRectangle(cornerRadius: 16))
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            }
        }
    }

    var passwordField: some View {
        ZStack(alignment: .trailing) {
            Group {
                if #available(iOS 26.0, *) {
                    Group {
                        if showingPassword {
                            TextField(text: $password) {
                                Label("Password", systemImage: "lock")
                            }
                            .focused($isFieldFocus, equals: .textField)
                        } else {
                            SecureField(text: $password) {
                                Label("Password", systemImage: "lock")
                            }
                            .focused($isFieldFocus, equals: .secureField)
                        }
                    }
                    .padding()
                    .glassEffect()
                } else {
                    Group {
                        if showingPassword {
                            TextField(text: $password) {
                                Label("Password", systemImage: "lock")
                            }
                            .focused($isFieldFocus, equals: .textField)
                        } else {
                            SecureField(text: $password) {
                                Label("Password", systemImage: "lock")
                            }
                            .focused($isFieldFocus, equals: .secureField)
                        }
                    }
                    .padding()
                    .background(.ultraThickMaterial)
                    .mask(RoundedRectangle(cornerRadius: 16))
                }
            }
            .textContentType(.password)
            .keyboardType(.alphabet)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .submitLabel(.done)
            .onSubmit {
                if !email.isEmpty && !password.isEmpty && !isLoading {
                    signInWithPassword()
                }
            }

            Button {
                showingPassword.toggle()
            } label: {
                Image(systemName: showingPassword ? "eye.slash" : "eye")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .minimumScaleFactor(0.1)
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .onChange(of: showingPassword) { result in
                isFieldFocus = showingPassword ? .textField : .secureField
            }
        }
    }
    
    var forgotPassword: some View {
        HStack {
            Spacer()
            if #available(iOS 26.0, *) {
                Button {
                    forgottenPasswordEmail = email
                    showingForgotPassword.toggle()
                } label: {
                    Text("Forgot Password?")
                        .foregroundStyle(.accent)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .matchedTransitionSource(id: "forgotpassword", in: namespace)
            } else {
                Button {
                    forgottenPasswordEmail = email
                    showingForgotPassword.toggle()
                } label: {
                    Text("Forgot Password?")
                        .underline()
                }
                .foregroundColor(.accent)
                .minimumScaleFactor(0.1)
                .buttonStyle(.plain)
                .padding(.bottom, 5)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            if #available(iOS 26.0, *) {
                ForgotPasswordView(email: email, showingForgotPassword: $showingForgotPassword)
                    .presentationDetents([.height(200)])
                    .navigationTransition(.zoom(sourceID: "forgotpassword", in: namespace))
            } else if #available(iOS 16.0, *) {
                ForgotPasswordView(email: email, showingForgotPassword: $showingForgotPassword)
                    .presentationDetents([.height(300)])
            } else {
                ForgotPasswordView(email: email, showingForgotPassword: $showingForgotPassword)
            }
        }
    }
    
    var loginButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    signInWithPassword()
                } label: {
                    Text("Login")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isLoading ? .clear : loginButtonDisabled ? .primary : .white)
                        .font(.body.weight(.semibold))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .disabled(loginButtonDisabled)
                .glassEffect()
            } else {
                Button {
                    signInWithPassword()
                } label: {
                    Text("Login")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isLoading ? .clear : .white)
                        .font(.body.weight(.semibold))
                        .background(.accent)
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(loginButtonDisabled)
            }
        }
    }

    var loginButtonDisabled: Bool {
        if email.isEmpty || password.isEmpty || isLoading {
            return true
        } else {
            return false
        }
    }

    func signInWithPassword() {
        if !email.isEmpty && !password.isEmpty {
            isLoading = true
            Task {
                do {
                    let isVerified = try await authManager.signIn(email: email, password: password)
                    if !isVerified {
                        alertHeader = "Verify account"
                        alertMessage = "A verification email has been sent to your account's email address. Verify your email then try logging in again."
                        showingAlert = true
                    }
                } catch {
                    alertHeader = "Error"
                    alertMessage = "\(error.localizedDescription)"
                    showingAlert = true
                }
                isLoading = false
            }
        }
    }
    
    var bottomText: some View {
        VStack {
            HStack {
                Text("Dont have an account yet?")
                    .foregroundStyle(.secondary)
                Button {
                    withAnimation {
                        signInView.toggle()
                    }
                } label: {
                    Text("Sign Up")
                        .foregroundColor(.accent)
                        .underline()
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SignInView(signInView: .constant(true))
}
