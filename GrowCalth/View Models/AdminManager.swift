//
//  AdminManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import SwiftUI
import FirebaseFirestore

enum PostError: LocalizedError {
    case failedToGetEmail
    case failedToPostAnnouncement
    case failedToPostEvent
    case failedToUpdateAnnouncement
    case failedToUpdateEvent
    case failedToDeleteAnnouncement
    case failedToDeleteEvent

    var errorDescription: String? {
        switch self {
        case .failedToGetEmail: "An error has occured while attempting to fetch your account details. Please sign out and sign back in again."
        case .failedToPostAnnouncement: "An error has occured while attempting to post your announcement. Please try again later."
        case .failedToPostEvent: "An error has occured while attempting to post your event. Please try again later."
        case .failedToUpdateAnnouncement: "An error has occured while attempting to update your announcement. Please try again later."
        case .failedToUpdateEvent: "An error has occured while attempting to update your event. Please try again later."
        case .failedToDeleteAnnouncement: "An error has occured while attempting to delete your announcement. Please try again later."
        case .failedToDeleteEvent: "An error has occured while attempting to delete your event. Please try again later."
        }
    }
}

class AdminManager: ObservableObject {

    @Published var isUnderMaintenance: Bool?
    @Published var appForcesUpdates: Bool?
    
    @ObservedObject var authManager: AuthenticationManager

    init(isUnderMaintenance: Bool? = nil, appForcesUpdates: Bool? = nil, authManager: AuthenticationManager) {
        self.isUnderMaintenance = isUnderMaintenance
        self.appForcesUpdates = appForcesUpdates
        self.authManager = authManager
        Task {
            try await checkIfUnderMaintenance()
            try await checkIfAppForcesUpdates()
        }
    }
    
    func postAnnouncement(title: String, description: String) async throws {
        if let email = authManager.email {
            do {
                try await Firestore.firestore().collection("Announcements").document().setData([
                    "dateAdded": Date(),
                    "header": title,
                    "text": description,
                    "name": email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased()
                ])
            } catch {
                throw PostError.failedToPostAnnouncement
            }
        } else {
            throw PostError.failedToGetEmail
        }
    }
    
    func postEvent(
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String
    ) async throws {
        if let email = authManager.email {
            do {
                try await Firestore.firestore().collection("houseevents").document().setData([
                    "dateAdded": Date(),
                    "header": title,
                    "desc": description,
                    "venue": eventVenues,
                    "date": eventDate.formatted(date: .long, time: .omitted),
                    "name": email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased()
                ])
            } catch {
                throw PostError.failedToPostEvent
            }
        } else {
            throw PostError.failedToGetEmail
        }
    }
    
    func editAnnouncement(announcementUUID: String, title: String, description: String) async throws {
        do {
            try await Firestore.firestore().collection("Announcements").document(announcementUUID).updateData([
                "header": title,
                "text": description
            ])
        } catch {
            throw PostError.failedToUpdateAnnouncement
        }
    }
    
    func editEvent(
        eventUUID: String,
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String
    ) async throws {
        do {
            try await Firestore.firestore().collection("houseevents").document(eventUUID).updateData([
                "header": title,
                "desc": description,
                "venue": eventVenues,
                "date": eventDate.formatted(date: .long, time: .omitted)
            ])
        } catch {
            throw PostError.failedToUpdateEvent
        }
    }
    
    func deleteAnnouncement(announcementUUID: String) async throws {
        do {
            try await Firestore.firestore().collection("Announcements").document(announcementUUID).delete()
        } catch {
            throw PostError.failedToDeleteAnnouncement
        }
    }
    
    func deleteEvent(eventUUID: String) async throws {
        do {
            try await Firestore.firestore().collection("houseevents").document(eventUUID).delete()
        } catch {
            throw PostError.failedToDeleteEvent
        }
    }
    
    func checkIfUnderMaintenance() async throws {
        let document = try await Firestore.firestore().collection("settings").document("maintenance").getDocument(source: .server)
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let status = data["status"] as? Bool else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        withAnimation {
            self.isUnderMaintenance = status
        }
    }
    
    func checkIfAppForcesUpdates() async throws {
        let document = try await Firestore.firestore().collection("settings").document("force-updates").getDocument(source: .server)
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let status = data["status"] as? Bool else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        withAnimation {
            self.appForcesUpdates = status
        }
    }
    
    func fetchBlockedVersions() async throws -> [String] {
        let document = try await Firestore.firestore().collection("settings").document("versions-blocked").getDocument(source: .server)
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let versions = data["versions"] as? [String] else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        return versions
    }
    
    func fetchBlockedVersionsAndroid() async throws -> [String] {
        let document = try await Firestore.firestore().collection("settings").document("versions-blocked-android").getDocument(source: .server)
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let versions = data["versions"] as? [String] else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        return versions
    }
}
