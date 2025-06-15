//
//  GoalsView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

@MainActor
struct GoalsView: View {

    @State private var stepsGoal: Int = 0
    @State private var distanceGoal: Double = 0

    @State private var timer: Timer?

    @EnvironmentObject var goalsManager: GoalsManager


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
            await refreshGoals()
        }
        .onAppear {
            loadInitialGoals()
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
                invalidateTimer()
            }

        // a long press gesture to activate timer and start increasing the goal
        let longPressGestureIncrease = LongPressGesture(minimumDuration: 0.2)
            .onEnded { _ in
                startIncrementTimer(for: goalType)
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
                invalidateTimer()
            }

        // a long press gesture to activate timer and start decreasing the goal
        let longPressGestureDecrease = LongPressGesture(minimumDuration: 0.2)
            .onEnded { _ in
                startDecrementTimer(for: goalType)
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

    // MARK: - Private Methods

    private func loadInitialGoals() {
        if let stepsGoal = goalsManager.stepsGoal {
            self.stepsGoal = stepsGoal
        }
        if let distanceGoal = goalsManager.distanceGoal {
            self.distanceGoal = distanceGoal
        }
    }

    private func refreshGoals() async {
        // Assuming goalsManager.refreshGoals() should be async
        // If it's not async, you can call it directly without await
        if let refreshMethod = goalsManager.refreshGoals as? () async -> Void {
            await refreshMethod()
        } else {
            goalsManager.refreshGoals()
        }

        // Update local state after refresh
        loadInitialGoals()
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func startIncrementTimer(for goalType: GoalType) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.increment(for: goalType)
            }
        }
    }

    private func startDecrementTimer(for goalType: GoalType) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.decrement(for: goalType)
            }
        }
    }

    private func decrementButtonColor(for goalType: GoalType) -> Color {
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

    private func increment(for goalType: GoalType) {
        switch goalType {
        case .steps:
            stepsGoal += 100
            updateGoalInManager(for: .steps, value: Double(stepsGoal))
        case .distance:
            distanceGoal += 0.5
            updateGoalInManager(for: .distance, value: distanceGoal)
        }
    }

    private func decrement(for goalType: GoalType) {
        switch goalType {
        case .steps:
            if stepsGoal - 100 > 0 {
                stepsGoal -= 100
            }
            updateGoalInManager(for: .steps, value: Double(stepsGoal))
        case .distance:
            if distanceGoal - 0.5 > 0 {
                distanceGoal -= 0.5
            }
            updateGoalInManager(for: .distance, value: distanceGoal)
        }
    }

    private func updateGoalInManager(for goalType: GoalType, value: Double) {
        // Wrap the goal manager update in a task to handle potential async operations
        Task { @MainActor in
            goalsManager.updateGoal(for: goalType, to: value)
        }
    }
}

#Preview {
    GoalsView()
        .environmentObject(GoalsManager()) // You'll need to provide a mock or real instance
}
