//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    
    @State var loaded = false

    @State var showingAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    @ObservedObject var lbManager: LeaderboardsManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared

    var body: some View {
        List {
            Section {
                ForEach(sortDictionary(for: lbManager.leaderboard), id: \.key) { house in
                    houseRow(text: house.key, points: house.value)
                }
            } footer: {
                Text("GrowCalth calculates and updates the Leaderboard upon the first launch of the app every day. \(GLOBAL_STEPS_PER_POINT) steps = 1 point.\n\nGrowCalth needs to be opened to calculate and add your points, unclaimed points will accumulate and be added to the Leaderboard the next time you open the app.")
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Leaderboard")
        .toolbar {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingAlert = true
                        alertTitle = "Reset GrowCalth points"
                        alertMessage = "Are you sure you want to reset all GrowCalth points? This action cannot be undone."
                    } label: {
                        Label("Reset GrowCalth points", systemImage: "arrow.clockwise.circle")
                    }
                    .tint(.red)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Reset", role: .destructive) {
                lbManager.resetLeaderboards(forHouse: "Black") { result in
                    switch result {
                    case .success(_):
                        lbManager.retrievePoints()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Black house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Blue") { result in
                    switch result {
                    case .success(_):
                        lbManager.retrievePoints()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Blue house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Green") { result in
                    switch result {
                    case .success(_):
                        lbManager.retrievePoints()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Green house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Red") { result in
                    switch result {
                    case .success(_):
                        lbManager.retrievePoints()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Red house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Yellow") { result in
                    switch result {
                    case .success(_):
                        lbManager.retrievePoints()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Yellow house. Please try again."
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
        .refreshable {
            lbManager.retrievePoints()
        }
        .onAppear {
            adminManager.checkIfUnderMaintenance() { }
            adminManager.checkIfAppForcesUpdates()
            lbManager.retrievePoints()
        }
    }

    private func sortDictionary(for dictionary: [String : Int]) -> Array<(key: String, value: Int)> {
        return dictionary.sorted { $0.value > $1.value }.sorted { first, second in
            if first.value == second.value {
                first.key < second.key
            } else {
                first.key == second.key
            }
        }
    }
    
    @ViewBuilder
    func houseRow(text: String, points: Int) -> some View {
        HStack {
            Image(text)
                .resizable()
                .scaledToFit()
                .frame(width: 64)
                .mask {
                    Circle()
                        .frame(width: 64)
                }
            Text(text)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.leading, 10)
            Spacer()
            Text("\(points)")
                .font(.title)
                .fontWeight(.black)
                .multilineTextAlignment(.trailing)
                .padding(.trailing)
        }
    }
}

#Preview {
    LeaderboardView()
}
