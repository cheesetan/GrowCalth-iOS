//
//  GrowCalth_iOSApp.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {

    let gcmMessageIDKey = "gcm.message_id"

    @ObservedObject var apnManager: ApplicationPushNotificationsManager = .shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Setting up Cloud Messaging

        Messaging.messaging().delegate = self

        // Setting up Notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {

        // Do something with message data here
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }

        // Print full message.
        print(userInfo)

        return UIBackgroundFetchResult.newData
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

    }
}

// Cloud Messaging
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        apnManager.setSelfFCMToken(fcmToken: fcmToken ?? "")
        Task {
            try await apnManager.updateFCMTokenInFirebase(fcmToken: fcmToken ?? "")
        }
        print(dataDict)
    }
}

// User Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // ...

        // Print full message.
        print(userInfo)

        // Change this to your preferred presentation option
        return [[.banner, .badge, .sound]]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        // ...

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print(userInfo)
    }
}

let GLOBAL_STEPS_PER_POINT: Int = 5000
let GLOBAL_GROWCALTH_START_DATE: Date = .init(timeIntervalSince1970: TimeInterval(1744128000))
let GLOBAL_ADMIN_EMAILS: [String] = ["admin@growcalth.com", "chay_yu_hung@s2021.ssts.edu.sg", "han_jeong_seu_caleb@s2021.ssts.edu.sg"]

@main
struct GrowCalth_iOSApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject var csManager = ColorSchemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(csManager)
                .preferredColorScheme(csManager.colorScheme == .automatic ? .none : csManager.colorScheme == .dark ? .dark : .light)
        }
    }
}
