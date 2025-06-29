import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Sendable struct for log data
struct LogData: Sendable {
    let dateLogged: Date
    let lastPointsAddedDate: Date
    let useruid: String
    let email: String
    let house: String
    let pointsAdded: String
    let appVersion: String
    let approvedBundleIdsUsed: [String]

    func toDictionary() -> [String: Any] {
        return [
            "dateLogged": dateLogged,
            "lastPointsAddedDate": lastPointsAddedDate,
            "useruid": useruid,
            "email": email,
            "house": house,
            "pointsAdded": pointsAdded,
            "appVersion": appVersion,
            "approvedBundleIdsUsed": approvedBundleIdsUsed
        ]
    }
}

@MainActor
class PointsManager: ObservableObject {

    @ObservedObject var adminManager: AdminManager
    @ObservedObject var hkManager: HealthKitManager
    @ObservedObject var authManager: AuthenticationManager

    @Published var lastPointsAwardedDate: Date? = nil {
        didSet {
            Task {
                await save()
            }
        }
    }

    enum PointsError: LocalizedError {
        case notDueForAdding
        case fileOperationFailed(Error)
        case firestoreError(Error)
        case invalidVersion(String?)
        case missingUserData

        var errorDescription: String? {
            switch self {
            case .notDueForAdding:
                return "Not due for points adding"
            case .fileOperationFailed(let error):
                return "File operation failed: \(error.localizedDescription)"
            case .firestoreError(let error):
                return "Firestore error: \(error.localizedDescription)"
            case .invalidVersion(let version):
                return "Invalid app version: \(version ?? "unknown")"
            case .missingUserData:
                return "Missing user data"
            }
        }
    }

    init(adminManager: AdminManager, hkManager: HealthKitManager, authManager: AuthenticationManager, lastPointsAwardedDate: Date? = nil) {
        self.adminManager = adminManager
        self.hkManager = hkManager
        self.authManager = authManager
        self.lastPointsAwardedDate = lastPointsAwardedDate

        Task {
            await load()
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

    private func save() async {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        do {
            let encodedlastPointsAwardedDates = try jsonEncoder.encode(lastPointsAwardedDate)
            try encodedlastPointsAwardedDates.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("Failed to save last points awarded date: \(error)")
        }
    }

    private func load() async {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        do {
            let retrievedDateData = try Data(contentsOf: archiveURL)
            let lastPointsAwardedDatesDecoded = try jsonDecoder.decode(Date.self, from: retrievedDateData)
            lastPointsAwardedDate = lastPointsAwardedDatesDecoded
        } catch {
            print("Failed to load last points awarded date: \(error)")
        }
    }

    func checkAndAddPoints() async throws {
        try isDueForPointsAwarding()
        let (pointsToAdd, approvedBundleIdsUsed) = try await calculatePoints()
        print("pointsToAdd: \(pointsToAdd)")

        if pointsToAdd > 0 {
            try await addPointsToFirebase(pointsToAdd: pointsToAdd, approvedBundleIdsUsed: approvedBundleIdsUsed)
        }

        updateLastPointsAwardedDate()
    }

    private func isDueForPointsAwarding() throws {
        guard authManager.accountType.canAddPoints else {
            throw PointsError.notDueForAdding
        }

        if let lastPointsAwardedDate = lastPointsAwardedDate {
            guard lastPointsAwardedDate.addingTimeInterval(86400) <= Date() else {
                throw PointsError.notDueForAdding
            }
        }
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

        guard let currentVersion = currentVersion, !versions.contains(currentVersion) else {
            throw PointsError.invalidVersion(currentVersion)
        }

        try await Firestore.firestore().collection("HousePoints").document(house).updateData([
            "points": FieldValue.increment(Double(pointsToAdd))
        ])

        try await logPoints(
            points: pointsToAdd,
            approvedBundleIdsUsed: approvedBundleIdsUsed
        )
    }

    private func updateLastPointsAwardedDate() {
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        lastPointsAwardedDate = cal.startOfDay(for: Date())
    }

    private func logPoints(
        points: Int,
        approvedBundleIdsUsed: [String]
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = authManager.email,
              let house = authManager.usersHouse else {
            throw PointsError.missingUserData
        }

        // Create Sendable LogData struct
        let logData = LogData(
            dateLogged: Date(),
            lastPointsAddedDate: self.lastPointsAwardedDate ?? Date(),
            useruid: uid,
            email: email,
            house: house,
            pointsAdded: String(points),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            approvedBundleIdsUsed: approvedBundleIdsUsed
        )

        // Pass the Sendable struct and convert to dictionary within the async context
        try await performFirestoreLog(logData)
    }

    private func performFirestoreLog(_ logData: LogData) async throws {
        try await Firestore.firestore().collection("logs").document().setData(logData.toDictionary())
    }
}
