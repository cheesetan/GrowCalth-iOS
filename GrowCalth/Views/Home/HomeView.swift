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

    @State private var showingAlumnusAppreciationAlert = false

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
            VStack(spacing: 30) {
                housePointsProgress
                stepsAndDistance
                leaderboardPreview
                goals
            }
            .padding(30)
        }
        .navigationTitle("Home")
        .refreshable {
            Task {
                await hkManager.fetchAllDatas()
            }
        }
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
//                    if authManager.accountType.canAddPoints {
                        Text("You have earned ")
                        Text("^[\(housePointsEarnedToday) points](inflect: true)")
                            .fontWeight(.bold)
                            .foregroundStyle(.accent)
                        Text(" today.")
//                    } else {
//                        Text("You are unable to earn GrowCalth points.")
//                    }
                }
            }
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.offBackground)
        .mask(Capsule())
        .shadow(color: Color(hex: 0x2B2B2E).opacity(0.2), radius: 35, x: 0, y: 5)
        .overlay {
            Capsule()
                .stroke(.white, lineWidth: 2)
        }
    }

    var stepsAndDistance: some View {
        Text("AathiRobo8")
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

    var leaderboardPreview: some View {
        NavigationLink {
            LeaderboardView()
        } label: {
            VStack {
                Capsule()
                    .frame(height: 64)
                    .foregroundStyle(Color(hex: 0xD4D4D9))
                    .overlay {
                        HStack(spacing: 20) {
                            Capsule()
                                .frame(width: 86)
                                .foregroundStyle(.white.opacity(0.8))
                                .overlay {
                                    Text("1ST")
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
                                .foregroundStyle(.yellow.opacity(0.8))
                                .overlay {
                                    Text("2400 POINTS")
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
                Capsule()
                    .frame(height: 48)
                    .foregroundStyle(Color(hex: 0xD4D4D9))
                    .overlay {
                        HStack(spacing: 20) {
                            Capsule()
                                .frame(width: 86)
                                .foregroundStyle(.white.opacity(0.8))
                                .overlay {
                                    Text("2ND")
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
                                .foregroundStyle(.blue.opacity(0.8))
                                .overlay {
                                    Text("1600 POINTS")
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
                Capsule()
                    .frame(height: 48)
                    .foregroundStyle(Color(hex: 0xD4D4D9))
                    .overlay {
                        HStack(spacing: 20) {
                            Capsule()
                                .frame(width: 86)
                                .foregroundStyle(.white.opacity(0.8))
                                .overlay {
                                    Text("3RD")
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
                                .foregroundStyle(.green.opacity(0.8))
                                .overlay {
                                    Text("800 POINTS")
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
                HStack {
                    Spacer()
                    Text("view more >")
                        .font(.footnote)
                }
                .padding(.horizontal, 5)
            }
        }
        .buttonStyle(.plain)
    }
    
    var goals: some View {
        Group {
            if #available(iOS 18.0, *) {
                NavigationLink {
                    GoalsView()
                        .navigationTransition(.zoom(sourceID: "goals", in: namespace))
                } label: {
                    HStack {
                        Spacer()
                        Text("What's your next goal?")
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0xBF7069).opacity(0.8))
                    .mask(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white, lineWidth: 2)
                            .padding(1)
                    }
                    .matchedTransitionSource(id: "goals", in: namespace)
                }
                .buttonStyle(.plain)
                .shadow(color: Color(hex: 0x2B2B2E).opacity(0.2), radius: 35, x: 0, y: 5)
            } else {
                NavigationLink {
                    GoalsView()
                } label: {
                    HStack {
                        Spacer()
                        Text("What's your next goal?")
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0xBF7069).opacity(0.8))
                    .mask(Capsule())
                    .shadow(color: Color(hex: 0x2B2B2E).opacity(0.2), radius: 35, x: 0, y: 5)
                    .overlay {
                        Capsule()
                            .stroke(.white, lineWidth: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SemiCircularProgressBar<Content: View>: View {
    @State var progress: Double

    @ViewBuilder let insetContent: Content
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
                    .stroke(style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                    .border(.red)


                Arc(startAngle: .degrees(0), endAngle: .degrees(150), clockwise: true)
                    .stroke(style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round))
                    .fill(.accent)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)

        return path
    }
}

#Preview {
    HomeView()
}
