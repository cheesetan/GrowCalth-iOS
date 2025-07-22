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
    @EnvironmentObject var motionManager: MotionManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("Leaderboard")
                    .font(.largeTitle.bold())
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        let sortedDictionary = sortDictionary(for: lbManager.leaderboard)
                        leaderboardPodium(data: sortedDictionary)
                            .frame(height: geometry.size.height*0.65)
                        VStack(spacing: 15) {
                            let height = geometry.size.height*0.1
                            if height >= 6 {
                                houseRow(
                                    placing: "4TH",
                                    height: height,
                                    text: sortedDictionary[3].key,
                                    points: sortedDictionary[3].value
                                )
                                houseRow(
                                    placing: "5TH",
                                    height: height,
                                    text: sortedDictionary[4].key,
                                    points: sortedDictionary[4].value
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, geometry.size.height * 0.02)
                }
            }
            .padding([.horizontal, .bottom], 30)
        }
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
    func leaderboardPodium(data: Array<(key: String, value: Int)>) -> some View {
        GeometryReader { geometry in
            if geometry.size.width >= 30 {
                let barWidth = (geometry.size.width-30)/3
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: barWidth*0.8, height: barWidth*0.8)
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow, radius: barWidth)
                        Spacer()
                    }
                    GeometryReader { geometry2 in
                        HStack(alignment: .bottom) {
                            leaderboardRectanglePodium(house: data[2].key, points: data[2].value)
                                .frame(width: barWidth, height: geometry2.size.height*0.8)

                            leaderboardRectanglePodium(house: data[0].key, points: data[0].value)
                                .frame(width: barWidth, height: geometry2.size.height)

                            leaderboardRectanglePodium(house: data[1].key, points: data[1].value)
                                .frame(width: barWidth, height: geometry2.size.height*0.9)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .overlay {
                    LinearGradient(
                        gradient: Gradient(
                            stops: [
                                .init(color: .background, location: 0.1),
                                .init(color: .clear, location: 0.3),
                                .init(color: .clear, location: 1)
                            ]
                        ),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func leaderboardRectanglePodium(house: String, points: Int) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .foregroundStyle(Houses(rawValue: house)!.color)
                .overlay(alignment: .top) {
                    VStack(spacing: 10) {
                        Image(house)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.85, height: geometry.size.width * 0.85)
                            .mask(Circle())
                            .specularHighlight(for: .circle, motionManager: motionManager)

                        Text("\(points)")
                            .foregroundStyle(.white)
                            .font(.system(size: geometry.size.width * 0.2).weight(.black).italic())
                    }
                    .padding(.top, geometry.size.width * 0.25)
                }
        }
    }

    @ViewBuilder
    func houseRow(placing: String, height: CGFloat, text: String, points: Int) -> some View {
        Capsule()
            .frame(maxHeight: height)
            .foregroundStyle(Color.lbCapsuleBackground)
            .overlay {
                HStack(spacing: 30) {
                    let lbPlacingWidth = height*1.2
                    Capsule()
                        .frame(width: lbPlacingWidth)
                        .foregroundStyle(Color.lbPlacingBackground)
                        .background {
                            Capsule()
                                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 6.5)))
                                .foregroundStyle(Color.lbPlacingBackground)
                        }
                        .overlay {
                            Text(placing)
                                .font(.title2.weight(.black).italic())
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .padding(lbPlacingWidth*0.15)
                        }
                        .shadow(color: Color.shadow, radius: 17.5, x: 0, y: 5)
                        .overlay {
                            Capsule()
                                .stroke(Color.lbPlacingOutline, lineWidth: 2)
                        }
                    Capsule()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: Houses(rawValue: text)!.color, location: 0.7),
                                    .init(color: Color.lbHouseColorToFadeTo, location: 1.2)
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                        .background {
                            Capsule()
                                .fill(.shadow(.inner(color: .white.opacity(0.25), radius: 6.5)))
                                .foregroundStyle(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Houses(rawValue: text)!.color, location: 0.7),
                                            .init(color: Color.lbHouseColorToFadeTo, location: 1.2)
                                        ],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                        }
                        .overlay {
                            HStack {
                                Image(text)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: height-6, height: height-6)
                                    .mask(Circle())
                                Spacer()
                                Text("\(points) POINTS")
                                    .font(.title2.weight(.black).italic())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                                    .padding(lbPlacingWidth*0.15)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 6)
                            .padding(.trailing)
                        }
                        .shadow(color: Color.shadow, radius: 17.5, x: 0, y: 5)
                }
            }
    }
}

#Preview {
    LeaderboardView()
}
