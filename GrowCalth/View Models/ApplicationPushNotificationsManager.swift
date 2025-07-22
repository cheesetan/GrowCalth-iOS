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

internal enum APNSError: LocalizedError, Sendable {
    case failedToFetchPrivateKeyFromFirestore
    case failedToDecodePrivateKey
    case jwtSigningError
    case httpError(Int, String?)
    case failedToParseTokenResponse
    case failedToFetchFCMTokensFromFirestore
    case errorFindingSpecifiedFCMToken
    case errorDeletingSpecifiedFCMToken
    case errorUpdatingFCMToken
    case invalidResponse
    case fcmError(code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .failedToFetchPrivateKeyFromFirestore:
            return "Failed to fetch private key from Firestore. Please try again later."
        case .failedToDecodePrivateKey:
            return "Failed to decode private key. Please try again later."
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message ?? "Unknown error"). Please try again later."
        case .jwtSigningError:
            return "Failed to sign JWT. Please try again later."
        case .failedToParseTokenResponse:
            return "Failed to parse token response. Please try again later."
        case .failedToFetchFCMTokensFromFirestore:
            return "Failed to fetch FCM Tokens from Firestore. Please try again later."
        case .errorFindingSpecifiedFCMToken:
            return "Failed to fetch specified FCM Token. Please try again later."
        case .errorDeletingSpecifiedFCMToken:
            return "Failed to delete specified FCM Token. Please try again later."
        case .errorUpdatingFCMToken:
            return "Failed to update your FCM Token. Please try again later."
        case .invalidResponse:
            return "Invalid response received. Please try again later."
        case .fcmError(let code, let message):
            return "FCM Error (\(code)): \(message)"
        }
    }
}

@MainActor
class ApplicationPushNotificationsManager: ObservableObject {
    static let shared: ApplicationPushNotificationsManager = .init()

    @Published var selfFCMToken: String = ""

    init() {}

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
        let fcmTokens = try await getFCMTokens()

        // Use TaskGroup for concurrent execution with proper async handling
        try await withThrowingTaskGroup(of: Void.self) { group in
            for fcmToken in fcmTokens {
                if fcmToken != self.selfFCMToken {
                    group.addTask {
                        try await self.sendPushNotification(
                            accessToken: token,
                            fcmToken: fcmToken,
                            title: title,
                            subtitle: subtitle,
                            body: body
                        )
                    }
                }
            }

            // Wait for all tasks to complete and handle any errors
            for try await _ in group {
                // Individual task completion
            }
        }
    }

    private func getFCMTokens() async throws -> [String] {
        return try await self.fetchFCMTokensFromFirebase()
    }

    nonisolated internal func fetchFCMTokensFromFirebase() async throws -> [String] {
        do {
            let query = try await Firestore.firestore().collection("fcmTokens").getDocuments()
            let tokenArray = query.documents.compactMap { document in
                document.data()["token"] as? String
            }
            return tokenArray
        } catch {
            throw APNSError.failedToFetchFCMTokensFromFirestore
        }
    }

    func sendPushNotification(accessToken: String, fcmToken: String, title: String, subtitle: String, body: String) async throws {
        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/new-growcalth/messages:send") else {
            throw APNSError.httpError(0, "Invalid URL")
        }

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
                throw APNSError.invalidResponse
            }

            let responseString = String(data: data, encoding: .utf8)
            print("Response: \(responseString ?? "")")

            // Check for failures - Enhanced error handling for FCM v1 API
            if httpResponse.statusCode >= 400 {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let error = json["error"] as? [String: Any] {
                        let errorCode = error["code"] as? String ?? "unknown"
                        let errorMessage = error["message"] as? String ?? "Unknown error"

                        // Remove token for specific error codes that indicate invalid tokens
                        if errorCode == "INVALID_ARGUMENT" ||
                            errorCode == "NOT_FOUND" ||
                            errorCode == "UNREGISTERED" {
                            try await self.removeFailedFCMToken(fcmToken: fcmToken)
                        }

                        throw APNSError.fcmError(code: errorCode, message: errorMessage)
                    }
                } catch let parseError where parseError is APNSError {
                    throw parseError
                } catch {
                    print("Error parsing error response JSON: \(error)")
                }

                // If we can't parse the error, still throw based on status code
                throw APNSError.httpError(httpResponse.statusCode, responseString)
            }

        } catch let error as APNSError {
            throw error
        } catch {
            print("Error sending push notification: \(error)")
            throw APNSError.httpError(0, error.localizedDescription)
        }
    }

    private func removeFailedFCMToken(fcmToken: String) async throws {
        let documentsIds = try await fetchSpecifiedFCMTokenDocumentIdsRequest(fcmToken: fcmToken)
        for id in documentsIds {
            try await removeSpecifiedFCMTokenRequest(documentID: id)
        }
    }

    nonisolated internal func fetchSpecifiedFCMTokenDocumentIdsRequest(
        fcmToken: String
    ) async throws -> [String] {
        do {
            let query = try await Firestore.firestore().collection("fcmTokens").whereField("token", isEqualTo: fcmToken).getDocuments()

            var documentIds: [String] = []
            for document in query.documents {
                documentIds.append(document.documentID)
            }
            return documentIds
        } catch {
            throw APNSError.errorFindingSpecifiedFCMToken
        }
    }

    internal func removeSpecifiedFCMTokenRequest(documentID: String) async throws {
        do {
            try await Firestore.firestore().collection("fcmTokens").document(documentID).delete()
        } catch {
            throw APNSError.errorDeletingSpecifiedFCMToken
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

        let jwt = JWT(claims: claims)

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

        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw APNSError.httpError(0, "Invalid OAuth URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(signedJWT)"
        request.httpBody = body.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APNSError.invalidResponse
            }

            if httpResponse.statusCode >= 400 {
                let responseString = String(data: data, encoding: .utf8)
                throw APNSError.httpError(httpResponse.statusCode, responseString)
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                print("❌ Failed to parse token response")
                throw APNSError.failedToParseTokenResponse
            }

            print("✅ Access token obtained successfully")
            return accessToken

        } catch let error as APNSError {
            throw error
        } catch {
            print("❌ HTTP error:", error)
            throw APNSError.httpError(0, error.localizedDescription)
        }
    }

    nonisolated internal func fetchPrivateKeyForOAuth() async throws -> String {
        do {
            let document = try await Firestore.firestore().collection("settings").document("private-key-for-oauth").getDocument(source: .server)

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
        } catch {
            throw APNSError.failedToFetchPrivateKeyFromFirestore
        }
    }
}
