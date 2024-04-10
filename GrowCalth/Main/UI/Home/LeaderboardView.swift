//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI
import SwiftPersistence

struct LeaderboardView: View {
    
    @State var loaded = false
    @State var leaderboardPoints = [String : Int]()
    
    @State var showingAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    @ObservedObject var lbManager: LeaderboardsManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    @Persistent("cachedLBPoints") var cachedLBPoints: [String : Int] = ["Black" : 0, "Blue" : 0, "Green" : 0, "Red" : 0, "Yellow" : 0]
    
    var body: some View {
        List {
            if loaded {
                Section {
                    ForEach(sortDictionary(for: leaderboardPoints), id: \.key) { house in
                        houseRow(text: house.key, points: house.value)
                    }
                } footer: {
                    Text("GrowCalth calculates and updates the Leaderboard upon the first launch of the app every day. 5000 steps = 1 point.\n\nGrowCalth needs to be opened to calculate and add your points, unclaimed points will accumulate and be added to the Leaderboard the next time you open the app.")
                }
            } else {
                Section {
                    ForEach(sortDictionary(for: cachedLBPoints), id: \.key) { house in
                        houseRow(text: house.key, points: house.value)
                    }
                } footer: {
                    Text("GrowCalth calculates and updates the Leaderboard upon the first launch of the app every day. 5000 steps = 1 point.\n\nGrowCalth needs to be opened to calculate and add your points, unclaimed points will accumulate and be added to the Leaderboard the next time you open the app.")
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Leaderboard")
//        .toolbar {
//            if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(role: .destructive) {
//                        showingAlert = true
//                        alertTitle = "Reset house points"
//                        alertMessage = "Are you sure you want to reset all house points? This action cannot be undone."
//                    } label: {
//                        Label("Reset house points", systemImage: "arrow.clockwise.circle")
//                    }
//                    .tint(.red)
//                }
//            }
//        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("Reset", role: .destructive) {
                lbManager.resetLeaderboards(forHouse: "Black") { result in
                    switch result {
                    case .success(_):
                        retrievePointsInformation()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset house points for Black house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Blue") { result in
                    switch result {
                    case .success(_):
                        retrievePointsInformation()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset house points for Blue house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Green") { result in
                    switch result {
                    case .success(_):
                        retrievePointsInformation()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset house points for Green house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Red") { result in
                    switch result {
                    case .success(_):
                        retrievePointsInformation()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset house points for Red house. Please try again."
                    }
                }
                lbManager.resetLeaderboards(forHouse: "Yellow") { result in
                    switch result {
                    case .success(_):
                        retrievePointsInformation()
                    case .failure(_):
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset house points for Yellow house. Please try again."
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
        .refreshable {
            retrievePointsInformation()
        }
        .onAppear {
            adminManager.checkIfUnderMaintenance() { }
            adminManager.checkIfAppForcesUpdates()
            print("cachedLBPoints before: \(cachedLBPoints)")
            retrievePointsInformation()
            print("cachedLBPoints after: \(cachedLBPoints)")
        }
    }
    
    func retrievePointsInformation() {
        lbManager.retrievePoints { _ in
            leaderboardPoints["Black"] = lbManager.black
            cachedLBPoints["Black"] = lbManager.black
            leaderboardPoints["Blue"] = lbManager.blue
            cachedLBPoints["Blue"] = lbManager.blue
            leaderboardPoints["Green"] = lbManager.green
            cachedLBPoints["Green"] = lbManager.green
            leaderboardPoints["Red"] = lbManager.red
            cachedLBPoints["Red"] = lbManager.red
            leaderboardPoints["Yellow"] = lbManager.yellow
            cachedLBPoints["Yellow"] = lbManager.yellow
            loaded = true
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
