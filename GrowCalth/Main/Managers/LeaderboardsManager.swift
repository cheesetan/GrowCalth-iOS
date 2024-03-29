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
    
    @Published var black: Int?
    @Published var blue: Int?
    @Published var green: Int?
    @Published var red: Int?
    @Published var yellow: Int?
    
    init() {
        retrievePoints { _ in }
    }
    
    func retrievePoints(_ completion: @escaping ((Bool) -> Void)) {
        Firestore.firestore().collection("HousePoints").getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                print("Error getting documents: \(err)")
            } else {
                for document in query!.documents {
                    switch document.documentID {
                    case "Black":
                        withAnimation {
                            self.black = document.data()["points"] as? Int
                        }
                    case "Blue":
                        withAnimation {
                            self.blue = document.data()["points"] as? Int
                        }
                    case "Green":
                        self.green = document.data()["points"] as? Int
                    case "Red":
                        withAnimation {
                            self.red = document.data()["points"] as? Int
                        }
                    case "Yellow":
                        withAnimation {
                            self.yellow = document.data()["points"] as? Int
                        }
                    default:
                        print("error")
                    }
                }
                completion(true)
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
