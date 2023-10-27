//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    
    @State var loaded = false
    @State var leaderboardPoints = [String: Int?]()
    @ObservedObject var lbManager: LeaderboardsManager = .shared
    
    var body: some View {
        List {
            if loaded {
                ForEach(sortedDictionary(), id: \.key) { house in
                    houseRow(text: house.key, points: house.value ?? 0)
                }
            } else {
                ProgressView()
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Leaderboard")
        .refreshable {
            retrieveInformation()
            
        }
        .onAppear {
            retrieveInformation()
        }
    }
    
    func retrieveInformation() {
        lbManager.retrievePoints { _ in
            leaderboardPoints["Black"] = lbManager.black
            leaderboardPoints["Blue"] = lbManager.blue
            leaderboardPoints["Green"] = lbManager.green
            leaderboardPoints["Red"] = lbManager.red
            leaderboardPoints["Yellow"] = lbManager.yellow
            loaded = true
        }
    }
    
    private func sortedDictionary() -> Array<(key: String, value: Optional<Int>)> {
        leaderboardPoints.sorted { $0.value ?? 0 > $1.value ?? 0 }.sorted { first, second in
            if first.value ?? 0 == second.value ?? 0 {
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
