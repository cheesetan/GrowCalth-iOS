//
//  SignUpView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

enum Houses: String, CaseIterable {
    case selectHouse = "Select your house"
    case black = "Black"
    case blue = "Blue"
    case green = "Green"
    case red = "Red"
    case yellow = "Yellow"
}

struct SignUpView: View {
    
    @Binding var signInView: Bool
    
    @State var isLoading = false
    
    @State var email = ""
    @State var password = ""
    @State var showingPassword = false
    @State var houseSelection: Houses = .selectHouse
    
    @State var alertHeader = ""
    @State var alertMessage = ""
    @State var showingAlert = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    @FocusState var isFieldFocus: FieldToFocus?
    
    internal enum FieldToFocus {
        case secureField, textField
    }

    var buttonDisabled: Bool {
        email.isEmpty || password.isEmpty || houseSelection == .selectHouse || isLoading
    }

    var body: some View {
        VStack(spacing: 30) {
            if #available(iOS 26.0, *) {
                Image(systemName: "person.and.person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.accent)
                    .glassEffect()
            } else {
                Image(systemName: "person.and.person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.accent)
                    .background(.ultraThickMaterial)
                    .mask(RoundedRectangle(cornerRadius: 32))
            }
            VStack(spacing: 5) {
                Text("Create Account")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Join The House Today.")
                    .fontWeight(.black)
                    .font(.title)
                    .multilineTextAlignment(.center)

                Text("Sign up to be part of the community")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            infoFields
            signUpButton
            bottomText
        }
        .padding(.horizontal)
        .alert(alertHeader, isPresented: $showingAlert) {
            if alertMessage == "An account with this email already exists. Please log in instead." {
                if #available(iOS 26.0, *) {
                    Button("Proceed to Login", role: .confirm) { signInView = true }
                } else {
                    Button("Proceed to Login") { signInView = true }
                }
            } else {
                if #available(iOS 26.0, *) {
                    Button("OK", role: .close) {}
                } else {
                    Button("OK", role: .cancel) {}
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    var infoFields: some View {
        VStack(spacing: 10) {
            emailField
            passwordField
            housePicker
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
                    signUp()
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

    var housePicker: some View {
        Group {
            if #available(iOS 26.0, *) {
                Picker("Select your house", selection: $houseSelection) {
                    ForEach(Houses.allCases, id: \.hashValue) { house in
                        if house != .selectHouse {
                            Text(house.rawValue)
                                .minimumScaleFactor(0.1)
                                .tag(house)
                        } else {
                            if houseSelection == .selectHouse {
                                Text(house.rawValue)
                                    .tag(house)
                                Divider()
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .glassEffect()
            } else {
                Picker("Select your house", selection: $houseSelection) {
                    ForEach(Houses.allCases, id: \.hashValue) { house in
                        if house != .selectHouse {
                            Text(house.rawValue)
                                .minimumScaleFactor(0.1)
                                .tag(house)
                        } else {
                            if houseSelection == .selectHouse {
                                Text(house.rawValue)
                                    .tag(house)
                                Divider()
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.ultraThickMaterial)
                .mask(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    var signUpButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    signUp()
                } label: {
                    Text("Sign Up")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isLoading ? .clear : buttonDisabled ? .primary : .white)
                        .font(.body.weight(.semibold))
                        .overlay {
                            if isLoading {
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
                    signUp()
                } label: {
                    Text("Sign Up")
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
                .disabled(buttonDisabled)
            }
        }
    }
    
    var bottomText: some View {
        VStack {
            HStack {
                Text("Already have an account?")
                    .foregroundStyle(.secondary)
                Button {
                    withAnimation {
                        signInView.toggle()
                    }
                } label: {
                    Text("Sign In")
                        .foregroundColor(.accent)
                        .underline()
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func signUp() {
        if !email.isEmpty && !password.isEmpty && houseSelection != .selectHouse {
            isLoading = true
            authManager.createAccount(email: email, password: password, house: houseSelection) { result in
                switch result {
                case .success(_):
                    isLoading = false
                    alertHeader = "Verify account"
                    alertMessage = "A verification email has been sent to your account's email address. Verify your email, then try logging in again."
                    signInView = true
                    showingAlert = true
                case .failure(let failure):
                    isLoading = false
                    alertMessage = "\(failure.localizedDescription)"
                    if alertMessage == "An account with this email already exists. Please log in instead." {
                        alertHeader = "Account Exists"
                    } else {
                        alertHeader = "Error"
                    }
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    SignUpView(signInView: .constant(false))
}
