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

    func checkAndAddPoints() async throws {
        try isDueForPointsAwarding()
        let (pointsToAdd, approvedBundleIdsUsed) = try await calculatePoints()
        print("pointsToAdd: \(pointsToAdd)")
        if pointsToAdd > 0 {
            do {
                try await self.addPointsToFirebase(pointsToAdd: pointsToAdd, approvedBundleIdsUsed: approvedBundleIdsUsed)
            } catch {
                print(error.localizedDescription)
            }
            self.updateLastPointsAwardedDate()
        } else {
            self.updateLastPointsAwardedDate()
        }

    }

    internal enum PointsAddingError: LocalizedError {
        case notDueForAdding
        var errorDescription: String? {
            switch self {
            case .notDueForAdding: "Not due for points adding."
            }
        }
    }

    private func isDueForPointsAwarding() throws {
        if authManager.accountType.canAddPoints {
            if let lastPointsAwardedDate = lastPointsAwardedDate {
                if lastPointsAwardedDate.addingTimeInterval(86400) <= Date() {
                    return
                }
            }
        }
        throw PointsAddingError.notDueForAdding
    }

    private func calculatePoints() async throws -> (Int, [String]) {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let (steps, approvedBundleIdsUsed) = try await hkManager.fetchStepsForPointsCalculation(startDate: lastPointsAwardedDate, endDate: cal.startOfDay(for: Date()))

        let points = Int(Double(steps) / Double(GLOBAL_STEPS_PER_POINT))
        return (points, approvedBundleIdsUsed)
    }

    private func addPointsToFirebase(
        pointsToAdd: Int,
        approvedBundleIdsUsed: [String]
    ) async throws {
        let house = try await authManager.fetchUsersHouse()
        let versions = try await adminManager.fetchBlockedVersions()

        let info = Bundle.main.infoDictionary
        let currentVersion = info?["CFBundleShortVersionString"] as? String

        if let currentVersion = currentVersion, !versions.contains(currentVersion) {
            try await Firestore.firestore().collection("HousePoints").document(house).updateData([
                "points": FieldValue.increment(Double(pointsToAdd))
            ])
            try await self.logPoints(
                points: pointsToAdd,
                approvedBundleIdsUsed: approvedBundleIdsUsed
            )
        }
    }

    private func updateLastPointsAwardedDate() {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        lastPointsAwardedDate = cal.startOfDay(for: Date())
    }

    private func logPoints(
        points: Int,
        approvedBundleIdsUsed: [String]
    ) async throws {
        try await Firestore.firestore().collection("logs").document().setData([
            "dateLogged": Date(),
            "lastPointsAddedDate": self.lastPointsAwardedDate ?? "LASTPOINTSAWARDEDDATE NOT FOUND (impossible)",
            "useruid": Auth.auth().currentUser?.uid ?? "UID NOT FOUND",
            "email": authManager.email ?? "EMAIL NOT FOUND",
            "house": authManager.usersHouse ?? "HOUSE NOT FOUND",
            "pointsAdded": "\(points)",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "idk",
            "approvedBundleIdsUsed": approvedBundleIdsUsed
        ])
    }
}
