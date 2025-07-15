//
//  GoalsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

@MainActor
final class GoalsManager: ObservableObject, Sendable {
    @Published var stepsGoal: Int?
    @Published var distanceGoal: Double?

    @AppStorage("stepsGoalAppStorage", store: .standard)
    private var stepsGoalAppStorage: Int = 5000

    @AppStorage("distanceGoalAppStorage", store: .standard)
    private var distanceGoalAppStorage: Double = 4.0

    init() {
        refreshGoals()
    }

    func refreshGoals() {
        withAnimation(.bouncy(extraBounce: 0.3)) {
            stepsGoal = stepsGoalAppStorage
            distanceGoal = distanceGoalAppStorage
        }
    }

    func updateGoal(for typeToUpdate: GoalType, to newValue: Double) {
        switch typeToUpdate {
        case .steps:
            stepsGoalAppStorage = Int(newValue)
        case .distance:
            distanceGoalAppStorage = newValue
        }
        refreshGoals()
    }
}
