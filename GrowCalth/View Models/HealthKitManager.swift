//
//  HealthKitManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import HealthKit
import FirebaseFirestore

@MainActor
class HealthKitManager: ObservableObject {

    private var healthStore = HKHealthStore()
    @Published var steps: Int? = nil
    @Published var distance: Double? = nil

    init() {
        Task {
            await requestAuthorization()
        }
    }

    enum HealthKitError: LocalizedError {
        case healthDataNotAvailable
        case authorizationFailed(Error?)
        case couldNotFindStepCountType
        case couldNotFindDistanceType
        case startDateIsNil
        case queryFailed(Error?)
        case noResults

        var errorDescription: String? {
            switch self {
            case .healthDataNotAvailable:
                return "Health data is not available on this device"
            case .authorizationFailed(let error):
                return "Authorization failed: \(error?.localizedDescription ?? "Unknown error")"
            case .couldNotFindStepCountType:
                return "Could not find Step Count Type"
            case .couldNotFindDistanceType:
                return "Could not find Distance Type"
            case .startDateIsNil:
                return "Start date is nil"
            case .queryFailed(let error):
                return "Query failed: \(error?.localizedDescription ?? "Unknown error")"
            case .noResults:
                return "No results found"
            }
        }
    }

    func requestAuthorization() async {
        let toReads = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        ])

        guard HKHealthStore.isHealthDataAvailable() else {
            print("health data not available!")
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: toReads)
            await fetchAllDatas()
        } catch {
            print("Authorization error: \(error)")
        }
    }

    func fetchAllDatas() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.readSteps()
            }
            group.addTask {
                await self.readDistance()
            }
        }
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

    func readSteps() async {
        do {
            let steps = try await performStepsQuery()
            self.steps = steps
        } catch {
            print("Failed to read steps: \(error)")
        }
    }

    private func performStepsQuery() async throws -> Int {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.couldNotFindStepCountType
        }

        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, Date() as NSDate)
        ])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum, .separateBySource]
            ) { _, hkResult, error in
                guard let hkResult = hkResult, let totalStepSumQuantity = hkResult.sumQuantity() else {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                var stepsToFilterOut = 0
                if let resultSources = hkResult.sources {
                    Task {
                        do {
                            let approvedBundleIdentifiers = try await self.fetchApprovedBundleIdentifiers()
                            resultSources.forEach { source in
                                if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                                    // Keep these steps
                                } else {
                                    if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                        stepsToFilterOut += Int(sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.count()))
                                    }
                                }
                            }

                            let finalSteps = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count())) - stepsToFilterOut
                            continuation.resume(returning: finalSteps)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    let finalSteps = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: finalSteps)
                }
            }

            healthStore.execute(query)
        }
    }

    func readDistance() async {
        do {
            let distance = try await performDistanceQuery()
            self.distance = distance
        } catch {
            print("Failed to read distance: \(error)")
        }
    }

    private func performDistanceQuery() async throws -> Double {
        guard let type = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.couldNotFindDistanceType
        }

        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "metadata.%K != true", HKMetadataKeyWasUserEntered),
            NSPredicate(format: "%K >= %@", HKPredicateKeyPathStartDate, newDate as NSDate),
            NSPredicate(format: "%K <= %@", HKPredicateKeyPathEndDate, Date() as NSDate)
        ])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum, .separateBySource]
            ) { _, hkResult, error in
                guard let hkResult = hkResult, let totalDistanceSumQuantity = hkResult.sumQuantity() else {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }

                var distanceToBeFilteredOut: Double = 0
                if let resultSources = hkResult.sources {
                    Task {
                        do {
                            let approvedBundleIdentifiers = try await self.fetchApprovedBundleIdentifiers()

                            resultSources.forEach { source in
                                if source.bundleIdentifier.contains("com.apple.health") || approvedBundleIdentifiers.contains(source.bundleIdentifier) {
                                    // Keep this distance
                                } else {
                                    if let sumOfFalseDataFromSpecificSource = hkResult.sumQuantity(for: source) {
                                        distanceToBeFilteredOut += sumOfFalseDataFromSpecificSource.doubleValue(for: HKUnit.meter())
                                    }
                                }
                            }

                            let finalDistance = (totalDistanceSumQuantity.doubleValue(for: HKUnit.meter()) - distanceToBeFilteredOut) / 1000
                            continuation.resume(returning: finalDistance)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } else {
                    let finalDistance = totalDistanceSumQuantity.doubleValue(for: HKUnit.meter()) / 1000
                    continuation.resume(returning: finalDistance)
                }
            }

            healthStore.execute(query)
        }
    }

    func fetchStepsForPointsCalculation(
        startDate: Date?,
        endDate: Date
    ) async throws -> (Int, [String]) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.couldNotFindStepCountType
        }

        guard let startDate else {
            throw HealthKitError.startDateIsNil
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
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
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
                    let finalStepCount = Int(totalStepSumQuantity.doubleValue(for: HKUnit.count()))
                    continuation.resume(returning: (finalStepCount, approvedBundleIdsUsed))
                }
            }

            healthStore.execute(query)
        }
    }
}
