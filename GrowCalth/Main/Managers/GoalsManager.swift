//
//  GoalsManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

class GoalsManager: ObservableObject {
    static let shared: GoalsManager = .init()
    
    @Published var stepsGoal: Int?
    @Published var distanceGoal: Double?
    
    @AppStorage("stepsGoalAppStorage", store: .standard) var stepsGoalAppStorage: Int = 5000
    @AppStorage("distanceGoalAppStorage", store: .standard) var distanceGoalAppStorage: Double = 4.0
    
    enum GoalTypes {
        case steps, distance
    }
    
    init() {
        refreshGoals()
    }
    
    func refreshGoals() {
        stepsGoal = stepsGoalAppStorage
        distanceGoal = distanceGoalAppStorage
    }
    
    func updateGoal(for typeToUpdate: GoalTypes, to newValue: Double) {
        switch typeToUpdate {
        case .steps:
            stepsGoalAppStorage = Int(newValue)
        case .distance:
            distanceGoalAppStorage = newValue
        }
        refreshGoals()
    }
}
