//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct ContentView: View {
    
    @State var isLoading = false
    
    @AppStorage("onboardingView", store: .standard) var onboardingView = true
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var updateManager: UpdateManager = .shared
    @ObservedObject var developerManager: DeveloperManager = .shared
    @ObservedObject var networkManager: NetworkManager = .shared
    
    var body: some View {
        if networkManager.isConnectionAvailable != nil {
            if networkManager.isConnectionAvailable == true {
                if adminManager.isUnderMaintenance != nil && updateManager.updateAvailable != nil && adminManager.appForcesUpdates != nil {
                    if updateManager.updateAvailable == true && adminManager.appForcesUpdates == true && adminManager.bypassed == false {
                        CustomContentUnavailableView(
                            title: "New Update Available",
                            systemImage: "app.dashed",
                            description: "There's a new update available on the App Store! Install the latest update to continue using GrowCalth.",
                            mode: .update
                        )
                    } else {
                        if adminManager.isUnderMaintenance == true && adminManager.bypassed == false {
                            CustomContentUnavailableView(
                                title: "Under Maintenance",
                                systemImage: "hammer.fill",
                                description: "GrowCalth is currently undergoing maintenance, please check back again later.",
                                mode: .maintenance
                            )
                        } else {
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
                } else {
                    ProgressView {
                        if updateManager.updateAvailable == nil {
                            Text("Checking For Updates...")
                        } else {
                            Text("Checking System Health...")
                        }
                    }
                    .controlSize(.large)
                }
            } else {
                CustomContentUnavailableView(
                    title: "No Network Connection",
                    systemImage: "pc",
                    description: "You seem to be offline! GrowCalth requires a network connection to work. If available, turn on your Mobile Data or WiFi and connect to a network.",
                    mode: .network
                )
            }
        } else {
            ProgressView {
                Text("Checking Internet Connection...")
            }
            .controlSize(.large)
        }
    }
}

#Preview {
    ContentView()
}
