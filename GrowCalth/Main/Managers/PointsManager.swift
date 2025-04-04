//
//  PointsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 30/10/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class PointsManager: ObservableObject {
    static let shared: PointsManager = .init()
    
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var hkManager: HealthKitManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared

    @Published var lastPointsAwardedDate: Date? = nil {
        didSet {
            save()
        }
    }

    init() {
        load()
    }

    private func getArchiveURL() -> URL {
        URL.documentsDirectory.appending(path: "lastPointsAwardedDate.json")
    }

    private func save() {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let encodedlastPointsAwardedDates = try? jsonEncoder.encode(lastPointsAwardedDate)
        try? encodedlastPointsAwardedDates?.write(to: archiveURL, options: .noFileProtection)
    }

    private func load() {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        if let retrievedDateData = try? Data(contentsOf: archiveURL),
           let lastPointsAwardedDatesDecoded = try? jsonDecoder.decode(Date.self, from: retrievedDateData) {
            lastPointsAwardedDate = lastPointsAwardedDatesDecoded
        }
    }

    func checkAndAddPoints() {
        if isDueForPointsAwarding() {
            calculatePoints { result in
                switch result {
                case .success(let pointsToAdd):
                    print("pointsToAdd: \(pointsToAdd)")
                    if pointsToAdd > 0 {
                        self.addPointsToFirebase(pointsToAdd: pointsToAdd) { result in
                            switch result {
                            case .success(_):
                                self.updateVariables()
                            case .failure(let failure):
                                self.updateVariables()
                                print(failure.localizedDescription)
                            }
                        }
                    } else {
                        self.updateVariables()
                    }
                case .failure(let failure):
                    self.updateVariables()
                    print(failure.localizedDescription)
                }
            }
        } else {
            print("not due for adding \(String(describing: lastPointsAwardedDate))")
        }
    }
    
    private func isDueForPointsAwarding() -> Bool {
        if let lastPointsAwardedDate = lastPointsAwardedDate {
            if lastPointsAwardedDate.addingTimeInterval(86400) <= Date() {
                return true
            }
        }
        return false
    }
    
    private func calculatePoints(_ completion: @escaping ((Result<Int, Error>) -> Void)) {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        hkManager.fetchStepsForPointsCalculation(startDate: lastPointsAwardedDate, endDate: cal.startOfDay(for: Date())) { result in
            switch result {
            case .success(let steps):
                print("pointsToAdd steps: \(steps)")
                let points = Int(Double(steps) / Double(GLOBAL_STEPS_PER_POINT))
                completion(.success(points))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    private func addPointsToFirebase(
        pointsToAdd: Int, 
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        fetchCurrentPoints { result in
            switch result {
            case .success(let success):
                self.adminManager.fetchBlockedVersions { result in
                    switch result {
                    case .success(let versions):
                        let info = Bundle.main.infoDictionary
                        let currentVersion = info?["CFBundleShortVersionString"] as? String
                        
                        if let versions = versions, let currentVersion = currentVersion {
                            if !versions.contains(currentVersion) {
                                Firestore.firestore().collection("HousePoints").document(success[0]).updateData([
                                    "points": Int(success[1])! + pointsToAdd
                                ]) { err in
                                    if let err = err {
                                        completion(.failure(err))
                                    } else {
                                        self.logPoints(points: pointsToAdd, previousHousePoints: Int(success[1])!)
                                        completion(.success(true))
                                    }
                                }
                            }
                        }
                    case .failure(let failure):
                        print(failure.localizedDescription)
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
                Firestore.firestore().collection("HousePoints").document(house).getDocument(source: .server) { (document, error) in
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
    
    private func logPoints(points: Int, previousHousePoints: Int) {
        Firestore.firestore().collection("logs").document().setData([
            "dateLogged": Date(),
            "lastPointsAddedDate": self.lastPointsAwardedDate ?? "LASTPOINTSAWARDEDDATE NOT FOUND (impossible)",
            "useruid": Auth.auth().currentUser?.uid ?? "UID NOT FOUND",
            "email": authManager.email ?? "EMAIL NOT FOUND",
            "house": authManager.usersHouse ?? "HOUSE NOT FOUND",
            "pointsAdded": "\(points)",
            "previousHousePoints": previousHousePoints,
            "newHousePoints": previousHousePoints + points,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "idk",
        ]) { _ in }
    }
}
