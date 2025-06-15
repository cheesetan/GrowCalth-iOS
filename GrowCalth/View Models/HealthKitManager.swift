//
//  HealthKitManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKit
import WidgetKit
import FirebaseFirestore

class HealthKitManager: ObservableObject {
    
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
    
    func fetchApprovedBundleIdentifiers(_ completion: @escaping ((Result<[String], Error>) -> Void)) {
        Firestore.firestore().collection("settings").document("approved-bundleids").getDocument(source: .server) { (document, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                if let document = document, document.exists {
                    if let documentData = document.data() {
                        completion(.success(documentData["ids"] as! [String]))
                    }
                }
            }
        }
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
                self.fetchApprovedBundleIdentifiers { result in
                    switch result {
                    case .success(let approvedBundleIdentifiers):
                        resultSources.forEach { source in
                            if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                                
                            } else {
                                if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                    stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                                }
                            }
                        }
                        
                        Task {
                            self.steps = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }
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
                self.fetchApprovedBundleIdentifiers { result in
                    switch result {
                    case .success(let approvedBundleIdentifiers):
                        resultSources.forEach { source in
                            if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                            } else {
                                if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                    distanceToBeFilteredOut += sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter())
                                    print(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter()))
                                }
                            }
                        }
                        
                        Task {
                            self.distance = (totalDistanceSumQuantity.doubleValue(for: HKUnit.meter()) - distanceToBeFilteredOut) / 1000
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
        
        healthStore.execute(query)
        WidgetCenter.shared.reloadAllTimelines()
    }

    internal enum FetchStepsError: LocalizedError {
        case couldNotFindStepCountType
        case startDateIsNil

        var errorDescription: String? {
            switch self {
            case .couldNotFindStepCountType: return "Could not find Step Count Type."
            case .startDateIsNil: return "StartDate is a nil value"
            }
        }
    }

    func fetchStepsForPointsCalculation(
        startDate: Date?,
        endDate: Date,
        _ completion: @escaping ((Result<(Int, [String]), Error>) -> Void)
    ) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(FetchStepsError.couldNotFindStepCountType))
            return
        }

        guard let startDate else {
            completion(.failure(FetchStepsError.startDateIsNil))
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
            var approvedBundleIdsUsed: [String] = []

            if let resultSources = hkResult.sources {
                self.fetchApprovedBundleIdentifiers { result in
                    switch result {
                    case .success(let approvedBundleIdentifiers):
                        resultSources.forEach { source in
                            if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                                approvedBundleIdsUsed.append(source.bundleIdentifier)
                            } else {
                                if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                    stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                                }
                            }
                        }
                    case .failure(let failure):
                        completion(.failure(failure))
                    }
                }
            }

            completion(.success((
                Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut,
                approvedBundleIdsUsed
            )))
        }

        healthStore.execute(query)
    }
}
