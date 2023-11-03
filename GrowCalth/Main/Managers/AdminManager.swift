//
//  AdminManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import Foundation
import FirebaseFirestore

class AdminManager: ObservableObject {
    static let shared: AdminManager = .init()
    
    @Published var approvedEmails = ["admin@growcalth.com", "chay_yu_hung@s2021.ssts.edu.sg", "han_jeong_seu_caleb@s2021.ssts.edu.sg"]
    
    func postAnnouncement(
        title: String,
        description: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("Announcements").document().setData([
            "dateAdded": Date(),
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
    
    func postEvent(
        title: String,
        description: String,
        eventDate: Date,
        eventVenues: String,
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Firestore.firestore().collection("houseevents").document().setData([
            "dateAdded": Date(),
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
    
    func editEvent() {
        
    }
    
    func deleteAnnouncement() {
        
    }
    
    func deleteEvent() {
        
    }
}
