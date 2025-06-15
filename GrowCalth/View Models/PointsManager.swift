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

    @ObservedObject var adminManager: AdminManager
    @ObservedObject var hkManager: HealthKitManager
    @ObservedObject var authManager: AuthenticationManager

    init(adminManager: AdminManager, hkManager: HealthKitManager, authManager: AuthenticationManager, lastPointsAwardedDate: Date? = nil) {
        self.adminManager = adminManager
        self.hkManager = hkManager
        self.authManager = authManager
        self.lastPointsAwardedDate = lastPointsAwardedDate

        load()
    }

    @Published var lastPointsAwardedDate: Date? = nil {
        didSet {
            save()
        }
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "lastPointsAwardedDate.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("lastPointsAwardedDate.json")
        }
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
                case .success((let pointsToAdd, let approvedBundleIdsUsed)):
                    print("pointsToAdd: \(pointsToAdd)")
                    if pointsToAdd > 0 {
                        self.addPointsToFirebase(
                            pointsToAdd: pointsToAdd,
                            approvedBundleIdsUsed: approvedBundleIdsUsed
                        ) { result in
                            switch result {
                            case .success(_):
                                self.updateLastPointsAwardedDate()
                            case .failure(let failure):
                                self.updateLastPointsAwardedDate()
                                print(failure.localizedDescription)
                            }
                        }
                    } else {
                        self.updateLastPointsAwardedDate()
                    }
                case .failure(let failure):
                    self.updateLastPointsAwardedDate()
                    print(failure.localizedDescription)
                }
            }
        } else {
            print("not due for adding \(String(describing: lastPointsAwardedDate))")
        }
    }

    private func isDueForPointsAwarding() -> Bool {
        if authManager.accountType.canAddPoints {
            if let lastPointsAwardedDate = lastPointsAwardedDate {
                if lastPointsAwardedDate.addingTimeInterval(86400) <= Date() {
                    return true
                }
            }
        } else {
            self.updateLastPointsAwardedDate()
        }
        return false
    }

    private func calculatePoints(_ completion: @escaping ((Result<(Int, [String]), Error>) -> Void)) {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        hkManager.fetchStepsForPointsCalculation(startDate: lastPointsAwardedDate, endDate: cal.startOfDay(for: Date())) { results in
            switch results {
            case .success((let steps, let approvedBundleIdsUsed)):
                print("pointsToAdd steps: \(steps)")
                let points = Int(Double(steps) / Double(GLOBAL_STEPS_PER_POINT))
                completion(.success((
                    points,
                    approvedBundleIdsUsed
                )))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }

    private func addPointsToFirebase(
        pointsToAdd: Int,
        approvedBundleIdsUsed: [String],
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        authManager.fetchUsersHouse { result in
            switch result {
            case .success(let house):
                self.adminManager.fetchBlockedVersions { result in
                    switch result {
                    case .success(let versions):
                        let info = Bundle.main.infoDictionary
                        let currentVersion = info?["CFBundleShortVersionString"] as? String

                        if let versions = versions, let currentVersion = currentVersion {
                            if !versions.contains(currentVersion) {
                                Firestore.firestore().collection("HousePoints").document(house).updateData([
                                    "points": FieldValue.increment(Double(pointsToAdd))
                                ]) { err in
                                    if let err = err {
                                        completion(.failure(err))
                                    } else {
                                        self.logPoints(
                                            points: pointsToAdd,
                                            approvedBundleIdsUsed: approvedBundleIdsUsed
                                        )
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

    private func updateLastPointsAwardedDate() {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        lastPointsAwardedDate = cal.startOfDay(for: Date())
    }

    private func logPoints(
        points: Int,
        approvedBundleIdsUsed: [String]
    ) {
        Firestore.firestore().collection("logs").document().setData([
            "dateLogged": Date(),
            "lastPointsAddedDate": self.lastPointsAwardedDate ?? "LASTPOINTSAWARDEDDATE NOT FOUND (impossible)",
            "useruid": Auth.auth().currentUser?.uid ?? "UID NOT FOUND",
            "email": authManager.email ?? "EMAIL NOT FOUND",
            "house": authManager.usersHouse ?? "HOUSE NOT FOUND",
            "pointsAdded": "\(points)",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "idk",
            "approvedBundleIdsUsed": approvedBundleIdsUsed
        ]) { _ in }
    }
}
