//
//  AdminManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class AdminManager: ObservableObject, Sendable {
    @Published var isUnderMaintenance: Bool?
    @Published var appForcesUpdates: Bool?

    private let authManager: AuthenticationManager

    init(isUnderMaintenance: Bool? = nil, appForcesUpdates: Bool? = nil, authManager: AuthenticationManager) {
        self.isUnderMaintenance = isUnderMaintenance
        self.appForcesUpdates = appForcesUpdates
        self.authManager = authManager

        Task {
            await initializeSettings()
        }
    }

    private func initializeSettings() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.checkIfUnderMaintenance()
                }
                group.addTask {
                    try await self.checkIfAppForcesUpdates()
                }

                // Wait for all tasks to complete
                for try await _ in group { }
            }
        } catch {
            print("Failed to initialize settings: \(error)")
        }
    }

    func postAnnouncement(title: String, description: String) async throws {
        guard let email = authManager.email else {
            throw PostError.failedToGetEmail
        }

        let authorName = email.components(separatedBy: "@")[0]
            .components(separatedBy: "_")
            .joined(separator: " ")
            .uppercased()

        let data: [String: Any] = [
            "dateAdded": Date(),
            "header": title,
            "text": description,
            "name": authorName
        ]

        do {
            try await Firestore.firestore()
                .collection("Announcements")
                .document()
                .setData(data)
        } catch {
            throw PostError.failedToPostAnnouncement
        }
    }

    func postEvent(
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String
    ) async throws {
        guard let email = authManager.email else {
            throw PostError.failedToGetEmail
        }

        let authorName = email.components(separatedBy: "@")[0]
            .components(separatedBy: "_")
            .joined(separator: " ")
            .uppercased()

        let data: [String: Any] = [
            "dateAdded": Date(),
            "header": title,
            "desc": description,
            "venue": eventVenues,
            "date": eventDate.formatted(date: .long, time: .omitted),
            "name": authorName
        ]

        do {
            try await Firestore.firestore()
                .collection("houseevents")
                .document()
                .setData(data)
        } catch {
            throw PostError.failedToPostEvent
        }
    }

    func editAnnouncement(announcementUUID: String, title: String, description: String) async throws {
        let data: [String: Any] = [
            "header": title,
            "text": description
        ]

        do {
            try await Firestore.firestore()
                .collection("Announcements")
                .document(announcementUUID)
                .updateData(data)
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
        let data: [String: Any] = [
            "header": title,
            "desc": description,
            "venue": eventVenues,
            "date": eventDate.formatted(date: .long, time: .omitted)
        ]

        do {
            try await Firestore.firestore()
                .collection("houseevents")
                .document(eventUUID)
                .updateData(data)
        } catch {
            throw PostError.failedToUpdateEvent
        }
    }

    func deleteAnnouncement(announcementUUID: String) async throws {
        do {
            try await Firestore.firestore()
                .collection("Announcements")
                .document(announcementUUID)
                .delete()
        } catch {
            throw PostError.failedToDeleteAnnouncement
        }
    }

    func deleteEvent(eventUUID: String) async throws {
        do {
            try await Firestore.firestore()
                .collection("houseevents")
                .document(eventUUID)
                .delete()
        } catch {
            throw PostError.failedToDeleteEvent
        }
    }

    func checkIfUnderMaintenance() async throws {
        let status = try await self.fetchMaintenanceStatus()

        await MainActor.run {
            withAnimation {
                self.isUnderMaintenance = status
            }
        }
    }

    nonisolated internal func fetchMaintenanceStatus() async throws -> Bool {
        let document = try await Firestore.firestore()
            .collection("settings")
            .document("maintenance")
            .getDocument(source: .server)

        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }

        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }

        guard let status = data["status"] as? Bool else {
            throw FirestoreError.failedToGetSpecifiedField
        }

        return status
    }

    func checkIfAppForcesUpdates() async throws {
        let status = try await self.fetchAppForcesUpdatesStatus()

        await MainActor.run {
            withAnimation {
                self.appForcesUpdates = status
            }
        }
    }

    nonisolated internal func fetchAppForcesUpdatesStatus() async throws -> Bool {
        let document = try await Firestore.firestore()
            .collection("settings")
            .document("force-updates")
            .getDocument(source: .server)

        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }

        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }

        guard let status = data["status"] as? Bool else {
            throw FirestoreError.failedToGetSpecifiedField
        }

        return status
    }

    func checkBlockediOSVersions() async throws -> [String] {
        try await self.fetchBlockediOSVersions()
    }

    nonisolated internal func fetchBlockediOSVersions() async throws -> [String] {
        let document = try await Firestore.firestore()
            .collection("settings")
            .document("versions-blocked")
            .getDocument(source: .server)

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


    func checkBlockedAndroidVersions() async throws -> [String] {
        return try await self.fetchBlockedAndroidVersions()
    }

    nonisolated internal func fetchBlockedAndroidVersions() async throws -> [String] {
        let document = try await Firestore.firestore()
            .collection("settings")
            .document("versions-blocked-android")
            .getDocument(source: .server)

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
