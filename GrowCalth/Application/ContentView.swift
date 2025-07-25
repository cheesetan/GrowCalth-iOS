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
    case home, announcements, challenges, napfa, settings
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

    @Environment(\.colorScheme) private var colorScheme

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
                if #available(iOS 18.0, *) {
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
//                GeometryReader { geometry in
//                    ZStack {
//                        Color.background.ignoresSafeArea()
//                        VStack {
//                            switch tabSelected {
//                            case .home: HomeView()
//                            case .announcements: AnnouncementsView()
//                            case .challenges: Text("Challenges")
//                            case .napfa: NAPFAView()
//                            case .settings: SettingsView()
//                            }
//                        }
//                        .padding(.bottom, geometry.size.height * 0.08 + geometry.size.height * 0.03)
//
//                        TabBar(height: geometry.size.height, tabSelected: $tabSelected)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .ignoresSafeArea()
//                }
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

struct TabBar: View {

    @State var height: CGFloat
    @Binding var tabSelected: TabSelection

    @EnvironmentObject private var motionManager: MotionManager

    var body: some View {
        Capsule()
            .fill(.shadow(.inner(
                color: Color.tabBarInnerShadow,
                radius: 6.5
            )))
            .foregroundStyle(Color.background)
            .frame(maxWidth: .infinity)
            .frame(height: height * 0.08)
            .specularHighlight(motionManager: motionManager)
            .shadow(color: Color.tabBarOuterShadow, radius: 17.5, x: 0, y: 5)
            .overlay {
                GeometryReader { geometry in
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(20)),
                            GridItem(.flexible()),
                            GridItem(.fixed(20)),
                            GridItem(.fixed(20)),
                            GridItem(.fixed(20))
                        ],
                        spacing: 0
                    ) {
                        tabButton("Home", systemImage: "house.fill", value: .home)
                        tabButton("Announcements", systemImage: "megaphone.fill", value: .announcements)
                        tabButton("Challenges", systemImage: "flag.checkered", value: .challenges)
                        tabButton("NAPFA", systemImage: "figure.run", value: .napfa)
                        tabButton("Settings", systemImage: "gearshape.fill", value: .settings)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .padding(.horizontal, height*0.08*0.2)
                .padding(.vertical, height*0.08*0.14)
            }
            .mask(Capsule())
            .padding(.bottom, height * 0.03)
            .padding(.horizontal, height * 0.025)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    @ViewBuilder
    func tabButton(
        _ title: String,
        systemImage image: String,
        value tab: TabSelection
    ) -> some View {
        let isActive = tabSelected == tab
        Button {
            withAnimation {
                tabSelected = tab
            }
        } label: {
            VStack(spacing: height*0.08*0.01) {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(isActive ? .accent : .primary)
                    .padding(height*0.08*0.07)

                Text(title)
                    .font(.system(size: height*0.08*0.12))
                    .foregroundStyle(isActive ? .accent : .primary)
                    .lineLimit(1)
            }
            .shadow(
                color: isActive ? Color.accent.opacity(0.8) : .clear,
                radius: height*0.08*0.25
            )
        }
        .buttonStyle(.plain)
        .border(.red)
    }
}

#Preview {
    ContentView()
}
