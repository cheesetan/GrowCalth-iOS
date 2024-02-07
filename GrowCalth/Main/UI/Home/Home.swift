//
//  Home.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKitUI

struct Home: View {
    
    let halfUIWidth = (UIScreen.main.bounds.width / 2) - 20
    
    @ObservedObject var daysManager: DaysManager = .shared
    @ObservedObject var hkManager: HealthKitManager = .shared
    @ObservedObject var quotesManager: QuotesManager = .shared
    @ObservedObject var goalsManager: GoalsManager = .shared
    @ObservedObject var pointsManager: PointsManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    HStack(alignment: .top, spacing: 15) {
                        VStack(spacing: 15) {
                            steps
                            distance
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 15) {
                            NavigationLink {
                                LeaderboardView()
                            } label: {
                                leaderboards
                            }
                            .buttonStyle(.plain)
                            
                            housePointsProgress
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    VStack(spacing: 15) {
                        NavigationLink {
                            QuoteView()
                        } label: {
                            quotes
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            GoalsView()
                        } label: {
                            goals
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 7.5)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("Home")
            .refreshable {
                hkManager.fetchAllDatas()
                daysManager.refreshNumberOfDaysInApp()
                quotesManager.generateNewQuote() { _ in }
            }
        }
        .onAppear {
            adminManager.checkIfUnderMaintenance() { }
            adminManager.checkIfAppForcesUpdates()
            hkManager.fetchAllDatas()
            daysManager.refreshNumberOfDaysInApp()
            quotesManager.generateNewQuote() { _ in }
            pointsManager.checkAndAddPoints()
        }
    }
    
    var steps: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 30)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                circularBackground(frame1: halfUIWidth - 55, frame2: halfUIWidth - 70)
                    .overlay {
                        VStack {
                            Text("\(hkManager.steps ?? 0)")
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .font(.system(size: 28.0))
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
            .shadow(color: .black, radius: 4, x: -1, y: 5)
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
    }
    
    var distance: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                circularBackground(frame1: halfUIWidth - 65, frame2: halfUIWidth - 80)
                    .overlay {
                        VStack {
                            Text("\(hkManager.distance ?? 0.00, specifier: "%.2f")")
                                .minimumScaleFactor(0.1)
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .font(.system(size: 28.0))
                            Text("km")
                                .minimumScaleFactor(0.1)
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
    
    var daysinappprogress: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 45)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                VStack {
                    if let daysInApp = daysManager.daysInApp {
                        Text("\(daysInApp)")
                            .font(.system(size: 50))
                            .fontWeight(.bold)
                        VStack {
                            if daysInApp == 1 {
                                Text("day in this app")
                                    .minimumScaleFactor(0.1)
                                    .lineLimit(1)
                            } else {
                                Text("days in this app")
                                    .minimumScaleFactor(0.1)
                                    .lineLimit(1)
                            }
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                    } else {
                        ProgressView()
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
    
    var housePointsProgress: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 45)
            .foregroundColor(Color(uiColor: .systemBackground))
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                let housePointsEarnedToday = Int(floor(Double((hkManager.steps ?? 0) / 1000)))
                VStack {
                    Spacer()
                    Text("\(housePointsEarnedToday)")
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    VStack {
                        if housePointsEarnedToday == 1 {
                            Text("house point earned today")
                        } else {
                            Text("house points earned today")
                        }
                    }
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.1)
                    .lineLimit(2)
                    Spacer()
                    Text("\(1000 - ((hkManager.steps ?? 0) - (housePointsEarnedToday * 1000))) more steps to another point!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
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
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                VStack {
                    HStack {
                        if let content = quotesManager.quote?.content {
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
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                VStack(spacing: 10) {
                    ProgressBar(text: "Steps", color: .red, height: 35, value: stepsGoalFloat)
                    ProgressBar(text: "Distance", color: .green, height: 35, value: distanceGoalFloat)
                }
                .font(.headline)
                .fontWeight(.semibold)
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
                    .font(.system(size: font == .small ? 15.0 : 20.0))
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
            }
            Spacer()
        }
        .padding([.top, .leading])
    }
}

#Preview {
    Home()
}
