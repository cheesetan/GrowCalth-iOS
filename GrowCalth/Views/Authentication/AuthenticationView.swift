//
//  AuthenticationView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct AuthenticationView: View {

    @State var isLoading = false

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
                       .specularHighlight(for: .circle, motionManager: motionManager)
               } else {
                   Image(systemName: "house.fill")
                       .resizable()
                       .scaledToFit()
                       .padding(30)
                       .frame(width: 100, height: 100)
                       .foregroundStyle(.accent)
                       .background(.thickMaterial)
                       .mask(Circle())
                       .specularHighlight(for: .circle, motionManager: motionManager)
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
                signInWithGoogleButton
            }
            .padding(AppState.padding)
        }
        .alert(alertHeader, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    var signInWithGoogleButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    signInWithGoogle()
                } label: {
                    Text("Sign In with Google")
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
            } else {
                Button {
                    signInWithGoogle()
                } label: {
                    Text("Sign In with Google")
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
            }
        }
    }

    func signInWithGoogle() {
        isLoading = true
        Task {
            do {
                try await authManager.signIn()
            } catch {
                alertHeader = "Error"
                alertMessage = "\(error.localizedDescription)"
                showingAlert = true
            }
            isLoading = false
        }
    }
}
