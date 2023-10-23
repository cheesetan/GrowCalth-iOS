//
//  Home.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKitUI

struct Home: View {
    
    let halfUIWidth = (UIScreen.main.bounds.width / 2) - 20
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    
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
                            leaderboards
                            daysinappprogress
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    VStack(spacing: 15) {
                        quotes
                        goals
                    }
                    .padding(.top, 7.5)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("Home")
        }
        .onAppear {
            hkManager.readSteps()
            hkManager.readDistance()
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
                        if let steps = hkManager.steps {
                            Text("\(steps)")
                                .fontWeight(.black)
                                .font(.title)
                        } else {
                            Text("0")
                                .fontWeight(.black)
                                .font(.title)
                        }
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
                        if let distance = hkManager.distance {
                            Text("\(distance, specifier: "%.2f")")
                                .fontWeight(.black)
                                .font(.title)
                        } else {
                            Text("0.00")
                                .fontWeight(.black)
                                .font(.title)
                        }
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
                    Text("0")
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    Text("days in this app")
                        .font(.title3)
                        .fontWeight(.medium)
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
    func rectangleHeader(text: String, font: Font = Font.headline) -> some View {
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
