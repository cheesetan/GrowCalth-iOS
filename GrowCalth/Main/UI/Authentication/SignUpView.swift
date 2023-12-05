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
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Join The House Today.")
                .fontWeight(.black)
                .font(.system(size: 35))
                .padding(.horizontal)
            
            VStack {
                infoFields
                signUpButton
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
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            
                passwordField
            
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
            .minimumScaleFactor(0.1)
            .pickerStyle(.menu)
            .padding(.vertical, 5)
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
            .textContentType(.newPassword)
            .keyboardType(.alphabet)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            
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
    
    var signUpButton: some View {
        Button {
            if !email.isEmpty && !password.isEmpty && houseSelection != .selectHouse {
                isLoading = true
                authManager.createAccount(email: email, password: password, house: houseSelection) { result in
                    switch result {
                    case .success(_):
                        isLoading = false
                        alertHeader = "Verify account"
                        alertMessage = "A verification email has been sent to your account's email address. Verify your email then try logging in again."
                        showingAlert = true
                    case .failure(let failure):
                        isLoading = false
                        alertHeader = "Error"
                        alertMessage = "\(failure.localizedDescription)"
                        showingAlert = true
                    }
                }
            }
        } label: {
            Text("Sign Up")
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
        .disabled(email.isEmpty || password.isEmpty || houseSelection == .selectHouse || isLoading)
    }
    
    var bottomText: some View {
        HStack {
            Text("Already have an account?")
                .minimumScaleFactor(0.1)
            Button {
                withAnimation {
                    signInView.toggle()
                }
            } label: {
                Text("Log In")
                    .foregroundColor(Color(hex: 0xDB5461))
                    .underline()
                    .fontWeight(.semibold)
            }
            .minimumScaleFactor(0.1)
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .padding(.top, 5)
    }
}

#Preview {
    SignUpView(signInView: .constant(false))
}
