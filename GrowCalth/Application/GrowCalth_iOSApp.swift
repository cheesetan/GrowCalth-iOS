//
//  GrowCalth_iOSApp.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseCore
import SwiftPersistence

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct GrowCalth_iOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @ObservedObject var csManager: ColorSchemeManager = .shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(csManager.colorScheme == .automatic ? .none : csManager.colorScheme == .dark ? .dark : .light)
        }
    }
}
