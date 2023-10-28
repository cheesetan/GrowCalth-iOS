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
    
    var body: some View {
        NavigationStack {
            ScrollView {
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
                            
                            daysinappprogress
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
                        goals
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
                quotesManager.generateNewQuote()
            }
        }
        .onAppear {
            hkManager.fetchAllDatas()
            daysManager.refreshNumberOfDaysInApp()
            quotesManager.generateNewQuote()
        }
    }
    
    var steps: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 30)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                ZStack {
                    circularBackground(frame1: halfUIWidth - 55, frame2: halfUIWidth - 70)
                    VStack {
                        Text("\(hkManager.steps ?? 0)")
                            .fontWeight(.black)
                            .font(.title)
                        Text("steps")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }
            }
            .overlay {
                rectangleHeader(text: "Steps")
            }
    }
    
    var leaderboards: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth - 15)
            .foregroundColor(.black)
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                Image("leaderboard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: halfUIWidth / 1.75)
                    .offset(y: 10)
            }
            .overlay {
                rectangleHeader(text: "Leaderboards")
                    .foregroundColor(.white)
            }
    }
    
    var distance: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                ZStack {
                    circularBackground(frame1: halfUIWidth - 65, frame2: halfUIWidth - 80)
                    VStack {
                        Text("\(hkManager.distance ?? 0.00, specifier: "%.2f")")
                            .fontWeight(.black)
                            .font(.title)
                        Text("km")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }
            }
            .overlay {
                rectangleHeader(text: "Distance")
            }
    }
    
    var daysinappprogress: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(width: halfUIWidth, height: halfUIWidth + 45)
            .foregroundColor(.white)
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
                            } else {
                                Text("days in this app")
                            }
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                    } else {
                        ProgressView()
                    }
                }
            }
            .overlay {
                rectangleHeader(text: "Progress")
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
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
            }
    }
    
    var goals: some View {
        RoundedRectangle(cornerRadius: 16)
            .frame(maxWidth: .infinity)
            .frame(height: halfUIWidth - 30)
            .foregroundColor(Color(hex: 0x7B5B66))
            .shadow(color: .black, radius: 4, x: -1, y: 5)
            .overlay {
                rectangleHeader(text: "Set your Goals", font: .title3)
                    .font(.title)
                    .foregroundColor(.white)
            }
    }
    @ViewBuilder
    func circularBackground(frame1: CGFloat, frame2: CGFloat) -> some View {
        ZStack {
            Circle()
                .foregroundColor(.black)
                .frame(width: frame1, height: frame1)
            Circle()
                .foregroundColor(Color(hex: 0xF1EEE9))
                .frame(width: frame2, height: frame2)
        }
    }
    
    @ViewBuilder
    func rectangleHeader(text: String, font: Font = Font.subheadline) -> some View {
        VStack {
            HStack {
                Text(text)
                    .font(font)
                    .fontWeight(.bold)
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
