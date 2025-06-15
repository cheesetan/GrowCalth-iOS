//
//  HealthKitManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKit
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
    
    func fetchApprovedBundleIdentifiers() async throws -> [String] {
        let document = try await Firestore.firestore().collection("settings").document("approved-bundleids").getDocument(source: .server)

        guard document.exists else {
            throw FirestoreError.documentDoesNotExist
        }

        guard let documentData = document.data() else {
            throw FirestoreError.documentHasNoData
        }

        guard let ids = documentData["ids"] as? [String] else {
            throw FirestoreError.failedToGetSpecifiedField
        }

        return ids
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
                Task {
                    let approvedBundleIdentifiers = try await self.fetchApprovedBundleIdentifiers()
                    resultSources.forEach { source in
                        if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {

                        } else {
                            if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                            }
                        }
                    }

                    self.steps = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut
                }
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
                Task {
                    let approvedBundleIdentifiers = try await self.fetchApprovedBundleIdentifiers()

                    resultSources.forEach { source in
                        if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                        } else {
                            if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                distanceToBeFilteredOut += sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter())
                                print(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter()))
                            }
                        }
                    }

                    self.distance = (totalDistanceSumQuantity.doubleValue(for: HKUnit.meter()) - distanceToBeFilteredOut) / 1000
                }
            }
        }
        
        healthStore.execute(query)
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
        endDate: Date
    ) async throws -> (Int, [String]) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw FetchStepsError.couldNotFindStepCountType
        }

        guard let startDate else {
            throw FetchStepsError.startDateIsNil
        }

        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: startDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, endDate as NSDate)
        ])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum, .separateBySource]
            ) { _, hkResult, error in
                guard let hkResult = hkResult, let totalStepSumQuantity = hkResult.sumQuantity() else {
                    print("failed to read step count: \(error?.localizedDescription ?? "UNKNOWN ERROR")")
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(domain: "HealthKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown HealthKit error"]))
                    }
                    return
                }

                var stepsToFilterOut = 0
                var approvedBundleIdsUsed: [String] = []

                if let resultSources = hkResult.sources {
                    Task {
                        do {
                            let approvedBundleIdentifiers = try await self.fetchApprovedBundleIdentifiers()

                            resultSources.forEach { source in
                                if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                                    approvedBundleIdsUsed.append(source.bundleIdentifier)
                                } else {
                                    if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                        stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                                    }
                                }
                            }

                            let finalStepCount = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut
                            continuation.resume(returning: (finalStepCount, approvedBundleIdsUsed))

                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    // No sources to filter, return total count
                    let finalStepCount = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: (finalStepCount, approvedBundleIdsUsed))
                }
            }

            healthStore.execute(query)
        }
    }
}
