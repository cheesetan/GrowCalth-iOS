//
//  AnnouncementManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import SwiftPersistence
import FirebaseFirestore

struct Announcement: Identifiable, Equatable, Codable {
    var id: String
    var title: String
    var description: String?
}

struct EventItem: Identifiable, Equatable, Codable {
    var id: String
    var title: String
    var description: String?
    var venue: String
    var date: String
}

enum AnnouncementType: String, CaseIterable {
    case announcements = "Announcements"
    case events = "Events"
}

class AnnouncementManager: ObservableObject {
    static let shared: AnnouncementManager = .init()
    
    @Published var events: [EventItem] = []
    @Published var announcements: [Announcement] = []
    
    @Persistent("cachedEvents", store: .fileManager) private var cachedEvents: [EventItem] = []
    @Persistent("cachedAnnouncements", store: .fileManager) private var cachedAnnouncements: [Announcement] = []
    
    init() {
        retrieveAllPosts() { }
    }
    
    func retrieveAllPosts(_ completion: @escaping (() -> Void)) {
        self.retrieveEvents() { _ in
            self.retrieveAnnouncements() { _ in
                completion()
            }
        }
    }
    
    func retrieveEvents(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("houseevents").order(by: "dateAdded", descending: true).getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                completion(.failure(err))
            } else {
                self.events = []
                for document in query!.documents {
                    self.events.append(
                        EventItem(
                            id: document.documentID,
                            title: document.data()["header"] as! String,
                            description: document.data()["desc"] as! String?,
                            venue: document.data()["venue"] as! String,
                            date: document.data()["date"] as! String
                        )
                    )
                }
                completion(.success(true))
            }
        }
    }
    
    func retrieveAnnouncements(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("Announcements").order(by: "dateAdded", descending: true).getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                completion(.failure(err))
            } else {
                self.announcements = []
                for document in query!.documents {
                    self.announcements.append(
                        Announcement(
                            id: document.documentID,
                            title: document.data()["header"] as! String,
                            description: document.data()["text"] as! String?
                        )
                    )
                }
                completion(.success(true))
            }
        }
    }
    
    
    func updateCacheForAllPosts() {
        updateCacheForEvents()
        updateCacheForAnnouncements()
    }
    
    func updateCacheForEvents() {
        self.cachedEvents = self.events
    }
    
    func updateCacheForAnnouncements() {
        self.cachedAnnouncements = self.announcements
    }
}
