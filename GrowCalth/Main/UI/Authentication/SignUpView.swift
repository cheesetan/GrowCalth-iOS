//
//  SignUpView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct SignUpView: View {
    
    @Binding var signInView: Bool
    
    @State var email = ""
    @State var password = ""
    @State var houseSelection: Houses = .selectHouse
    
    enum Houses: String, CaseIterable {
        case selectHouse = "Select your house"
        case black = "Black"
        case blue = "Blue"
        case green = "Green"
        case red = "Red"
        case yellow = "Yellow"
    }
    
    var body: some View {
        VStack {
            Text("Join The House Today.")
                .fontWeight(.black)
                .font(.system(size: 35))
            
            VStack {
                TextField("Email Address", text: $email)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                
                TextField("Password", text: $password)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                
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
                
                Button {
                    
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
                
                HStack {
                    Text("Already have an account?")
                    Button {
                        signInView.toggle()
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
            .padding(.horizontal)
        }
    }
}

#Preview {
    SignUpView(signInView: .constant(false))
}
