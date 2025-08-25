//
//  LeaderboardView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct LeaderboardView: View {
    
    @State var loaded = false
    
    @EnvironmentObject var lbManager: LeaderboardsManager
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var motionManager: MotionManager

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    let sortedLeaderboard = sortLeaderboard(for: lbManager.leaderboard)
                    leaderboardPodium(data: sortedLeaderboard)
                    VStack(spacing: 15) {
                        ForEach(sortedLeaderboard.indices, id: \.value) { i in
                            if i > 2 {
                                houseRow(
                                    placing: House.getPlacingFrom(int: i+1),
                                    height: 60,
                                    house: sortedLeaderboard[i]
                                )
                            }
                        }
                    }
                }
                .padding(AppState.padding)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .refreshable {
            Task {
                await lbManager.retrieveLeaderboard()
            }
        }
        .onAppear {
            Task {
                await lbManager.retrieveLeaderboard()
                try await adminManager.checkIfUnderMaintenance()
                try await adminManager.checkIfAppForcesUpdates()
            }
        }
    }

    private func sortLeaderboard(for leaderboard: [House]) -> [House] {
        return leaderboard.sorted { $0.points > $1.points }.sorted { first, second in
            if first.points == second.points {
                first.name < second.name
            } else {
                first.name == second.name
            }
        }
    }

    @ViewBuilder
    func leaderboardPodium(data: [House]) -> some View {
        let barWidth = UIScreen.main.bounds.width/4
        VStack {
            HStack(alignment: .bottom) {
                if data.count >= 3 {
                    leaderboardRectanglePodium(house: data[2])
                        .frame(width: barWidth, height: 310)
                }

                if data.count >= 1 {
                    VStack {
                        Image(systemName: "trophy.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: barWidth*0.8, height: barWidth*0.8)
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow, radius: barWidth)

                        leaderboardRectanglePodium(house: data[0])
                            .frame(width: barWidth, height: 350)
                    }
                }

                if data.count >= 2 {
                    leaderboardRectanglePodium(house: data[1])
                        .frame(width: barWidth, height: 330)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
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
        .padding(.horizontal)
    }

    @ViewBuilder
    func leaderboardRectanglePodium(house: House) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .foregroundStyle(house.color)
                .overlay(alignment: .top) {
                    VStack(spacing: 10) {
                        AsyncImage(url: house.icon)
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.85, height: geometry.size.width * 0.85)
                            .mask(Circle())
                            .specularHighlight(for: .circle, motionManager: motionManager)

                        Text("\(house.points)")
                            .foregroundStyle(.white)
                            .font(.system(size: geometry.size.width * 0.2).weight(.black).italic())
                    }
                    .padding(.top, geometry.size.width * 0.25)
                }
        }
    }

    @ViewBuilder
    func houseRow(placing: String, height: CGFloat, house: House) -> some View {
        Capsule()
            .frame(height: height)
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
                                    .init(color: house.color, location: 0.7),
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
                                            .init(color: house.color, location: 0.7),
                                            .init(color: Color.lbHouseColorToFadeTo, location: 1.2)
                                        ],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                        }
                        .overlay {
                            HStack {
                                AsyncImage(url: house.icon)
                                    .scaledToFit()
                                    .frame(width: height-6, height: height-6)
                                    .mask(Circle())
                                Spacer()
                                Text("\(house.points) POINTS")
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
