//
//  GrowCalth_iOSApp.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

@main
struct GrowCalth_iOSApp: App {
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    
    var body: some Scene {
        WindowGroup {
//            ContentView()
            AuthenticationView()
        }
    }
}
