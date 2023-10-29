//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    
    @State var sampleLBPoints: [String : Int?] = ["Black" : nil, "Blue" : nil, "Green" : nil, "Red" : nil, "Yellow" : nil]
    
    @State var loaded = false
    @State var leaderboardPoints = [String : Int?]()
    @ObservedObject var lbManager: LeaderboardsManager = .shared
    
    var body: some View {
        List {
            if loaded {
                ForEach(sortDictionary(for: leaderboardPoints), id: \.key) { house in
                    houseRow(text: house.key, points: house.value ?? 0)
                }
            } else {
                ForEach(sortDictionary(for: sampleLBPoints), id: \.key) { house in
                    houseRow(text: house.key, points: nil)
                }
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
    
    private func sortDictionary(for dictionary: [String : Int?]) -> Array<(key: String, value: Optional<Int>)> {
        return dictionary.sorted { $0.value ?? 0 > $1.value ?? 0 }.sorted { first, second in
            if first.value ?? 0 == second.value ?? 0 {
                first.key < second.key
            } else {
                first.key == second.key
            }
        }
    }
    
    @ViewBuilder
    func houseRow(text: String, points: Int?) -> some View {
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
            if let points = points {
                Text("\(points)")
                    .font(.title)
                    .fontWeight(.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing)
            } else {
                ProgressView()
                    .font(.title)
                    .padding(.trailing)
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
