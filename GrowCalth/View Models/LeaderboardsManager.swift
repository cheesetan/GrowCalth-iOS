//
//  LeaderboardsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class LeaderboardsManager: ObservableObject {

    @Published var leaderboard: [House] = [] {
        didSet {
            Task {
                await save()
            }
        }
    }

    enum LeaderboardError: LocalizedError {
        case fileOperationFailed(Error)
        case firestoreError(Error)
        case invalidHouseName(String)

        var errorDescription: String? {
            switch self {
            case .fileOperationFailed(let error):
                return "File operation failed: \(error.localizedDescription)"
            case .firestoreError(let error):
                return "Firestore error: \(error.localizedDescription)"
            case .invalidHouseName(let name):
                return "Invalid house name: \(name)"
            }
        }
    }

    private let authManager: AuthenticationManager

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        Task {
            await load()
            await retrieveLeaderboard()
        }
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "leaderboard.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("leaderboard.json")
        }
    }

    private func save() async {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        do {
            let encodedTypes = try jsonEncoder.encode(leaderboard)
            try encodedTypes.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("Failed to save leaderboard: \(error)")
        }
    }

    private func load() async {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        do {
            let retrievedTypeData = try Data(contentsOf: archiveURL)
            let leaderboardDecoded = try jsonDecoder.decode([House].self, from: retrievedTypeData)
            leaderboard = leaderboardDecoded
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
    }

    func retrieveLeaderboard() async {
        do {
            let fetchedData = try await self.fetchLeaderboard()
            withAnimation {
                self.leaderboard = fetchedData
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }

    nonisolated internal func fetchLeaderboard() async throws -> [House] {
        guard let schoolCode = await authManager.schoolCode else { return [] }

        var result: [House] = []
        let query = try await Firestore.firestore()
            .collection("schools")
            .document(schoolCode).collection("leaderboard").getDocuments()

        for document in query.documents {
            guard let name = document.data()["name"] as? String else { return [] }
            guard let color = document.data()["color"] as? String else { return [] }
            guard let points = document.data()["points"] as? Int else { return [] }
            let icon = document.data()["icon"] as? String ?? ""

            result.append(
                House(
                    id: document.documentID,
                    name: name,
                    color: Color(hex: color, alpha: 1) ?? .gray,
                    points: points,
                    icon: URL(string: icon)
                )
            )
        }

        return result
    }
}
