//
//  AnnouncementManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import FirebaseFirestore

class AnnouncementManager: ObservableObject {

    @Published var announcements: [Announcement] = [] {
        didSet {
            saveAnnouncements()
        }
    }

    @Published var events: [EventItem] = [] {
        didSet {
            saveEvents()
        }
    }
    
    init() {
        loadEvents()
        loadAnnouncements()
        retrieveAllPosts() {}
    }

    private func getAnnouncementArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "announcements.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("announcements.json")
        }
    }

    private func getEventArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "events.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("events.json")
        }
    }

    private func saveAnnouncements() {
        let archiveURL = getAnnouncementArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let encodedAnnouncements = try? jsonEncoder.encode(announcements)
        try? encodedAnnouncements?.write(to: archiveURL, options: .noFileProtection)
    }

    private func saveEvents() {
        let archiveURL = getEventArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        let encodedEventItems = try? jsonEncoder.encode(events)
        try? encodedEventItems?.write(to: archiveURL, options: .noFileProtection)
    }

    private func loadAnnouncements() {
        let archiveURL = getAnnouncementArchiveURL()
        let jsonDecoder = JSONDecoder()

        if let retrievedAnnouncementData = try? Data(contentsOf: archiveURL),
           let announcementsDecoded = try? jsonDecoder.decode([Announcement].self, from: retrievedAnnouncementData) {
            announcements = announcementsDecoded
        }
    }

    private func loadEvents() {
        let archiveURL = getEventArchiveURL()
        let jsonDecoder = JSONDecoder()
        
        if let retrievedEventItemData = try? Data(contentsOf: archiveURL),
           let eventsDecoded = try? jsonDecoder.decode([EventItem].self, from: retrievedEventItemData) {
            events = eventsDecoded
        }
    }
    
    func retrieveAllPosts(_ completion: @escaping (() -> Void)) {
        self.retrieveEvents() { _ in }
        self.retrieveAnnouncements() { _ in }
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
                            name: document.data()["name"] as? String,
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
                            name: document.data()["name"] as? String,
                            title: document.data()["header"] as! String,
                            description: document.data()["text"] as! String?
                        )
                    )
                }
                completion(.success(true))
            }
        }
    }
}
