//
//  EnterSchoolCodeView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/8/25.
//

import SwiftUI

struct EnterSchoolCodeView: View {

    @State private var isLoading = false

    @State private var referralCode = ""

    @State private var alertShowing = false
    @State private var alertHeader = ""
    @State private var alertMessage = ""

    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Enter Code")
                        .fontWeight(.black)
                        .font(.title)

                    Text("Enter the referral code given to you by your school to continue.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                codeField
                enterCodeButton
            }
            .padding(AppState.padding)
        }
        .alert(alertHeader, isPresented: $alertShowing) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }

    }

    var codeField: some View {
        Group {
            if #available(iOS 26.0, *) {
                TextField(text: Binding(get: {
                    referralCode
                }, set: { value in
                    if value.count <= 8 {
                        referralCode = value
                    }

                    if referralCode.count == 8 {
                        Task {
                            do {
                                try await authManager.getSchoolCode(fromReferralCode: referralCode)
                            } catch {
                                alertHeader = "Error"
                                alertMessage = error.localizedDescription
                                alertShowing = true
                            }
                        }
                    }
                })) {
                    Label("Referral Code", systemImage: "abc")
                }
                .padding()
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .glassEffect()
            } else {
                TextField(text: Binding(get: {
                    referralCode
                }, set: { value in
                    if value.count <= 8 {
                        referralCode = value
                    }

                    if referralCode.count >= 8 {
                        submitCode()
                    }
                })) {
                    Label("Referral Code", systemImage: "abc")
                }
                .padding()
                .background(.thickMaterial)
                .mask(Capsule())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            }
        }
        .accessibilityLabel("Referral Code")
    }

    var enterCodeButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    if referralCode.count >= 8 {
                        submitCode()
                    }
                } label: {
                    Text("Continue")
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
                .disabled(referralCode.count != 8)
            } else {
                Button {
                    if referralCode.count >= 8 {
                        submitCode()
                    }
                } label: {
                    Text("Continue")
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
                .disabled(referralCode.count != 8)
            }
        }
    }

    func submitCode() {
        isLoading = true
        Task {
            do {
                try await authManager.getSchoolCode(fromReferralCode: referralCode)
            } catch {
                alertHeader = "Error"
                alertMessage = error.localizedDescription
                alertShowing = true
            }
            isLoading = false
        }
    }
}

#Preview {
    EnterSchoolCodeView()
}
