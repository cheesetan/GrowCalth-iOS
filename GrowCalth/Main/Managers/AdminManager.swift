//
//  AdminManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import SwiftUI
import FirebaseFirestore

class AdminManager: ObservableObject {
    static let shared: AdminManager = .init()
    
    @Published var bypassed = false
    @Published var isUnderMaintenance: Bool?
    @Published var appForcesUpdates: Bool?
    @Published var approvedEmails = ["admin@growcalth.com", "chay_yu_hung@s2021.ssts.edu.sg", "han_jeong_seu_caleb@s2021.ssts.edu.sg"]
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    init() {
        checkIfUnderMaintenance() { }
        checkIfAppForcesUpdates()
    }
    
    func postAnnouncement(
        title: String,
        description: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        if let email = authManager.email {
            Firestore.firestore().collection("Announcements").document().setData([
                "dateAdded": Date(),
                "header": title,
                "text": description,
                "name": email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased()
            ]) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
    
    func postEvent(
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        if let email = authManager.email {
            Firestore.firestore().collection("houseevents").document().setData([
                "dateAdded": Date(),
                "header": title,
                "desc": description,
                "venue": eventVenues,
                "date": eventDate.formatted(date: .long, time: .omitted),
                "name": email.components(separatedBy: "@")[0].components(separatedBy: "_").joined(separator: " ").uppercased()
            ]) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
    
    func editAnnouncement(
        announcementUUID: String,
        title: String,
        description: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("Announcements").document(announcementUUID).updateData([
            "header": title,
            "text": description
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func editEvent(
        eventUUID: String,
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("houseevents").document(eventUUID).updateData([
            "header": title,
            "desc": description,
            "venue": eventVenues,
            "date": eventDate.formatted(date: .long, time: .omitted)
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func deleteAnnouncement(
        announcementUUID: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("Announcements").document(announcementUUID).delete() { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func deleteEvent(
        eventUUID: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("houseevents").document(eventUUID).delete() { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func checkIfUnderMaintenance(_ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("settings").document("maintenance").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    withAnimation {
                        self.isUnderMaintenance = documentData["status"] as? Bool
                        completion()
                    }
                }
            } else {
                print("Document does not exist")
                completion()
            }
        }
    }
    
    func checkIfAppForcesUpdates() {
        Firestore.firestore().collection("settings").document("force-updates").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    withAnimation {
                        self.appForcesUpdates = documentData["status"] as? Bool
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func fetchBlockedVersions(
        _ completion: @escaping ((Result<[String]?, Error>) -> Void)
    ) {
        Firestore.firestore().collection("settings").document("versions-blocked").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    withAnimation {
                        completion(.success(documentData["versions"] as? [String]))
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func fetchBlockedVersionsAndroid(
        _ completion: @escaping ((Result<[String]?, Error>) -> Void)
    ) {
        Firestore.firestore().collection("settings").document("versions-blocked-android").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    withAnimation {
                        completion(.success(documentData["versions"] as? [String]))
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func developerBypass() {
        withAnimation {
            self.bypassed = true
        }
    }
    
    func changeBypassValue(to newValue: Bool) {
        withAnimation {
            self.bypassed = newValue
        }
    }
}
