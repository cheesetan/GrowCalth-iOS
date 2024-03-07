//
//  HealthKitManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKit
import WidgetKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private var healthStore = HKHealthStore()
    @Published var steps: Int? = nil
    @Published var distance: Double? = nil 
    
    init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let toReads = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        ])
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("health data not available!")
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: toReads) {
            success, error in
            if success {
                self.fetchAllDatas()
            } else {
                print("\(String(describing: error))")
            }
        }
    }
    
    func fetchAllDatas() {
        readSteps()
        readDistance()
    }
    
    func readSteps() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, Date() as NSDate)
        ])
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType, // the data type
            quantitySamplePredicate: predicate, // the predicate using the set startDate and endDate
            options: [.cumulativeSum, .separateBySource] // to get the total steps
        ) {
            _, hkResult, error in
            guard let hkResult = hkResult, let totalStepSumQuantity = hkResult.sumQuantity() else {
                print("failed to read step count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                return
            }
            
            var stepsToFilterOut = 0
            if let resultSources = hkResult.sources {
                resultSources.forEach { source in
                    if source.bundleIdentifier == "com.apple.shortcuts" {
                        if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                            stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.steps = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut
            }
        }
        
        healthStore.execute(query)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func readDistance() {
        guard let type = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            fatalError("Something went wrong retrieving quantity type distanceWalkingRunning")
        }
        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, Date() as NSDate)
        ])

        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum, .separateBySource]
        ) { (_, hkResult, error) in
            guard let hkResult = hkResult, let totalDistanceSumQuantity = hkResult.sumQuantity() else {
                print("failed to read distance count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                return
            }
            
            var distanceToBeFilteredOut: Double = 0
            if let resultSources = hkResult.sources {
                resultSources.forEach { source in
                    if source.bundleIdentifier == "com.apple.shortcuts" {
                        if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                            distanceToBeFilteredOut += sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter())
                            print(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter()))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.distance = (totalDistanceSumQuantity.doubleValue(for: HKUnit.meter()) - distanceToBeFilteredOut) / 1000
            }
        }
        
        healthStore.execute(query)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func fetchStepsForPointsCalculation(
        startDate: Date,
        endDate: Date,
        _ completion: @escaping ((Result<Int, Error>) -> Void)
    ) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: startDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, endDate as NSDate)
        ])
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType, // the data type
            quantitySamplePredicate: predicate, // the predicate using the set startDate and endDate
            options: [.cumulativeSum, .separateBySource] // to get the total steps
        ) {
            _, hkResult, error in
            guard let hkResult = hkResult, let totalStepSumQuantity = hkResult.sumQuantity() else {
                print("failed to read step count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                if let error = error {
                    completion(.failure(error))
                }
                return
            }
            
            var stepsToFilterOut = 0
            if let resultSources = hkResult.sources {
                resultSources.forEach { source in
                    if source.bundleIdentifier == "com.apple.shortcuts" {
                        if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                            stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                        }
                    }
                }
            }
            
            completion(.success(Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut))
        }
        
        healthStore.execute(query)
    }
}
