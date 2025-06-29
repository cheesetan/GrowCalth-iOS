//
//  HomeView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKitUI

struct HomeView: View {

    let halfUIWidth = (UIScreen.main.bounds.width / 2) - 20
    
    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var quotesManager: QuotesManager
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                HStack(alignment: .top, spacing: 15) {
                    VStack(spacing: 15) {
                        steps
                        distance
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 15) {
                        if #available(iOS 18.0, *) {
                            NavigationLink {
                                LeaderboardView()
                                    .navigationTransition(.zoom(sourceID: "leaderboard", in: namespace))
                            } label: {
                                leaderboards
                                    .matchedTransitionSource(id: "leaderboard", in: namespace)
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                        } else {
                            NavigationLink {
                                LeaderboardView()
                            } label: {
                                leaderboards
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                        }

                        housePointsProgress
                    }
                    .frame(maxWidth: .infinity)
                }

                VStack(spacing: 15) {
                    if #available(iOS 18.0, *) {
                        NavigationLink {
                            QuoteView()
                                .navigationTransition(.zoom(sourceID: "quote", in: namespace))
                        } label: {
                            quotes
                                .matchedTransitionSource(id: "quote", in: namespace)
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                    } else {
                        NavigationLink {
                            QuoteView()
                        } label: {
                            quotes
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                    }

                    if #available(iOS 18.0, *) {
                        NavigationLink {
                            GoalsView()
                                .navigationTransition(.zoom(sourceID: "goals", in: namespace))
                        } label: {
                            goals
                                .matchedTransitionSource(id: "goals", in: namespace)
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                    } else {
                        NavigationLink {
                            GoalsView()
                        } label: {
                            goals
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        .navigationTitle("Home")
        .refreshable {
            Task {
                await hkManager.fetchAllDatas()
                try await quotesManager.generateNewQuote()
            }
        }
        .onAppear {
            Task {
                await hkManager.fetchAllDatas()
                try await quotesManager.generateNewQuote()
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

    var steps: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 30)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
            .overlay {
                circularBackground(frame1: halfUIWidth - 55, frame2: halfUIWidth - 70)
                    .overlay {
                        VStack {
                            Text("\(hkManager.steps ?? 0)")
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .font(.system(size: 28.0))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)
                            Text("steps")
                                .foregroundColor(.gray)
                                .font(.system(size: 15.0))
                        }
                        .padding()
                    }
            }
            .overlay {
                rectangleHeader(text: "Steps")
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
    }
    
    var leaderboards: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth - 15)
            .foregroundColor(.black)
            .overlay {
                Image("Leaderboard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: halfUIWidth / 1.75)
                    .offset(y: 10)
            }
            .overlay {
                rectangleHeader(text: "Leaderboards")
                    .foregroundColor(.white)
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
            .accessibilityLabel("Leaderboard")
    }
    
    var distance: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
            .overlay {
                circularBackground(frame1: halfUIWidth - 65, frame2: halfUIWidth - 80)
                    .overlay {
                        VStack {
                            Text("\(hkManager.distance ?? 0.00, specifier: "%.2f")")
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .font(.system(size: 28.0))
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)
                            Text("km")
                                .foregroundColor(.gray)
                                .font(.system(size: 15.0))
                        }
                        .padding()
                    }
            }
            .overlay {
                rectangleHeader(text: "Distance")
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
    }
    
    var housePointsProgress: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 45)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 0)
            .overlay {
                let housePointsEarnedToday = Int(floor(Double((hkManager.steps ?? 0) / GLOBAL_STEPS_PER_POINT)))
                VStack {
                    Spacer()
                    Text(authManager.accountType.canAddPoints ? "\(housePointsEarnedToday)" : "-" )
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    VStack {
                        if authManager.accountType.canAddPoints && housePointsEarnedToday == 1 {
                            Text("GrowCalth point earned today")
                        } else {
                            Text("GrowCalth points earned today")
                        }
                    }
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.1)
                    .lineLimit(2)
                    Spacer()
                    if authManager.accountType.canAddPoints {
                        Text("\(GLOBAL_STEPS_PER_POINT - ((hkManager.steps ?? 0) - (housePointsEarnedToday * GLOBAL_STEPS_PER_POINT))) more steps to another point!")
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                }
                .padding()
            }
            .overlay {
                rectangleHeader(text: "Progress")
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
    }
    
    var quotes: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .foregroundColor(Color(hex: 0xC2CFDE))
            .overlay {
                VStack {
                    HStack {
                        if let content = quotesManager.quote?.text {
                            Text(content)
                                .foregroundColor(.black)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    Spacer()
                    if let author = quotesManager.quote?.author {
                        HStack {
                            Spacer()
                            Text(author)
                                .foregroundColor(.black)
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
            .accessibilityLabel("Quotes")
    }
    
    var stepsGoalFloat: Binding<Double> {
        if let stepsGoal = goalsManager.stepsGoal, let steps = hkManager.steps {
            return .constant(Double(steps) / Double(stepsGoal))
        } else {
            return .constant(0)
        }
    }
    
    var distanceGoalFloat: Binding<Double> {
        if let distanceGoal = goalsManager.distanceGoal, let distance = hkManager.distance {
            return .constant(Double(distance) / Double(distanceGoal))
        } else {
            return .constant(0)
        }
    }
    
    var goals: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(maxWidth: .infinity)
            .frame(height: halfUIWidth - 30)
            .foregroundColor(Color(hex: 0x7B5B66))
            .overlay {
                VStack(spacing: 10) {
                    ProgressBar(text: "Steps", color: .red, height: 35, value: stepsGoalFloat)
                    ProgressBar(text: "Distance", color: .green, height: 35, value: distanceGoalFloat)
                }
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .padding([.horizontal, .top])
            }
            .overlay {
                rectangleHeader(text: "Goals", font: .large)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white, lineWidth: 2)
                }
            }
            .accessibilityLabel("Goals")
    }
    
    @ViewBuilder
    func circularBackground(frame1: CGFloat, frame2: CGFloat) -> some View {
        ZStack {
            Circle()
                .foregroundColor(colorScheme == .light ? .black : .secondary)
                .frame(width: frame1, height: frame1)
            Circle()
                .foregroundColor(Color(hex: 0xF1EEE9))
                .frame(width: frame2, height: frame2)
        }
    }
    
    enum FontSize {
        case small, large
    }
    
    @ViewBuilder
    func rectangleHeader(text: String, font: FontSize = .small) -> some View {
        VStack {
            HStack {
                Text(text)
                    .minimumScaleFactor(0.1)
                    .font(.system(size: font == .small ? 15.0 : 20.0).weight(.bold))
                    .lineLimit(1)
                Spacer()
            }
            Spacer()
        }
        .padding([.top, .leading])
    }
}

#Preview {
    HomeView()
}
