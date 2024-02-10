//
//  GrowCalthWidgetsBundle.swift
//  GrowCalthWidgetsExtension
//
//  Created by Tristan Chay on 10/2/24.
//

import WidgetKit
import SwiftUI

@main
struct GrowCalthWidgetsBundle: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        GrowCalthStepsWidget()
        GrowCalthDistanceWidget()
    }
}
