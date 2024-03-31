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

    var body: some View {
        if !onboardingView {
            if authManager.isLoggedIn && authManager.accountVerified {
                if adminManager.isUnderMaintenance != nil && updateManager.updateAvailable != nil && adminManager.appForcesUpdates != nil {
                    if updateManager.updateAvailable == true && adminManager.appForcesUpdates == true && adminManager.bypassed == false {
                        unavailableView(title: "New Update Available", systemImage: "app.dashed", description: "There's a new update available on the App Store! Install the latest update to continue using GrowCalth.")
                    } else {
                        if adminManager.isUnderMaintenance == true && adminManager.bypassed == false {
                            unavailableView(title: "Under Maintenance", systemImage: "hammer.fill", description: "GrowCalth is currently undergoing maintenance, please check back again later.", isMaintenance: true)
                        } else {
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
                        }
                    }
                } else {
                    ProgressView()
                        .controlSize(.large)
                }
            } else {
                AuthenticationView()
            }
        } else {
            OnboardingView(onboardingView: $onboardingView)
        }
    }
    
    @ViewBuilder
    func unavailableView(title: String, systemImage: String, description: String, isMaintenance: Bool = false) -> some View {
        VStack {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label(title, systemImage: systemImage)
                } description: {
                    Text(description)
                } actions: {
                    if isMaintenance {
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
                        
                        if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                            Button {
                                developerManager.changeAppIsUnderMaintenanceValue(to: false) { _ in }
                                adminManager.checkIfUnderMaintenance { }
                            } label: {
                                Text("Turn Off Maintenance Mode FOR EVERYONE")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                            Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                        Button {
                            adminManager.developerBypass()
                        } label: {
                            Text("Temporarily Bypass Restrictions (Developer ONLY)")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Spacer()
                    Image(systemName: systemImage)
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text(description)
                        .multilineTextAlignment(.center)
                    if isMaintenance {
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
                    } else {
                        Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                            Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
