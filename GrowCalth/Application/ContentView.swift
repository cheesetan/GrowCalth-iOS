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

    var body: some View {
        if !onboardingView {
            if authManager.isLoggedIn && authManager.accountVerified {
                if adminManager.isUnderMaintenance != nil {
                    if adminManager.isUnderMaintenance == false {
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
                        maintenanceView
                    }
                } else {
                    ProgressView()
                }
            } else {
                AuthenticationView()
            }
        } else {
            OnboardingView(onboardingView: $onboardingView)
        }
    }
    
    var maintenanceView: some View {
        VStack {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label("Under Maintenance", systemImage: "hammer.fill")
                } description: {
                    Text("GrowCalth is currently undergoing maintenance, please check back again later.")
                } actions: {
                    Button {
                        isLoading = true
                        adminManager.checkIfUnderMaintenance() {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Check Status", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 15) {
                    Spacer()
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("GrowCalth is currently undergoing maintenance, please check back again later.")
                        .multilineTextAlignment(.center)
                    Button {
                        isLoading = true
                        adminManager.checkIfUnderMaintenance() {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Check Status", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
