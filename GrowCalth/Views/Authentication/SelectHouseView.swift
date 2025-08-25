//
//  SelectHouseView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/8/25.
//

import SwiftUI

struct SelectHouseView: View {

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

//    var housePicker: some View {
//        Group {
//            if #available(iOS 26.0, *) {
//                Picker("House Selection", selection: $houseSelection) {
//                    ForEach(Houses.allCases, id: \.hashValue) { house in
//                        if house != .selectHouse {
//                            Text(house.rawValue)
//                                .minimumScaleFactor(0.1)
//                                .tag(house)
//                        } else {
//                            if houseSelection == .selectHouse {
//                                Text(house.rawValue)
//                                    .tag(house)
//                                Divider()
//                            }
//                        }
//                    }
//                }
//                .padding(10)
//                .frame(maxWidth: .infinity)
//                .glassEffect()
//            } else {
//                Picker("House Selection", selection: $houseSelection) {
//                    ForEach(Houses.allCases, id: \.hashValue) { house in
//                        if house != .selectHouse {
//                            Text(house.rawValue)
//                                .minimumScaleFactor(0.1)
//                                .tag(house)
//                        } else {
//                            if houseSelection == .selectHouse {
//                                Text(house.rawValue)
//                                    .tag(house)
//                                Divider()
//                            }
//                        }
//                    }
//                }
//                .padding(10)
//                .frame(maxWidth: .infinity)
//                .background(.thickMaterial)
//                .mask(Capsule())
//            }
//        }
//    }

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
    SelectHouseView()
}
