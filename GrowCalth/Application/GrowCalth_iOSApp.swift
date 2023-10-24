//
//  Growcalth_iOSApp.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

@main
struct Growcalth_iOSApp: App {
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
