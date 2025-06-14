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
        
        updateValues() {}
    }
    
    func updateValues(_ completion: @escaping (() -> Void)) {
        adminManager.fetchBlockedVersions { result in
            switch result {
            case .success(let versions):
                self.blockedVersions = versions?.sorted()
                completion()
            case .failure(_):
                completion()
            }
        }
        
        adminManager.fetchBlockedVersionsAndroid { result in
            switch result {
            case .success(let versions):
                self.blockedVersionsAndroid = versions?.sorted()
                completion()
            case .failure(_):
                completion()
            }
        }
    }
    
    func changeAppIsUnderMaintenanceValue(to newValue: Bool, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("settings").document("maintenance").updateData([
            "status": newValue
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func changeAppForcesUpdatesValue(to newValue: Bool, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("settings").document("force-updates").updateData([
            "status": newValue
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func changeVersionsBlockedValue(to newValue: [String], _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("settings").document("versions-blocked").updateData([
            "versions": newValue
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                self.updateValues() {}
                completion(.success(true))
            }
        }
    }
    
    func changeVersionsBlockedValueForAndroid(to newValue: [String], _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("settings").document("versions-blocked-android").updateData([
            "versions": newValue
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                self.updateValues() {}
                completion(.success(true))
            }
        }
    }
}
