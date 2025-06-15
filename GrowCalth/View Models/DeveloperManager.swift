//
//  DeveloperManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 31/3/24.
//

import SwiftUI
import FirebaseFirestore

class DeveloperManager: ObservableObject {
    
    @Published var bypassed = false
    @Published var blockedVersions: [String]?
    @Published var blockedVersionsAndroid: [String]?
    
    @ObservedObject var adminManager: AdminManager
    
    init(bypassed: Bool = false, blockedVersions: [String]? = nil, blockedVersionsAndroid: [String]? = nil, adminManager: AdminManager) {
        self.bypassed = bypassed
        self.blockedVersions = blockedVersions
        self.blockedVersionsAndroid = blockedVersionsAndroid
        self.adminManager = adminManager

        Task {
            try await updateValues()
        }
    }
    
    func updateValues() async throws {
        let versions = try await adminManager.fetchBlockedVersions()
        self.blockedVersions = versions.sorted()

        let versionsAndroid = try await adminManager.fetchBlockedVersionsAndroid()
        self.blockedVersionsAndroid = versionsAndroid.sorted()
    }
    
    func changeAppIsUnderMaintenanceValue(to newValue: Bool) async throws {
        try await Firestore.firestore().collection("settings").document("maintenance").updateData([
            "status": newValue
        ])
    }
    
    func changeAppForcesUpdatesValue(to newValue: Bool) async throws {
        try await Firestore.firestore().collection("settings").document("force-updates").updateData([
            "status": newValue
        ])
    }
    
    func changeVersionsBlockedValue(to newValue: [String]) async throws {
        try await Firestore.firestore().collection("settings").document("versions-blocked").updateData([
            "versions": newValue
        ])
        try await self.updateValues()
    }
    
    func changeVersionsBlockedValueForAndroid(to newValue: [String]) async throws {
        try await Firestore.firestore().collection("settings").document("versions-blocked-android").updateData([
            "versions": newValue
        ])
        try await self.updateValues()
    }
}
