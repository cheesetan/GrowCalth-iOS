//
//  DeveloperManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 31/3/24.
//

import SwiftUI
import FirebaseFirestore

class DeveloperManager: ObservableObject {
    static let shared: DeveloperManager = .init()
    
    @Published var blockedVersions: [String]?
    
    @ObservedObject var adminManager: AdminManager = .shared
    
    init() {
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
}
