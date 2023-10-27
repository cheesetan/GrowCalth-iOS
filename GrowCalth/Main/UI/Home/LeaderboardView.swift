//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    
    @ObservedObject var lbManager: LeaderboardsManager = .shared
    
    var body: some View {
        List {
            if let points = lbManager.black {
                houseRow(text: "Black", points: points)
            }
            if let points = lbManager.blue {
                houseRow(text: "Blue", points: points)
            }
            if let points = lbManager.green {
                houseRow(text: "Green", points: points)
            }
            if let points = lbManager.red {
                houseRow(text: "Red", points: points)
            }
            if let points = lbManager.yellow {
                houseRow(text: "Yellow", points: points)
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Leaderboard")
        .refreshable {
            lbManager.retrievePoints()
        }
        .onAppear {
            lbManager.retrievePoints()
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
