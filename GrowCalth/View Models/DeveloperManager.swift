//
//  DeveloperManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 31/3/24.
//

import SwiftUI
import FirebaseFirestore

enum DeveloperManagerError: LocalizedError, Sendable {
    case failedToUpdateMaintenance
    case failedToUpdateForceUpdates
    case failedToUpdateBlockedVersions
    case failedToUpdateBlockedVersionsAndroid
    case failedToFetchBlockedVersions

    var errorDescription: String? {
        switch self {
        case .failedToUpdateMaintenance:
            return "Failed to update maintenance status. Please try again."
        case .failedToUpdateForceUpdates:
            return "Failed to update force updates setting. Please try again."
        case .failedToUpdateBlockedVersions:
            return "Failed to update blocked versions. Please try again."
        case .failedToUpdateBlockedVersionsAndroid:
            return "Failed to update blocked Android versions. Please try again."
        case .failedToFetchBlockedVersions:
            return "Failed to fetch blocked versions. Please try again."
        }
    }
}

@MainActor
final class DeveloperManager: ObservableObject {

    @Published var bypassed = false
    @Published var blockedVersions: [String]?
    @Published var blockedVersionsAndroid: [String]?

    let adminManager: AdminManager

    init(bypassed: Bool = false, blockedVersions: [String]? = nil, blockedVersionsAndroid: [String]? = nil, adminManager: AdminManager) {
        self.bypassed = bypassed
        self.blockedVersions = blockedVersions
        self.blockedVersionsAndroid = blockedVersionsAndroid
        self.adminManager = adminManager

        Task {
            do {
                try await updateValues()
            } catch {
                print("Failed to update values: \(error)")
            }
        }
    }

    func updateValues() async throws {
        do {
            let versions = try await adminManager.fetchBlockediOSVersions()
            self.blockedVersions = versions.sorted()

            let versionsAndroid = try await adminManager.fetchBlockedAndroidVersions()
            self.blockedVersionsAndroid = versionsAndroid.sorted()
        } catch {
            throw DeveloperManagerError.failedToFetchBlockedVersions
        }
    }

    func changeAppIsUnderMaintenanceValue(to newValue: Bool) async throws {
        do {
            try await Firestore.firestore().collection("settings").document("maintenance").updateData([
                "status": newValue
            ])
        } catch {
            throw DeveloperManagerError.failedToUpdateMaintenance
        }
    }

    func changeAppForcesUpdatesValue(to newValue: Bool) async throws {
        do {
            try await Firestore.firestore().collection("settings").document("force-updates").updateData([
                "status": newValue
            ])
        } catch {
            throw DeveloperManagerError.failedToUpdateForceUpdates
        }
    }

    func changeVersionsBlockedValue(to newValue: [String]) async throws {
        do {
            try await Firestore.firestore().collection("settings").document("versions-blocked").updateData([
                "versions": newValue
            ])
            try await self.updateValues()
        } catch let error as DeveloperManagerError {
            throw error
        } catch {
            throw DeveloperManagerError.failedToUpdateBlockedVersions
        }
    }

    func changeVersionsBlockedValueForAndroid(to newValue: [String]) async throws {
        do {
            try await Firestore.firestore().collection("settings").document("versions-blocked-android").updateData([
                "versions": newValue
            ])
            try await self.updateValues()
        } catch let error as DeveloperManagerError {
            throw error
        } catch {
            throw DeveloperManagerError.failedToUpdateBlockedVersionsAndroid
        }
    }
}
