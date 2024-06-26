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
                        unavailableView(title: "New Update Available", systemImage: "app.dashed", description: "There's a new update available on the App Store! Install the latest update to continue using GrowCalth.", mode: .update)
                    } else {
                        if adminManager.isUnderMaintenance == true && adminManager.bypassed == false {
                            unavailableView(title: "Under Maintenance", systemImage: "hammer.fill", description: "GrowCalth is currently undergoing maintenance, please check back again later.", mode: .maintenance)
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
                unavailableView(title: "No Network Connection", systemImage: "pc", description: "You seem to be offline! GrowCalth requires a Network connection to work. If available, turn on your Mobile Data or WiFi and connect to a Network.", mode: .network)
            }
        } else {
            ProgressView {
                Text("Checking Internet Connection...")
            }
            .controlSize(.large)
        }
    }
    
    enum UnavailableMode {
        case maintenance, update, network
    }
    
    @ViewBuilder
    func unavailableView(title: String, systemImage: String, description: String, mode: UnavailableMode) -> some View {
        VStack {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label(title, systemImage: systemImage)
                } description: {
                    Text(description)
                } actions: {
                    switch mode {
                    case .maintenance:
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
                    case .update:
                        Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                            Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                    case .network:
                        EmptyView()
                    }
                    
                    switch mode {
                    case .maintenance, .update:
                        if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                            Button {
                                adminManager.developerBypass()
                            } label: {
                                Text("Temporarily Bypass Restrictions (Developer ONLY)")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    case .network:
                        EmptyView()
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
                    switch mode {
                    case .maintenance:
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
                    case .update:
                        Link(destination: URL(string: "https://apps.apple.com/sg/app/growcalth/id6456388202")!) {
                            Label("Open App Store", systemImage: "arrow.up.forward.app.fill")
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                    case .network:
                        EmptyView()
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
