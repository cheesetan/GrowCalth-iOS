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
    
    @State var email = ""
    @State var password = ""
    @State var showingPassword = false
    @State var houseSelection: Houses = .selectHouse
    
    @State var alertHeader = ""
    @State var alertMessage = ""
    @State var showingAlert = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    @FocusState var passwordFieldFocused: Bool
    
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
            
                passwordField
            
            Picker("Select your house", selection: $houseSelection) {
                ForEach(Houses.allCases, id: \.hashValue) { house in
                    if house != .selectHouse {
                        Text(house.rawValue)
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
            .pickerStyle(.menu)
            .padding(.vertical, 5)
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
            .buttonStyle(.plain)
            .padding(.trailing, 20)
        }
    }
    
    var signUpButton: some View {
        Button {
            if !email.isEmpty && !password.isEmpty && houseSelection != .selectHouse {
                authManager.createAccount(email: email, password: password, house: houseSelection) { result in
                    switch result {
                    case .success(_):
                        break
                    case .failure(let failure):
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
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .background(Color(hex: 0xDB5461))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(email.isEmpty || password.isEmpty || houseSelection == .selectHouse)
    }
    
    var bottomText: some View {
        HStack {
            Text("Already have an account?")
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
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .padding(.top, 5)
    }
}

#Preview {
    SignUpView(signInView: .constant(false))
}
