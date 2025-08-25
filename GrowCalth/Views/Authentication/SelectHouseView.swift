//
//  SelectHouseView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/8/25.
//

import SwiftUI

struct SelectHouseView: View {

    @State private var isLoading = false

    @State private var houseSelection = ""

    @State private var alertShowing = false
    @State private var alertHeader = ""
    @State private var alertMessage = ""

    @EnvironmentObject private var lbManager: LeaderboardsManager
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Select your House.")
                        .fontWeight(.black)
                        .font(.title)

                    Text(authManager.schoolName ?? "Pick a House to continue.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                housePicker
                continueButton
            }
            .padding(AppState.padding)
        }
        .alert(alertHeader, isPresented: $alertShowing) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await lbManager.retrieveLeaderboard()
            }
        }
    }

    var housePicker: some View {
        Group {
            if #available(iOS 26.0, *) {
                Picker("House Selection", selection: $houseSelection) {
                    if houseSelection.isEmpty {
                        Text("Select your House")
                            .tag("")
                        Divider()
                    }
                    ForEach(lbManager.leaderboard) { house in
                        Text(house.name)
                            .tag(house.id)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .glassEffect()
            } else {
                Picker("House Selection", selection: $houseSelection) {
                    if houseSelection.isEmpty {
                        Text("Select your House")
                            .tag("")
                        Divider()
                    }
                    ForEach(lbManager.leaderboard) { house in
                        Text(house.name)
                            .tag(house.id)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.thickMaterial)
                .mask(Capsule())
            }
        }
    }

    var continueButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    continueButtonPressed()
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
                .disabled(houseSelection.isEmpty)
            } else {
                Button {
                    continueButtonPressed()
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
                .disabled(houseSelection.isEmpty)
            }
        }
    }

    func continueButtonPressed() {
        if !houseSelection.isEmpty {
            isLoading = true
            Task {
                do {
                    try await authManager.setUserHouse(houseId: houseSelection)
                } catch {
                    alertHeader = "Error"
                    alertMessage = error.localizedDescription
                    alertShowing = true
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    SelectHouseView()
}
