//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

enum AppStatus: Sendable {
    case home, login, onboarding, noNetwork, updateAvailable, underMaintenance, loading(String)
}

@MainActor
class AppState: ObservableObject {

    @AppStorage("onboardingView", store: .standard) var onboardingView = true

    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var adminManager: AdminManager
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var developerManager: DeveloperManager
    @ObservedObject var networkManager: NetworkManager

    init(
        onboardingView: Bool = true,
        authManager: AuthenticationManager,
        adminManager: AdminManager,
        updateManager: UpdateManager,
        developerManager: DeveloperManager,
        networkManager: NetworkManager
    ) {
        self.onboardingView = onboardingView
        self.authManager = authManager
        self.adminManager = adminManager
        self.updateManager = updateManager
        self.developerManager = developerManager
        self.networkManager = networkManager
    }

    var status: AppStatus {
        if let isConnectionAvailable = networkManager.isConnectionAvailable {
            if isConnectionAvailable {
                if let isUnderMaintenance = adminManager.isUnderMaintenance,
                   let updateAvailable = updateManager.updateAvailable,
                   let appForcesUpdates = adminManager.appForcesUpdates {

                    if updateAvailable && appForcesUpdates && !developerManager.bypassed {
                        return .updateAvailable
                    } else {
                        if isUnderMaintenance && !developerManager.bypassed {
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

    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var hkManager: HealthKitManager
    @ObservedObject var apnsManager: ApplicationPushNotificationsManager
    @ObservedObject var goalsManager: GoalsManager
    @ObservedObject var lbManager: LeaderboardsManager
    @ObservedObject var napfaManager: NAPFAManager
    @ObservedObject var quotesManager: QuotesManager
    @ObservedObject var announcementManager: AnnouncementManager
    @ObservedObject var csManager: ColorSchemeManager

    @ObservedObject var pointsManager: PointsManager
    @ObservedObject var developerManager: DeveloperManager
    @ObservedObject var adminManager: AdminManager
    @ObservedObject var appState: AppState

    init(
        authManager: AuthenticationManager = .init(),
        updateManager: UpdateManager = .init(),
        networkManager: NetworkManager = .init(),
        hkManager: HealthKitManager = .init(),
        apnsManager: ApplicationPushNotificationsManager = .init(),
        goalsManager: GoalsManager = .init(),
        lbManager: LeaderboardsManager = .init(),
        napfaManager: NAPFAManager = .init(),
        quotesManager: QuotesManager = .init(),
        announcementManager: AnnouncementManager = .init(),
        csManager: ColorSchemeManager = .init()
    ) {
        self.authManager = authManager
        self.updateManager = updateManager
        self.networkManager = networkManager
        self.hkManager = hkManager
        self.apnsManager = apnsManager
        self.goalsManager = goalsManager
        self.lbManager = lbManager
        self.napfaManager = napfaManager
        self.quotesManager = quotesManager
        self.announcementManager = announcementManager
        self.csManager = csManager

        let adminManager = AdminManager(authManager: authManager)
        self.adminManager = adminManager

        let developerManager = DeveloperManager(adminManager: adminManager)
        self.developerManager = developerManager

        self.appState = AppState(
            authManager: authManager,
            adminManager: adminManager,
            updateManager: updateManager,
            developerManager: developerManager,
            networkManager: networkManager
        )
        self.pointsManager = PointsManager(
            adminManager: adminManager,
            hkManager: hkManager,
            authManager: authManager
        )

        // Initialize points manager date logic
        self.initializePointsManagerDate()
    }

    private func initializePointsManagerDate() {
        if let lastPointsAwardedDate = pointsManager.lastPointsAwardedDate {
            if lastPointsAwardedDate < GLOBAL_GROWCALTH_START_DATE {
                pointsManager.lastPointsAwardedDate = GLOBAL_GROWCALTH_START_DATE
            }
        } else {
            let cal = Calendar(identifier: .gregorian)
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
                if #available(iOS 18.0, *) {
                    TabView {
                        Tab("Home", systemImage: "house.fill") {
                            HomeView()
                        }
                        Tab("Announcements", systemImage: "megaphone") {
                            AnnouncementsView()
                        }
                        Tab("NAPFA", systemImage: "figure.run") {
                            NAPFAView()
                        }
                        Tab("Settings", systemImage: "gearshape") {
                            SettingsView()
                        }
                    }
                } else {
                    TabView {
                        HomeView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                        AnnouncementsView()
                            .tabItem {
                                Label("Announcements", systemImage: "megaphone")
                            }
                        NAPFAView()
                            .tabItem {
                                Label("NAPFA", systemImage: "figure.run")
                            }
                        SettingsView()
                            .tabItem {
                                Label("Settings", systemImage: "gearshape")
                            }
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
        .environmentObject(authManager)
        .environmentObject(updateManager)
        .environmentObject(networkManager)
        .environmentObject(hkManager)
        .environmentObject(apnsManager)
        .environmentObject(goalsManager)
        .environmentObject(lbManager)
        .environmentObject(napfaManager)
        .environmentObject(quotesManager)
        .environmentObject(announcementManager)
        .environmentObject(csManager)
        .environmentObject(pointsManager)
        .environmentObject(developerManager)
        .environmentObject(adminManager)
        .environmentObject(appState)
        .preferredColorScheme(
            csManager.colorScheme == .automatic ? .none :
                csManager.colorScheme == .dark ? .dark : .light
        )
    }
}

#Preview {
    ContentView()
}
