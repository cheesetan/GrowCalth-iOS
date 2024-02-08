//
//  GrowCalthStepsWidget.swift
//  GrowCalthStepsWidget
//
//  Created by Tristan Chay on 8/2/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    @ObservedObject var hkManager: HealthKitManager = .shared
    @ObservedObject var goalsManager: GoalsManager = .shared
    
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), steps: 0, progress: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> ()) {
        
        hkManager.fetchAllDatas()
        goalsManager.refreshGoals()
        var entry = StepsEntry(date: Date(), steps: hkManager.steps, progress: CGFloat(0))
        withAnimation {
            if let steps = hkManager.steps, let stepsGoals = goalsManager.stepsGoal {
                entry = StepsEntry(date: Date(), steps: steps, progress: CGFloat(Double(steps) / Double(stepsGoals)))
            }
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        
        hkManager.fetchAllDatas()
        goalsManager.refreshGoals()
        var entry = StepsEntry(date: Date(), steps: hkManager.steps, progress: CGFloat(0))
        withAnimation {
            if let steps = hkManager.steps, let stepsGoals = goalsManager.stepsGoal {
                entry = StepsEntry(date: Date(), steps: steps, progress: CGFloat(Double(steps) / Double(stepsGoals)))
            }
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int?
    let progress: CGFloat
}

struct GrowCalthStepsWidgetEntryView : View {
    var entry: Provider.Entry
    
    let frame1: CGFloat = 135
        
    var body: some View {
        ZStack {
//            ActivityRingView(progress: entry.progress,
//                             ringRadius: 60.0,
//                             thickness: 10.0,
//                             startColor: Color(hex: 0xD3D3D3),
//                             endColor: Color(hex: 0x808080))
//            .frame(height: 350)
            Circle()
                .foregroundColor(.secondary)
                .frame(width: frame1, height: frame1)
            Circle()
                .foregroundColor(Color(hex: 0xF1EEE9))
                .frame(width: frame1 - 15, height: frame1 - 15)
            VStack {
                Text("\(entry.steps ?? 0)")
                    .foregroundColor(.black)
                    .fontWeight(.black)
                    .font(.system(size: 28.0))
                Text("steps")
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

struct GrowCalthStepsWidget: Widget {
    let kind: String = "GrowCalthStepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                GrowCalthStepsWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                GrowCalthStepsWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Steps")
        .description("Check how many steps you've walked today!")
    }
}
