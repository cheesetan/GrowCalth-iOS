//
//  SignInView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI
import KeychainAccess

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
        .onOpenURL { url in
            handleMagicLink(url: url)
        }
        .onAppear {
            let keychain = Keychain(service: "com.kidcodes.growcalth")
            keychain["kishikawakatsumi"] = "01234567-89ab-cdef-0123-456789abcdef"
        }
    }
    
    private func handleMagicLink(url: URL) {
        isLoading = true
        Task {
            await authManager.handleMagicLink(url: url) { result in
                switch result {
                case .success(_):
                    isLoading = false
                case .failure(let failure):
                    isLoading = false
                    alertHeader = "Error"
                    alertMessage = failure.localizedDescription
                    showingAlert = true
                }
            }
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
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
            
            passwordField
        }
    }
    
    var passwordField: some View {
        ZStack(alignment: .trailing) {
            VStack {
                if showingPassword {
                    TextField("Password", text: $password)
                        .focused($isFieldFocus, equals: .textField)
                } else {
                    SecureField("Password", text: $password)
                        .focused($isFieldFocus, equals: .secureField)
                }
            }
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(16)
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
        Button {
            forgottenPasswordEmail = email
            showingForgotPassword.toggle()
        } label: {
            HStack {
                Text("Forgot Password?")
                    .underline()
            }
        }
        .foregroundColor(.gray)
        .minimumScaleFactor(0.1)
        .buttonStyle(.plain)
        .padding(.bottom, 5)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(email: email, showingForgotPassword: $showingForgotPassword)
            .presentationDetents([.height(300)])
        }
    }
    
    var loginButton: some View {
        Button {
            if authManager.magicLinkAuthenticationEnabled {
                if !email.isEmpty && password.isEmpty {
                    sendMagicLink()
                } else {
                    signInWithPassword()
                }
            } else {
                signInWithPassword()
            }
        } label: {
            Text(!email.isEmpty && password.isEmpty ? authManager.magicLinkAuthenticationEnabled ? "Login via Magic Link" : "Login" : "Login")
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
        .disabled(loginButtonDisabled)
    }
    
    var loginButtonDisabled: Bool {
        if authManager.magicLinkAuthenticationEnabled {
            if email.isEmpty || isLoading {
                return true
            } else {
                return false
            }
        } else {
            if email.isEmpty || password.isEmpty || isLoading {
                return true
            } else {
                return false
            }
        }
    }
    
    func signInWithPassword() {
        if !email.isEmpty && !password.isEmpty {
            isLoading = true
            authManager.signIn(email: email, password: password) { result in
                switch result {
                case .success(let success):
                    isLoading = false
                    if success == false {
                        alertHeader = "Verify account"
                        alertMessage = "A verification email has been sent to your account's email address. Verify your email then try logging in again."
                        showingAlert = true
                    }
                case .failure(let failure):
                    isLoading = false
                    alertHeader = "Error"
                    alertMessage = "\(failure.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    func sendMagicLink() {
        if !email.isEmpty && password.isEmpty {
            isLoading = true
            Task {
                await authManager.sendMagicLink(email: email) { result in
                    switch result {
                    case .success(_):
                        isLoading = false
                        alertHeader = "Magic Link sent"
                        alertMessage = "Check your email to continue with login."
                        showingAlert = true
                    case .failure(let failure):
                        isLoading = false
                        alertHeader = "Error"
                        alertMessage = failure.localizedDescription
                        showingAlert = true
                    }
                }
            }
        }
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
