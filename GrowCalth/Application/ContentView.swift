//
//  ContentView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

enum AppStatus: Sendable {
    case home, login, noNetwork, updateAvailable, underMaintenance, loading(String)
}

@MainActor
class AppState: ObservableObject {

    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var adminManager: AdminManager
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var developerManager: DeveloperManager
    @ObservedObject var networkManager: NetworkManager

    init(
        authManager: AuthenticationManager,
        adminManager: AdminManager,
        updateManager: UpdateManager,
        developerManager: DeveloperManager,
        networkManager: NetworkManager
    ) {
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
                        } else if authManager.isLoggedIn && authManager.accountVerified {
                            return .home
                        } else {
                            return .login
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

enum TabSelection {
    case home, announcements, napfa, settings
}


struct ContentView: View {

    @StateObject private var authManager: AuthenticationManager
    @StateObject private var updateManager: UpdateManager
    @StateObject private var networkManager: NetworkManager
    @StateObject private var hkManager: HealthKitManager
    @StateObject private var apnsManager: ApplicationPushNotificationsManager
    @StateObject private var goalsManager: GoalsManager
    @StateObject private var lbManager: LeaderboardsManager
    @StateObject private var napfaManager: NAPFAManager
    @StateObject private var quotesManager: QuotesManager
    @StateObject private var announcementManager: AnnouncementManager
    @StateObject private var settingsManager: SettingsManager
    @StateObject private var audioManager: AudioManager

    @StateObject private var adminManager: AdminManager
    @StateObject private var developerManager: DeveloperManager
    @StateObject private var appState: AppState
    @StateObject private var pointsManager: PointsManager
    @StateObject private var motionManager: MotionManager


    init() {
        let authManager = AuthenticationManager()
        _authManager = StateObject(wrappedValue: authManager)

        let updateManager = UpdateManager()
        _updateManager = StateObject(wrappedValue: updateManager)

        let networkManager = NetworkManager()
        _networkManager = StateObject(wrappedValue: networkManager)

        let hkManager = HealthKitManager()
        _hkManager = StateObject(wrappedValue: hkManager)

        let apnsManager = ApplicationPushNotificationsManager()
        _apnsManager = StateObject(wrappedValue: apnsManager)

        let goalsManager = GoalsManager()
        _goalsManager = StateObject(wrappedValue: goalsManager)

        let lbManager = LeaderboardsManager()
        _lbManager = StateObject(wrappedValue: lbManager)

        let napfaManager = NAPFAManager()
        _napfaManager = StateObject(wrappedValue: napfaManager)

        let quotesManager = QuotesManager()
        _quotesManager = StateObject(wrappedValue: quotesManager)

        let announcementManager = AnnouncementManager()
        _announcementManager = StateObject(wrappedValue: announcementManager)

        let settingsManager = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settingsManager)

        let audioManager = AudioManager()
        _audioManager = StateObject(wrappedValue: audioManager)

        let adminManager = AdminManager(authManager: authManager)
        _adminManager = StateObject(wrappedValue: adminManager)

        let developerManager = DeveloperManager(adminManager: adminManager)
        _developerManager = StateObject(wrappedValue: developerManager)

        let appState = AppState(
            authManager: authManager,
            adminManager: adminManager,
            updateManager: updateManager,
            developerManager: developerManager,
            networkManager: networkManager
        )
        _appState = StateObject(wrappedValue: appState)

        let pointsManager = PointsManager(
            adminManager: adminManager,
            hkManager: hkManager,
            authManager: authManager
        )
        _pointsManager = StateObject(wrappedValue: pointsManager)

        let motionManager = MotionManager(settingsManager: settingsManager)
        _motionManager = StateObject(wrappedValue: motionManager)
    }

    @State private var tabSelected: TabSelection = .home

    var body: some View {
        Group {
            switch appState.status {
            case .home:
                if #available(iOS 26.0, *) {
                    TabView(selection: $tabSelected) {
                        Tab("Home", systemImage: "house.fill", value: .home) {
                            HomeView()
                        }
                        Tab("Announcements", systemImage: "megaphone", value: .announcements) {
                            AnnouncementsView()
                        }
                        Tab("NAPFA", systemImage: "figure.run", value: .napfa) {
                            NAPFAView()
                        }
                        Tab("Settings", systemImage: "gearshape", value: .settings) {
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
                ZStack {
                    Color.background.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Divider().frame(width: 200)
                        VStack {
                            if let content = quotesManager.quote?.text {
                                Text(content)
                                    .font(.headline.italic())
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.1)
                            }
                            if let author = quotesManager.quote?.author, !author.isEmpty {
                                Text(author)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.1)
                            }
                        }
                        Divider()
                            .frame(width: 200)
                        Text(string)
                            .font(.subheadline.italic())
                            .lineLimit(1)
                            .minimumScaleFactor(0.1)
                            .padding(.horizontal)
                    }
                    .padding()
                }
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
        .environmentObject(announcementManager)
        .environmentObject(settingsManager)
        .environmentObject(audioManager)
        .environmentObject(pointsManager)
        .environmentObject(developerManager)
        .environmentObject(adminManager)
        .environmentObject(appState)
        .environmentObject(motionManager)
        .preferredColorScheme(
            settingsManager.colorScheme == .automatic ? .none :
                settingsManager.colorScheme == .dark ? .dark : .light
        )
        .onAppear {
            initializePointsManagerDate()
        }
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
}

#Preview {
    ContentView()
}
