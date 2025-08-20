//
//  AnnouncementManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class AnnouncementManager: ObservableObject, Sendable {
    @Published var announcements: [Announcement] = [] {
        didSet {
            Task {
                await saveAnnouncements()
            }
        }
    }
    
    @Published var events: [EventItem] = [] {
        didSet {
            Task {
                await saveEvents()
            }
        }
    }
    
    init() {
        Task {
            await initializeData()
        }
    }
    
    private func initializeData() async {
        await loadEvents()
        await loadAnnouncements()
        
        do {
            try await retrieveAllPosts()
        } catch {
            print("Failed to retrieve posts: \(error)")
        }
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
    
    private func saveAnnouncements() async {
        let archiveURL = getAnnouncementArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodedData = try jsonEncoder.encode(announcements)
            try encodedData.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("Failed to save announcements: \(error)")
        }
    }
    
    private func saveEvents() async {
        let archiveURL = getEventArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let encodedData = try jsonEncoder.encode(events)
            try encodedData.write(to: archiveURL, options: .noFileProtection)
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    private func loadAnnouncements() async {
        let archiveURL = getAnnouncementArchiveURL()
        let jsonDecoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: archiveURL)
            let decodedAnnouncements = try jsonDecoder.decode([Announcement].self, from: data)
            announcements = decodedAnnouncements
        } catch {
            print("Failed to load announcements: \(error)")
        }
    }
    
    private func loadEvents() async {
        let archiveURL = getEventArchiveURL()
        let jsonDecoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: archiveURL)
            let decodedEvents = try jsonDecoder.decode([EventItem].self, from: data)
            events = decodedEvents
        } catch {
            print("Failed to load events: \(error)")
        }
    }
    
    func retrieveAllPosts() async throws {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.retrieveAnnouncements()
                }
                group.addTask {
                    try await self.retrieveEvents()
                }
                
                // Wait for all tasks to complete
                for try await _ in group { }
            }
        } catch {
            print("Failed to initialize settings: \(error)")
            throw error
        }
    }
    
    func retrieveEvents() async throws {
        let events = try await self.fetchEvents()
        self.events = events
    }
    
    nonisolated internal func fetchEvents() async throws -> [EventItem] {
        let query = try await Firestore.firestore()
            .collection("schools")
            .document("sst")
            .collection("houseEvents")
            .order(by: "dateAdded", descending: true)
            .getDocuments()
        
        let newEvents = query.documents.compactMap { document -> EventItem? in
            guard let title = document.data()["title"] as? String,
                  let description = document.data()["description"] as? String,
                  let venue = document.data()["venue"] as? String,
                  let date = (document.data()["eventDate"] as? Timestamp)?.dateValue(),
                  let dateAdded = (document.data()["dateAdded"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return EventItem(
                id: document.documentID,
                dateAdded: dateAdded,
                title: title,
                description: description,
                venue: venue,
                eventDate: date
            )
        }
        
        return newEvents
    }
    
    func retrieveAnnouncements() async throws {
        let announcements = try await self.fetchAnnouncements()
        self.announcements = announcements
    }
    
    nonisolated internal func fetchAnnouncements() async throws -> [Announcement] {
        let query = try await Firestore.firestore()
            .collection("schools")
            .document("sst")
            .collection("announcements")
            .order(by: "dateAdded", descending: true)
            .getDocuments()
        
        let newAnnouncements = query.documents.compactMap { document -> Announcement? in
            guard let title = document.data()["title"] as? String,
                  let description = document.data()["description"] as? String,
                  let date = (document.data()["dateAdded"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return Announcement(
                id: document.documentID,
                date: date,
                title: title,
                description: description
            )
        }
        
        return newAnnouncements
    }
}
