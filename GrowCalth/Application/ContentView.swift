//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var authManager: AuthenticationManager = .shared

    var body: some View {
        if authManager.isLoggedIn {
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
    }
}

#Preview {
    ContentView()
}
