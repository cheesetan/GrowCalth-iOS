//
//  PointsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 30/10/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftPersistence

class PointsManager: ObservableObject {
    static let shared: PointsManager = .init()
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    @Persistent("lastPointsAwardedDate") private var lastPointsAwardedDate: Date? = nil
    @Persistent("appInstalledDate") private var appInstalledDate: Date = Date()
    
    func checkAndAddPoints() {
        if isDueForPointsAwarding() {
            calculatePoints { result in
                switch result {
                case .success(let pointsToAdd):
                    print("pointsToAdd: \(pointsToAdd)")
                    self.addPointsToFirebase(pointsToAdd: pointsToAdd) { result in
                        switch result {
                        case .success(_):
                            self.updateVariables()
                        case .failure(let failure):
                            print(failure.localizedDescription)
                        }
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            }
        } else {
            print("not due for adding")
        }
    }
    
    private func isDueForPointsAwarding() -> Bool {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        
        if let lastPointsAwardedDate = lastPointsAwardedDate {
            if lastPointsAwardedDate.addingTimeInterval(86400) < cal.startOfDay(for: Date()) {
                return true
            }
        } else {
            if appInstalledDate.addingTimeInterval(86400) < cal.startOfDay(for: Date()) {
                return true
            }
        }
        return false
    }
    
    private func calculatePoints(_ completion: @escaping ((Result<Int, Error>) -> Void)) {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        hkManager.fetchStepsForPointsCalculation(startDate: lastPointsAwardedDate ?? appInstalledDate, endDate: cal.startOfDay(for: Date())) { result in
            switch result {
            case .success(let steps):
                print("pointsToAdd steps: \(steps)")
                let points = Int(Double(steps) / Double(1000))
                completion(.success(points))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    private func addPointsToFirebase(pointsToAdd: Int, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        fetchCurrentPoints { result in
            switch result {
            case .success(let success):
                Firestore.firestore().collection("HousePoints").document(success[0]).updateData([
                    "points": Int(success[1])! + pointsToAdd
                ]) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(true))
                    }
                }
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
    
    private func fetchCurrentPoints(_ completion: @escaping ((Result<[String], Error>) -> Void)) {
        authManager.fetchUsersHouse { result in
            switch result {
            case .success(let house):
                Firestore.firestore().collection("HousePoints").document(house).getDocument { (document, error) in
                    if let document = document, document.exists {
                        if let documentData = document.data() {
                            let pointsString = "\(documentData["points"] as! Int)"
                            completion(.success([house, pointsString]))
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
    
    private func updateVariables() {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        lastPointsAwardedDate = cal.startOfDay(for: Date())
    }
}
