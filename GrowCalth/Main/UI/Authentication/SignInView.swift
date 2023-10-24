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
    
    var body: some View {
        VStack {
            Text("The House You Need.")
                .fontWeight(.black)
                .font(.system(size: 35))
            
            VStack {
                TextField("Email Address", text: $email)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                
                Button {
                    
                } label: {
                    Text("Forgot Password?")
                        .underline()
                }
                .foregroundColor(.gray)
                .font(.subheadline)
                .buttonStyle(.plain)
                .padding(.bottom, 5)
                
                Button {
                    
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
                
                HStack {
                    Text("Dont have an account yet?")
                    Button {
                        signInView.toggle()
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
            .padding(.horizontal)
        }
    }
}

#Preview {
    SignInView(signInView: .constant(true))
}
