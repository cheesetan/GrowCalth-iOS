//
//  HealthKitManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKit

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
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, Date() as NSDate)
        ])
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType, // the data type
            quantitySamplePredicate: predicate, // the predicate using the set startDate and endDate
            options: [.cumulativeSum] // to get the total steps
        ) {
            _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("failed to read step count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self.steps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    func readDistance() {
        guard let type = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            fatalError("Something went wrong retrieving quantity type distanceWalkingRunning")
        }
        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        
        let notUserEnteredPredicate = NSPredicate(format: "%K != true", HKMetadataKeyWasUserEntered)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, Date() as NSDate)
        ])

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: [.cumulativeSum]) { (query, statistics, error) in
            var value: Double = 0

            if error != nil {
                print("something went wrong")
            } else if let quantity = statistics?.sumQuantity() {
                value = quantity.doubleValue(for: HKUnit.meter())
            }
            DispatchQueue.main.async {
                self.distance = value / 1000
            }
        }
        
        healthStore.execute(query)
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
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, Date() as NSDate)
        ])
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType, // the data type
            quantitySamplePredicate: predicate, // the predicate using the set startDate and endDate
            options: [.cumulativeSum] // to get the total steps
        ) {
            _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("failed to read step count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                if let error = error {
                    completion(.failure(error))
                }
                return
            }
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(.success(steps))
        }
        
        healthStore.execute(query)
    }
}
