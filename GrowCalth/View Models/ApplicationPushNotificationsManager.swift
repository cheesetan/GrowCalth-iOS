//
//  ApplicationPushNotificationsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 6/2/24.
//

import SwiftUI
import SwiftJWT
import FirebaseFirestore
import FirebaseMessaging

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
        self.getOAuthToken { token in
            if let token {
                self.fetchFCMTokensFromFirebase { fcmTokens in
                    fcmTokens.forEach { fcmToken in
                        if token != self.selfFCMToken {
                            self.sendPushNotification(
                                accessToken: token,
                                fcmToken: fcmToken,
                                title: title,
                                subtitle: subtitle,
                                body: body
                            )
                        }
                    }
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
    
    func sendPushNotification(accessToken: String, fcmToken: String, title: String, subtitle: String, body: String) {
        // Replace "YOUR_SERVER_KEY" with your actual FCM server key
        let url = URL(string: "https://fcm.googleapis.com/v1/projects/new-growcalth/messages:send")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Build the message payload
        let notificationData: [String: Any] = [
            "message": [
                "token": fcmToken,
                "notification": [
                    "title": subtitle,
//                    "subtitle": subtitle,
                    "body": body
                ],
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
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        if let json = json, let failureCount = json["failure"] as? Int {
                            if failureCount > 0 {
                                self.removeFailedFCMToken(fcmToken: fcmToken)
                            }
                        }
                    } catch {
                        print("errorMsg")
                    }
                }
            }
            
            task.resume()
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
    
    private func removeFailedFCMToken(fcmToken: String) {
        Firestore.firestore().collection("fcmTokens").whereField("token", isEqualTo: fcmToken).getDocuments { querySnapshot, error in
            if let error {
                print("Error finding FCM Token's document: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    Firestore.firestore().collection("fcmTokens").document(document.documentID).delete() { err in
                        if let error {
                            print("Error while deleting FCM Token's document: \(error)")
                        }
                    }
                }
            }
        }
    }

    func getOAuthToken(completion: @escaping (String?) -> Void) {
        let iat = Int(Date().timeIntervalSince1970)
        let exp = iat + 3600

        let claims = GoogleClaims(
            iss: "firebase-adminsdk-c0u9w@new-growcalth.iam.gserviceaccount.com",
            scope: "https://www.googleapis.com/auth/firebase.messaging",
            aud: "https://oauth2.googleapis.com/token",
            exp: exp,
            iat: iat
        )

        var jwt = JWT(claims: claims)

        // Clean up PEM format to raw base64 key
        fetchPrivateKeyForOAuth { result in
            switch result {
            case .success(let privateKey):
                let base64Key = privateKey
                    .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\\n", with: "")


                guard let privateKeyData = Data(base64Encoded: base64Key) else {
                    print("❌ Failed to decode private key")
                    completion(nil)
                    return
                }

                let signer = JWTSigner.rs256(privateKey: privateKeyData)

                do {
                    let signedJWT = try jwt.sign(using: signer)

                    var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
                    request.httpMethod = "POST"
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

                    let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(signedJWT)"
                    request.httpBody = body.data(using: .utf8)

                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        if let error = error {
                            print("❌ HTTP error:", error)
                            completion(nil)
                            return
                        }

                        guard let data = data,
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let accessToken = json["access_token"] as? String else {
                            print("❌ Failed to parse token response")
                            completion(nil)
                            return
                        }

                        print("✅ Access token:", accessToken)
                        completion(accessToken)
                    }

                    task.resume()

                } catch {
                    print("❌ JWT signing error:", error)
                    completion(nil)
                }
            case .failure(let failure):
                print(failure)
            }
        }
    }

    private func fetchPrivateKeyForOAuth(_ completion: @escaping (Result<String, Error>) -> ()) {
        Firestore.firestore().collection("settings").document("private-key-for-oauth").getDocument(source: .server) { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists {
                    if let documentData = document.data() {
                        completion(.success(documentData["key"] as! String))
                    }
                }
            }
        }
    }
}
