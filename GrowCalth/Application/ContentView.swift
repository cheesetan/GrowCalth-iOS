//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct ContentView: View {
    
    @AppStorage("onboardingView", store: .standard) var onboardingView = true
    @ObservedObject var authManager: AuthenticationManager = .shared

    var body: some View {
        if !onboardingView {
            if authManager.isLoggedIn && authManager.accountVerified {
                TabView {
                    Home()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    Announcements()
                        .tabItem {
                            Label("Announcements", systemImage: "megaphone")
                        }
                    NAPFA()
                        .tabItem {
                            Label("NAPFA", systemImage: "figure.run")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                AuthenticationView()
            }
        } else {
            OnboardingView(onboardingView: $onboardingView)
        }
    }
}

#Preview {
    ContentView()
}
