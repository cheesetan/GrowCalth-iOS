//
//  GoalsView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI
import WidgetKit

struct GoalsView: View {
    
    @State var stepsGoal: Int = 0
    @State var distanceGoal: Double = 0
    
    @State private var timer: Timer?
    
    @EnvironmentObject var goalsManager: GoalsManager
    
    enum GoalType {
        case steps, distance
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            stepsGoalView
            distanceGoalView
            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle("Goals")
        .refreshable {
            goalsManager.refreshGoals()
        }
        .onAppear {
            if let stepsGoal = goalsManager.stepsGoal {
                self.stepsGoal = stepsGoal
            }
            if let distanceGoal = goalsManager.distanceGoal {
                self.distanceGoal = distanceGoal
            }
        }
    }
    
    var stepsGoalView: some View {
        HStack {
            Spacer()
            Spacer()
            decrementButton(for: .steps)
            Spacer()
            stepsGoalCountView
            Spacer()
            incrementButton(for: .steps, color: .red)
            Spacer()
            Spacer()
        }
    }
    
    var distanceGoalView: some View {
        HStack {
            Spacer()
            Spacer()
            decrementButton(for: .distance)
            Spacer()
            distanceGoalCountView
            Spacer()
            incrementButton(for: .distance, color: .green)
            Spacer()
            Spacer()
        }
    }
    
    var stepsGoalCountView: some View {
        VStack {
            Text("\(Int(stepsGoal))")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.horizontal)
            Text("Steps")
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
    
    var distanceGoalCountView: some View {
        VStack {
            Text(String(format: "%.2f", distanceGoal))
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.horizontal)
            Text("km")
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
    
    @ViewBuilder
    func incrementButton(for goalType: GoalType, color: Color) -> some View {
        let releaseGesture = DragGesture(minimumDistance: 0)
            .onEnded { _ in
                self.timer?.invalidate()
            }
        
        // a long press gesture to activate timer and start increasing the proteinAmount
        let longPressGestureIncrease = LongPressGesture(minimumDuration: 0.2)
            .onEnded { value in
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                    increment(for: goalType)
                })
            }
        
        // a combined gesture that forces the user to long press before releasing for increasing the value
        let combinedIncrease = longPressGestureIncrease.sequenced(before: releaseGesture)
        
        Image(systemName: "plus.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 48)
            .foregroundColor(color)
            .background(.white)
            .mask(Circle())
            .onTapGesture {
                increment(for: goalType)
            }
            .gesture(combinedIncrease)
    }
    
    @ViewBuilder
    func decrementButton(for goalType: GoalType) -> some View {
        let releaseGesture = DragGesture(minimumDistance: 0)
            .onEnded { _ in
                self.timer?.invalidate()
            }
        // a long press gesture to activate timer and start decreasing the proteinAmount
        let longPressGestureDecrease = LongPressGesture(minimumDuration: 0.2)
            .onEnded { value in
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                    decrement(for: goalType)
                })
            }
        // a combined gesture that forces the user to long press before releasing for decreasing the value
        let combinedDecrease = longPressGestureDecrease.sequenced(before: releaseGesture)
        
        Image(systemName: "minus.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 48)
            .foregroundColor(decrementButtonColor(for: goalType))
            .background(.white)
            .mask(Circle())
            .onTapGesture {
                decrement(for: goalType)
            }
            .gesture(combinedDecrease)
    }
    
    func decrementButtonColor(for goalType: GoalType) -> Color {
        switch goalType {
        case .steps:
            if stepsGoal - 100 <= 0 {
                return .gray
            } else {
                return .red
            }
        case .distance:
            if distanceGoal - 0.5 <= 0 {
                return .gray
            } else {
                return .green
            }
        }
    }
    
    func increment(for goalType: GoalType) {
        switch goalType {
        case .steps:
            stepsGoal += 100
            goalsManager.updateGoal(for: .steps, to: Double(stepsGoal))
        case .distance:
            distanceGoal += 0.5
            goalsManager.updateGoal(for: .distance, to: distanceGoal)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func decrement(for goalType: GoalType) {
        switch goalType {
        case .steps:
            if stepsGoal - 100 > 0 {
                stepsGoal -= 100
            }
            goalsManager.updateGoal(for: .steps, to: Double(stepsGoal))
        case .distance:
            if distanceGoal - 0.5 > 0 {
                distanceGoal -= 0.5
            }
            goalsManager.updateGoal(for: .distance, to: distanceGoal)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    GoalsView()
}
