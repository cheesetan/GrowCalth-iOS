//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    var body: some View {
        List {
            houseRow(text: "Black")
            houseRow(text: "Blue")
            houseRow(text: "Green")
            houseRow(text: "Red")
            houseRow(text: "Yellow")
        }
        .listStyle(.grouped)
        .navigationTitle("Leaderboard")
    }
    
    @ViewBuilder
    func houseRow(text: String) -> some View {
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
            Text("0")
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
