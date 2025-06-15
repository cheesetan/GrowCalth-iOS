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

internal enum APNSError: LocalizedError {
    case failedToFetchPrivateKeyFromFirestore
    case failedToDecodePrivateKey
    case jwtSigningError
    case httpError
    case failedToParseTokenResponse

    case failedToFetchFCMTokensFromFirestore

    case errorFindingSpecifiedFCMToken
    case errorDeletingSpecifiedFCMToken

    case errorUpdatingFCMToken

    var errorDescription: String? {
        switch self {
        case .failedToFetchPrivateKeyFromFirestore: "Failed to fetch private key from Firestore. Please try again later."
        case .failedToDecodePrivateKey: "Failed to decode private key. Please try again later."
        case .httpError: "A HTTP Error occured. Please try again later."
        case .jwtSigningError: "Failed to sign JWT. Please try again later."
        case .failedToParseTokenResponse: "Failed to parse token response. Please try again later."
        case .failedToFetchFCMTokensFromFirestore: "Failed to fetch FCM Tokens from Firestore. Please try again later."
        case .errorFindingSpecifiedFCMToken: "Failed to fetch specified FCM Token. Please try again later."
        case .errorDeletingSpecifiedFCMToken: "Failed to delete specified FCM Token. Please try again later."
        case .errorUpdatingFCMToken: "Failed to update your FCM Token. Please try again later."
        }
    }
}

class ApplicationPushNotificationsManager: ObservableObject {
    static let shared: ApplicationPushNotificationsManager = .init()
    
    @Published var selfFCMToken: String = ""
    
    func setSelfFCMToken(fcmToken: String) {
        self.selfFCMToken = fcmToken
    }

    func updateFCMTokenInFirebase(fcmToken: String) async throws {
        do {
            try await Firestore.firestore().collection("fcmTokens").document(UIDevice.current.identifierForVendor?.uuidString ?? "").setData([
                "token": fcmToken
            ])
        } catch {
            throw APNSError.errorUpdatingFCMToken
        }
    }

    func sendPushNotificationsToEveryone(title: String, subtitle: String, body: String) async throws {
        let token = try await getOAuthToken()
        let fcmTokens = try await fetchFCMTokensFromFirebase()

        // Use TaskGroup for concurrent execution with proper async handling
        await withTaskGroup(of: Void.self) { group in
            for fcmToken in fcmTokens {
                if fcmToken != self.selfFCMToken {
                    group.addTask {
                        do {
                            try await self.sendPushNotification(
                                accessToken: token,
                                fcmToken: fcmToken,
                                title: title,
                                subtitle: subtitle,
                                body: body
                            )
                        } catch {
                            print("Failed to send notification to token \(fcmToken): \(error)")
                        }
                    }
                }
            }
        }
    }

    internal func sendFCMTokenFetchRequest() async throws -> QuerySnapshot {
        do {
            return try await Firestore.firestore().collection("fcmTokens").getDocuments()
        } catch {
            throw APNSError.failedToFetchFCMTokensFromFirestore
        }
    }

    private func fetchFCMTokensFromFirebase() async throws -> [String] {
        let query = try await Firestore.firestore().collection("fcmTokens").getDocuments()
        let tokenArray = query.documents.map { document in
            document.data()["token"] as? String
        }
        return tokenArray.compactMap({$0})
    }
    
    func sendPushNotification(accessToken: String, fcmToken: String, title: String, subtitle: String, body: String) async throws {
        let url = URL(string: "https://fcm.googleapis.com/v1/projects/new-growcalth/messages:send")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let notificationData: [String: Any] = [
            "message": [
                "token": fcmToken,
                "notification": [
                    "title": subtitle,
                    "body": body
                ]
            ]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData, options: [])
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "InvalidResponse", code: 0, userInfo: nil)
            }

            let responseString = String(data: data, encoding: .utf8)
            print("Response: \(responseString ?? "")")

            // Check for failures - Fixed error handling for FCM v1 API
            if httpResponse.statusCode >= 400 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let json = json, let error = json["error"] as? [String: Any] {
                        let errorCode = error["code"] as? String ?? "unknown"
                        let errorMessage = error["message"] as? String ?? "Unknown error"

                        // Remove token for specific error codes that indicate invalid tokens
                        if errorCode == "INVALID_ARGUMENT" ||
                            errorCode == "NOT_FOUND" ||
                            errorCode == "UNREGISTERED" {
                            try await self.removeFailedFCMToken(fcmToken: fcmToken)
                        }

                        throw NSError(domain: "FCMError", code: httpResponse.statusCode,
                                      userInfo: ["message": errorMessage, "code": errorCode])
                    }
                } catch let parseError as NSError where parseError.domain != "FCMError" {
                    print("Error parsing error response JSON: \(parseError)")
                }

                // If we can't parse the error, still throw based on status code
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)
            }

        } catch {
            print("Error sending push notification: \(error)")
            throw error
        }
    }

    internal func fetchSpecifiedFCMTokenRequest(fcmToken: String) async throws -> QuerySnapshot {
        do {
            return try await Firestore.firestore().collection("fcmTokens").whereField("token", isEqualTo: fcmToken).getDocuments()
        } catch {
            throw APNSError.errorFindingSpecifiedFCMToken
        }
    }

    internal func removeSpecifiedFCMTokenRequest(documentID: String) async throws {
        do {
            try await Firestore.firestore().collection("fcmTokens").document(documentID).delete()
        } catch {
            throw APNSError.errorFindingSpecifiedFCMToken
        }
    }

    private func removeFailedFCMToken(fcmToken: String) async throws {
        let query = try await fetchSpecifiedFCMTokenRequest(fcmToken: fcmToken)
        for document in query.documents {
            try await removeSpecifiedFCMTokenRequest(documentID: document.documentID)
        }
    }

    internal func signJWT(jwt: JWT<GoogleClaims>, using signer: JWTSigner) throws -> String {
        do {
            var jwt = jwt
            return try jwt.sign(using: signer)
        } catch {
            print("❌ JWT signing error:", error)
            throw APNSError.jwtSigningError
        }
    }

    func getOAuthToken() async throws -> String {
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
        let privateKey = try await fetchPrivateKeyForOAuth()
        let base64Key = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\\n", with: "")

        guard let privateKeyData = Data(base64Encoded: base64Key) else {
            print("❌ Failed to decode private key")
            throw APNSError.failedToDecodePrivateKey
        }

        let signer = JWTSigner.rs256(privateKey: privateKeyData)
        let signedJWT = try signJWT(jwt: jwt, using: signer)

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(signedJWT)"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                print("❌ Failed to parse token response")
                throw APNSError.failedToParseTokenResponse
            }

            print("✅ Access token:", accessToken)
            return accessToken

        } catch {
            print("❌ HTTP error:", error)
            throw APNSError.httpError
        }
    }

    internal func sendRequestToFirestoreForToken() async throws -> DocumentSnapshot {
        do {
            let document = try await Firestore.firestore().collection("settings").document("private-key-for-oauth").getDocument(source: .server)
            return document
        } catch {
            throw APNSError.failedToFetchPrivateKeyFromFirestore
        }
    }

    private func fetchPrivateKeyForOAuth() async throws -> String {
        let document = try await sendRequestToFirestoreForToken()
        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }
        guard let data = document.data() else {
            throw FirestoreError.documentHasNoData
        }
        guard let key = data["key"] as? String else {
            throw FirestoreError.failedToGetSpecifiedField
        }
        return key
    }
}
