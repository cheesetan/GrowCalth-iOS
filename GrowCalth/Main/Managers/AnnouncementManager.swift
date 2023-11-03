//
//  AnnouncementManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import FirebaseFirestore

struct Announcement: Identifiable, Equatable {
    var id: String
    var title: String
    var description: String?
}

struct EventItem: Identifiable, Equatable {
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
    
    init() {
        retrieveAllPosts()
    }
    
    func retrieveAllPosts() {
        retrieveEvents()
        retrieveAnnouncements()
    }
    
    func retrieveEvents() {
        Firestore.firestore().collection("houseevents").order(by: "dateAdded", descending: true).getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                print("Error getting documents: \(err)")
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
            }
        }
    }
    
    func retrieveAnnouncements() {
        Firestore.firestore().collection("Announcements").order(by: "dateAdded", descending: true).getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                print("Error getting documents: \(err)")
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
            }
        }
    }
}
