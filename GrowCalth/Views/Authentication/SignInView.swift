//
//  SignInView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct SignInView: View {

    let verify_account_alert_header = "Verify Account"

    @Binding var signInView: Bool
    
    @State var isLoading = false
    @State var alertIsLoading = false

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
    @EnvironmentObject var motionManager: MotionManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 30) {
                if #available(iOS 26.0, *) {
                    Image(systemName: "house.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(30)
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.accent)
                        .glassEffect()
                        .mask(Circle())
                        .specularHighlight(
                            for: .circle,
                            motionManager: motionManager,
                            strokeWidth: 2.0
                        )
                } else {
                    Image(systemName: "house.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(30)
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.accent)
                        .background(.thickMaterial)
                        .mask(Circle())
                        .specularHighlight(
                            for: .circle,
                            motionManager: motionManager,
                            strokeWidth: 2.0
                        )
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
            .padding(30)
        }
        .alert(alertHeader, isPresented: $showingAlert) {
            if alertHeader == verify_account_alert_header {
                if #available(iOS 26.0, *) {
                    Button("Close", role: .close) {}
                    Button(role: .confirm) {
                        sendVerificationEmail()
                    } label: {
                        if alertIsLoading {
                            ProgressView()
                        } else {
                            Text("Send Again")
                        }
                    }
                } else {
                    Button("Cancel", role: .cancel) {}
                    Button {
                        sendVerificationEmail()
                    } label: {
                        if alertIsLoading {
                            ProgressView()
                        } else {
                            Text("Send Again")
                        }
                    }
                }
            } else {
                Button("OK", role: .cancel) {}
            }
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
                .background(.thickMaterial)
                .mask(Capsule())
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            }
        }
        .accessibilityLabel("Email")
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
                    .background(.thickMaterial)
                    .mask(Capsule())
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
            .accessibilityLabel("Password")

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
            .accessibilityLabel(showingPassword ? "Hide" : "Show")
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
            } else {
                Button {
                    forgottenPasswordEmail = email
                    showingForgotPassword.toggle()
                } label: {
                    Text("Forgot Password?")
                        .foregroundStyle(.accent)
                        .padding(5)
                        .padding(.horizontal, 5)
                        .background(.thickMaterial)
                        .mask(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            if #available(iOS 16.0, *) {
                ForgotPasswordView(email: email, showingForgotPassword: $showingForgotPassword)
                    .presentationDetents([.height(200)])
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
                        .foregroundColor(isLoading ? .clear : .white)
                        .font(.body.weight(.semibold))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.glassProminent)
                .disabled(loginButtonDisabled)
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
                        .mask(Capsule())
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

    func signInWithPassword() {
        if !email.isEmpty && !password.isEmpty {
            isLoading = true
            Task {
                do {
                    let isVerified = try await authManager.signIn(email: email, password: password)
                    if !isVerified {
                        try await authManager.signOut()
                        alertHeader = verify_account_alert_header
                        alertMessage = "We've sent a verification email to your SST email address. Please verify your email before logging in again, and don’t forget to check your junk or spam folder. If you didn’t receive the email, click \"Send Again\" to resend it."
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

    func sendVerificationEmail() {
        alertIsLoading = true
        Task {
            do {
                let _ = try await authManager.signIn(email: email, password: password)
                let user = try authManager.getCurrentUser()
                try await authManager.verifyEmail(user: user)
            } catch {
                alertHeader = "Error"
                alertMessage = "\(error.localizedDescription)"
                showingAlert = true
            }
            try await authManager.signOut()
            alertIsLoading = false
        }
    }
}

#Preview {
    SignInView(signInView: .constant(true))
}
