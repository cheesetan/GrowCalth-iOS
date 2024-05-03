//
//  GrowCalthWidgetsBundle.swift
//  GrowCalthWidgetsExtension
//
//  Created by Tristan Chay on 10/2/24.
//

import WidgetKit
import SwiftUI
import FirebaseCore

@main
struct GrowCalthWidgetsBundle: WidgetBundle {
    
    init() {
        FirebaseApp.configure()
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        GrowCalthStepsWidget()
        GrowCalthDistanceWidget()
    }
}
