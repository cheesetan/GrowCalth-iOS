//
//  AppState.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import SwiftUI

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

    var deviceWidth: CGFloat = 0
    var padding: CGFloat {
        deviceWidth * 0.0697674419
    }
}
