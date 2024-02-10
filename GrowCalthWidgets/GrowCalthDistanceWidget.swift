//
//  GrowCalthDistanceWidget.swift
//  GrowCalthStepsWidgetExten
//
//  Created by Tristan Chay on 8/2/24.
//

import WidgetKit
import SwiftUI

struct GrowCalthDistanceWidgetProvider: TimelineProvider {
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    @ObservedObject var goalsManager: GoalsManager = .shared
    
    func placeholder(in context: Context) -> DistanceEntry {
        DistanceEntry(date: Date(), distance: 0, progress: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DistanceEntry) -> ()) {
        
        hkManager.fetchAllDatas()
        goalsManager.refreshGoals()
//        print("snapshot \(goalsManager.distanceGoal)")
        var entry = DistanceEntry(date: Date(), distance: hkManager.distance, progress: CGFloat(0))
        withAnimation {
            if let distance = hkManager.distance, let distanceGoals = goalsManager.distanceGoal {
                entry = DistanceEntry(date: Date(), distance: distance, progress: CGFloat(Double(distance) / Double(distanceGoals)))
            }
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        
        hkManager.fetchAllDatas()
        goalsManager.refreshGoals()
//        print("timeline \(goalsManager.distanceGoal)")
        var entry = DistanceEntry(date: Date(), distance: hkManager.distance, progress: CGFloat(0))
        withAnimation {
            if let distance = hkManager.distance, let distanceGoals = goalsManager.distanceGoal {
                entry = DistanceEntry(date: Date(), distance: distance, progress: CGFloat(Double(distance) / Double(distanceGoals)))
            }
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct DistanceEntry: TimelineEntry {
    let date: Date
    let distance: Double?
    let progress: CGFloat
}

struct GrowCalthDistanceWidgetEntryView : View {
    var entry: GrowCalthDistanceWidgetProvider.Entry
    
    let frame1: CGFloat = 135
        
    var body: some View {
        ZStack {
            ActivityRingView(progress: entry.progress,
                             ringRadius: 60.0,
                             thickness: 15.0,
                             startColor: Color(hex: 0xD3D3D3),
                             endColor: Color(hex: 0x808080))
            .frame(height: 350)
//            Circle()
//                .foregroundColor(.secondary)
//                .frame(width: frame1, height: frame1)
            Circle()
                .foregroundColor(Color(hex: 0xF1EEE9))
                .frame(width: frame1 - 15, height: frame1 - 15)
            VStack {
                Text("\(entry.distance ?? 0.00, specifier: "%.2f")")
                    .minimumScaleFactor(0.1)
                    .foregroundColor(.black)
                    .fontWeight(.black)
                    .font(.system(size: 28.0))
                    .multilineTextAlignment(.center)
                
                Text("km")
                    .foregroundColor(.gray)
                    .font(.system(size: 15.0))
            }
            .padding()
//            VStack {
//                Spacer()
//                Text("Last updated: \(entry.date.formatted(date: .numeric, time: .shortened))")
//                    .minimumScaleFactor(0.1)
//                    .font(.caption2)
//                    .lineLimit(1)
//                    .multilineTextAlignment(.center)
//            }
//            .padding(.bottom, -12)
        }
    }
}

struct GrowCalthDistanceWidget: Widget {
    let kind: String = "GrowCalthDistanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GrowCalthDistanceWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                GrowCalthDistanceWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                GrowCalthDistanceWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Distance")
        .description("Check how far you've walked today!")
    }
}
