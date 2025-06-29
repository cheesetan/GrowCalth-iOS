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
    
    @EnvironmentObject var lbManager: LeaderboardsManager
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        List {
            Section {
                ForEach(sortDictionary(for: lbManager.leaderboard), id: \.key) { house in
                    houseRow(text: house.key, points: house.value)
                }
            } footer: {
                Text("GrowCalth calculates and updates the Leaderboard upon the first launch of the app every day. \(GLOBAL_STEPS_PER_POINT) steps = 1 point.\(GLOBAL_STEPS_PER_POINT == 2500 ? " (Limited Time Double Points Event!)" : "")\n\nGrowCalth needs to be opened to calculate and add your points, unclaimed points will accumulate and be added to the Leaderboard the next time you open the app.")
            }
        }
        .navigationTitle("Leaderboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
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
                Task {
                    do {
                        try await lbManager.resetLeaderboards(forHouse: "Black")
                        await lbManager.retrievePoints()
                        try await lbManager.resetLeaderboards(forHouse: "Blue")
                        await lbManager.retrievePoints()
                        try await lbManager.resetLeaderboards(forHouse: "Green")
                        await lbManager.retrievePoints()
                        try await lbManager.resetLeaderboards(forHouse: "Red")
                        await lbManager.retrievePoints()
                        try await lbManager.resetLeaderboards(forHouse: "Yellow")
                        await lbManager.retrievePoints()
                    } catch {
                        showingAlert = true
                        alertTitle = "Error"
                        alertTitle = "An error has occurred while attempting to reset GrowCalth points for Black house. Please try again."
                    }
                }
            }
        } message: {
            Text(alertMessage)
        }
        .refreshable {
            Task {
                await lbManager.retrievePoints()
            }
        }
        .onAppear {
            Task {
                await lbManager.retrievePoints()
                try await adminManager.checkIfUnderMaintenance()
                try await adminManager.checkIfAppForcesUpdates()
            }
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
