//
//  ApplicationPushNotificationsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 6/2/24.
//

import SwiftUI
import FirebaseFirestore

class ApplicationPushNotificationsManager: ObservableObject {
    static let shared: ApplicationPushNotificationsManager = .init()
    
    @Published var selfFCMToken: String = ""
    
    func setSelfFCMToken(fcmToken: String) {
        self.selfFCMToken = fcmToken
    }

    func updateFCMTokenInFirebase(fcmToken: String) {
        Firestore.firestore().collection("fcmTokens").document(UIDevice.current.identifierForVendor?.uuidString ?? "").setData([
            "token": fcmToken
        ]) { err in
            if let err = err {
                print(err.localizedDescription)
            }
        }
    }
    
    func sendPushNotificationsToEveryone(title: String, subtitle: String, body: String) {
        self.fetchFCMTokensFromFirebase { tokens in
            tokens.forEach { token in
                if token != self.selfFCMToken {
                    self.sendPushNotification(fcmToken: token, title: title, subtitle: subtitle, body: body)
                }
            }
        }
    }
    
    private func fetchFCMTokensFromFirebase(_ completion: @escaping (([String]) -> Void)) {
        Firestore.firestore().collection("fcmTokens").getDocuments { (query: QuerySnapshot?, err) in
            if let err {
                print("Error getting documents: \(err)")
            } else {
                let tokenArray = query!.documents.map { $0.data()["token"] as! String }
                print("tokenArray = \(tokenArray)")
                completion(tokenArray)
            }
        }
    }
    
    private func sendPushNotification(fcmToken: String, title: String, subtitle: String, body: String) {
        // Replace "YOUR_SERVER_KEY" with your actual FCM server key
        let serverKey = ApplicationPushNotificationsManager.getServerKey()
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        let notificationData: [String: Any] = [
            "to": fcmToken,
            "notification": [
                "title": subtitle,
//                "subtitle": subtitle,
                "body": body
            ],
            "data": [
                "additionalDataKey": "additionalDataValue"
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData, options: [])
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Response: \(responseString ?? "")")
                }
            }
            
            task.resume()
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}
