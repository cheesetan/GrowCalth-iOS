//
//  HomeView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKitUI

struct HomeView: View {

    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var pointsManager: PointsManager
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var lbManager: LeaderboardsManager

    @State private var showingAlumnusAppreciationAlert = false
    @State private var showingGoalsSetting = false

    @Environment(\.colorScheme) var colorScheme

    @Namespace private var namespace

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                main
            }
        } else {
            NavigationView {
                main
            }
            .navigationViewStyle(.stack)
        }
    }

    var main: some View {
        ZStack {
            Color.offBackground.ignoresSafeArea()
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.15 / 3) {
                    housePointsProgress
                        .frame(height: geometry.size.height * 0.07)

                    HStack {
                        steps
                        distance
                    }
                    .frame(height: geometry.size.height * 0.35)

                    leaderboardPreview
                        .frame(height: geometry.size.height * 0.35)

                    goals
                        .frame(height: geometry.size.height * 0.08)
                }
                .frame(maxHeight: geometry.size.height)
            }
            .padding()
        }
        .navigationTitle("Home")
        .onAppear {
            Task {
                await hkManager.fetchAllDatas()
                try await adminManager.checkIfUnderMaintenance()
                try await adminManager.checkIfAppForcesUpdates()
                try await pointsManager.checkAndAddPoints()
            }

            if authManager.accountType == .alumnus {
                self.showingAlumnusAppreciationAlert = true
            }
        }
        .alert("Thank you.", isPresented: $showingAlumnusAppreciationAlert) {

        } message: {
            Text("As an alumnus, you're able to view the contents of the app, but are unable to contribute to the leaderboard. We really appreciate your previous support as a student!")
        }
    }

    var housePointsProgress: some View {
        VStack {
            let housePointsEarnedToday = Int(floor(Double((hkManager.steps ?? 0) / GLOBAL_STEPS_PER_POINT)))
            HStack {
                HStack(spacing: 0) {
                    if authManager.accountType.canAddPoints {
                        Text("You have earned ")
                        Text("^[\(housePointsEarnedToday) points](inflect: true)")
                            .fontWeight(.bold)
                            .foregroundStyle(.accent)
                        Text(" today.")
                    } else {
                        Text("You are unable to earn GrowCalth points.")
                    }
                }
            }
            .font(.title3.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.1)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.offBackground)
        .mask(Capsule())
        .shadow(color: Color(hex: 0x2B2B2E).opacity(0.2), radius: 35, x: 0, y: 5)
        .overlay {
            Capsule()
                .stroke(.white, lineWidth: 2)
        }
    }

    var steps: some View {
        VStack {
            Text("Steps AathiRobo8")
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            .shadow(.inner(color: Color(red: 197/255, green: 197/255, blue: 197/255).opacity(0.5),radius: 3, x:3, y: 3))
                            .shadow(.inner(color: .white.opacity(0.5), radius: 3, x: -3, y: -3))
                        )
                        .foregroundStyle(.offBackground)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0), .white.opacity(0.8)], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 2)
                }
        }
    }

    var distance: some View {
        VStack {
            Text("Distance AathiRobo8")
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            .shadow(.inner(color: Color(red: 197/255, green: 197/255, blue: 197/255).opacity(0.5),radius: 3, x:3, y: 3))
                            .shadow(.inner(color: .white.opacity(0.5), radius: 3, x: -3, y: -3))
                        )
                        .foregroundStyle(.offBackground)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0), .white.opacity(0.8)], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 2)
                }
        }
    }

    var leaderboardPreview: some View {
        NavigationLink {
            LeaderboardView()
        } label: {
            GeometryReader { geometry in
                VStack(spacing: 5) {
                    VStack(spacing: 15) {
                        let tallHeight: Double = abs(Double((geometry.size.height - 50) / 7 * 3))
                        let normalHeight: Double = abs(Double((geometry.size.height - 50) / 7 * 2))
                        let data = sortDictionary(for: lbManager.leaderboard)

                        ForEach(data.prefix(3), id: \.key) { house in
                            let placing: Int = data.firstIndex(where: { $0.key == house.key }) ?? -1
                            if let houses = Houses.init(rawValue: house.key) {
                                leaderboardPreviewRow(
                                    placing: Houses.getPlacingFrom(int: placing + 1),
                                    house: houses,
                                    points: house.value,
                                    height: placing == 0 ? tallHeight : normalHeight,
                                    placingBubbleWidth: tallHeight
                                )
                            }
                        }
                    }
                    HStack {
                        Spacer()
                        Text("view more >")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 5)
                    .frame(height: 15)
                }
            }
        }
        .buttonStyle(.plain)
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
    func leaderboardPreviewRow(
        placing: String,
        house: Houses,
        points: Int,
        height: CGFloat,
        placingBubbleWidth: CGFloat
    ) -> some View {
        Capsule()
            .frame(maxHeight: height)
            .foregroundStyle(Color(hex: 0xD4D4D9))
            .overlay {
                HStack(spacing: 30) {
                    Capsule()
                        .frame(width: placingBubbleWidth*1.2)
                        .foregroundStyle(.white.opacity(0.8))
                        .overlay {
                            Text(placing)
                                .font(.title2.weight(.black).italic())
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                        }
                        .overlay {
                            Capsule()
                                .stroke(.white, lineWidth: 2)
                        }
                    Capsule()
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(house.color.opacity(0.8))
                        .overlay {
                            Text("\(points) POINTS")
                                .font(.title3.weight(.black).italic())
                                .lineLimit(1)
                                .minimumScaleFactor(0.1)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        .overlay {
                            Capsule()
                                .stroke(LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0), .white.opacity(0.8)], startPoint: .bottomLeading, endPoint: .topTrailing), lineWidth: 2)
                        }
                }
            }
    }

    var goals: some View {
        Button {
            showingGoalsSetting.toggle()
        } label: {
            goalsButtonLabel
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingGoalsSetting) {
            GoalsView()
                .presentationDetents([.height(300)])
        }
    }

    var goalsButtonLabel: some View {
        HStack {
            Text("What's your next goal?")
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
            Spacer()
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
        }
        .foregroundStyle(.white)
        .lineLimit(1)
        .padding(.horizontal, 30)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xBF7069).opacity(0.8))
        .mask(Capsule())
        .shadow(color: Color(hex: 0x2B2B2E).opacity(0.2), radius: 35, x: 0, y: 5)
        .overlay {
            Capsule()
                .stroke(.white, lineWidth: 2)
        }
    }
}

#Preview {
    HomeView()
}
