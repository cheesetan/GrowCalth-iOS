//
//  LeaderboardsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
@preconcurrency import FirebaseFirestore

@MainActor
class LeaderboardsManager: ObservableObject {

    @Published var leaderboard: [String: Int] = [:] {
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

    init() {
        Task {
            await load()
            await retrievePoints()
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
            let leaderboardDecoded = try jsonDecoder.decode([String: Int].self, from: retrievedTypeData)
            leaderboard = leaderboardDecoded
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
    }

    func retrievePoints() async {
        do {
            let query = try await Firestore.firestore().collection("HousePoints").getDocuments()

            for document in query.documents {
                switch document.documentID {
                case "Black", "Blue", "Green", "Red", "Yellow":
                    withAnimation {
                        self.leaderboard[document.documentID] = document.data()["points"] as? Int
                    }
                default:
                    print("Unknown house: \(document.documentID)")
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
    }

    func resetLeaderboards(forHouse house: String) async throws {
        guard ["Black", "Blue", "Green", "Red", "Yellow"].contains(house) else {
            throw LeaderboardError.invalidHouseName(house)
        }

        do {
            try await Firestore.firestore().collection("HousePoints").document(house).updateData([
                "points": 0
            ])
        } catch {
            throw LeaderboardError.firestoreError(error)
        }
    }
}
