//
//  GrowCalth_iOSApp.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import SwiftPersistence

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
        apnManager.updateFCMTokenInFirebase(fcmToken: fcmToken ?? "")
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

@main
struct GrowCalth_iOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @ObservedObject var csManager: ColorSchemeManager = .shared
    @Persistent("appInstalledDate") var appInstalledDate: Date = Date()
    @Persistent("lastPointsAwardedDate") private var lastPointsAwardedDate: Date? = nil
    
    init() {
        if let lastPointsAwardedDate = lastPointsAwardedDate {
            let growCalthStartDate = Date.init(timeIntervalSince1970: TimeInterval(1744128000))
            if lastPointsAwardedDate < growCalthStartDate {
                self.lastPointsAwardedDate = growCalthStartDate
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(csManager.colorScheme == .automatic ? .none : csManager.colorScheme == .dark ? .dark : .light)
                .onAppear {
                    let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                    appInstalledDate = cal.startOfDay(for: appInstalledDate)
                }
        }
    }
}
