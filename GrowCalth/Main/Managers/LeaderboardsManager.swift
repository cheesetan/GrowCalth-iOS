//
//  LeaderboardsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import FirebaseFirestore

class LeaderboardsManager: ObservableObject {
    static let shared: LeaderboardsManager = .init()
    
    @Published var leaderboard: [String : Int] = [:] {
        didSet {
            save()
        }
    }

    init() {
        load()
        retrievePoints()
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "leaderboard.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("leaderboard.json")
        }
    }

    private func save() {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let encodedTypes = try? jsonEncoder.encode(leaderboard)
        try? encodedTypes?.write(to: archiveURL, options: .noFileProtection)
    }

    private func load() {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        if let retrievedTypeData = try? Data(contentsOf: archiveURL),
           let leaderboardDecoded = try? jsonDecoder.decode([String : Int].self, from: retrievedTypeData) {
            leaderboard = leaderboardDecoded
        }
    }

    func retrievePoints() {
        Firestore.firestore().collection("HousePoints").getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                print("Error getting documents: \(err)")
            } else {
                for document in query!.documents {
                    switch document.documentID {
                    case "Black", "Blue", "Green", "Red", "Yellow":
                        withAnimation {
                            self.leaderboard[document.documentID] = document.data()["points"] as? Int
                        }
                    default:
                        print("error")
                    }
                }
            }
        }
    }
    
    func resetLeaderboards(forHouse house: String, _ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("HousePoints").document(house).updateData([
            "points": 0
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
}
