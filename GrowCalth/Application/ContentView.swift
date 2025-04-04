//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

enum AppStatus {
    case home, login, onboarding, noNetwork, updateAvailable, underMaintenance, loading(String)
}

class AppState: ObservableObject {
    static let shared: AppState = .init()

//    @Published var status: AppStatus = .loading("Loading...")

    @AppStorage("onboardingView", store: .standard) var onboardingView = true

    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var updateManager: UpdateManager = .shared
    @ObservedObject var developerManager: DeveloperManager = .shared
    @ObservedObject var networkManager: NetworkManager = .shared

    var status: AppStatus {
        if networkManager.isConnectionAvailable != nil {
            if networkManager.isConnectionAvailable == true {
                if adminManager.isUnderMaintenance != nil && updateManager.updateAvailable != nil && adminManager.appForcesUpdates != nil {
                    if updateManager.updateAvailable == true && adminManager.appForcesUpdates == true && developerManager.bypassed == false {
                        return .updateAvailable
                    } else {
                        if adminManager.isUnderMaintenance == true && developerManager.bypassed == false {
                            return .underMaintenance
                        } else {
                            if !onboardingView {
                                if authManager.isLoggedIn && authManager.accountVerified {
                                    return .home
                                } else {
                                    return .login
                                }
                            } else {
                                return .onboarding
                            }
                        }
                    }
                } else {
                    if updateManager.updateAvailable == nil {
                        return .loading("Checking For Updates...")
                    } else {
                        return .loading("Checking System Health...")
                    }
                }
            } else {
                return .noNetwork
            }
        } else {
            return .loading("Checking Internet Connection...")
        }
    }
}

struct ContentView: View {

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var updateManager: UpdateManager = .shared
    @ObservedObject var developerManager: DeveloperManager = .shared
    @ObservedObject var networkManager: NetworkManager = .shared
    @ObservedObject var pointsManager: PointsManager = .shared

    init() {
        if let lastPointsAwardedDate = pointsManager.lastPointsAwardedDate {
            if lastPointsAwardedDate < GLOBAL_GROWCALTH_START_DATE {
                pointsManager.lastPointsAwardedDate = GLOBAL_GROWCALTH_START_DATE
            }
        } else {
            let cal = Calendar(identifier: Calendar.Identifier.gregorian)
            let today = cal.startOfDay(for: Date())

            if today < GLOBAL_GROWCALTH_START_DATE {
                pointsManager.lastPointsAwardedDate = GLOBAL_GROWCALTH_START_DATE
            } else {
                pointsManager.lastPointsAwardedDate = today
            }
        }
    }

    var body: some View {
        Group {
            switch appState.status {
            case .home:
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
            case .login:
                AuthenticationView()
            case .onboarding:
                OnboardingView(onboardingView: $appState.onboardingView)
            case .noNetwork:
                CustomContentUnavailableView(
                    title: "No Network Connection",
                    systemImage: "pc",
                    description: "You seem to be offline! GrowCalth requires a network connection to work. If available, turn on your Mobile Data or WiFi and connect to a network.",
                    mode: .network
                )
            case .updateAvailable:
                CustomContentUnavailableView(
                    title: "New Update Available",
                    systemImage: "app.dashed",
                    description: "There's a new update available on the App Store! Install the latest update to continue using GrowCalth.",
                    mode: .update
                )
            case .underMaintenance:
                CustomContentUnavailableView(
                    title: "Under Maintenance",
                    systemImage: "hammer.fill",
                    description: "GrowCalth is currently undergoing maintenance, please check back again later.",
                    mode: .maintenance
                )
            case .loading(let string):
                ProgressView {
                    Text(string)
                }
                .controlSize(.large)
            }
        }
    }
}

#Preview {
    ContentView()
}
