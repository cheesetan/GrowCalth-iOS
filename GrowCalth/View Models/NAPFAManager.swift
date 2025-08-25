//
//  NAPFAManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 3/1/24.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class NAPFAManager: ObservableObject {
    
    @AppStorage("levelSelection", store: .standard) var levelSelection: String = NAPFALevel.secondary2.rawValue
    @AppStorage("yearSelection", store: .standard) var year: Int = Calendar.current.component(.year, from: Date())
    
    @Published internal var sitUps: [NAPFAResults] = []
    @Published internal var sitAndReach: [NAPFAResults] = []
    @Published internal var sbj: [NAPFAResults] = []
    @Published internal var shuttleRun: [NAPFAResults] = []
    @Published internal var inclinedPullUps: [NAPFAResults] = []
    @Published internal var pullUps: [NAPFAResults] = []
    @Published internal var twoPointFourKm: [NAPFAResults] = []
    
    @Published internal var internalData: [NAPFAResults] = []
    @Published var data: [String : [NAPFAResults]] = [:]
    
    enum NAPFAError: LocalizedError {
        case documentNotFound
        case invalidDocumentData
        case firebaseError(Error)
        case invalidLevel
        
        var errorDescription: String? {
            switch self {
            case .documentNotFound:
                return "NAPFA document not found for the specified year."
            case .invalidDocumentData:
                return "Invalid document data received from Firebase."
            case .firebaseError(let error):
                return "Firebase error: \(error.localizedDescription)"
            case .invalidLevel:
                return "Invalid NAPFA level selected."
            }
        }
    }

    private let authManager: AuthenticationManager

    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        Task {
            do {
                try await self.fetchAllData(for: self.year)
            } catch {
                print("Error fetching initial data: \(error)")
            }
        }
    }
    
    func fetchAllData(for year: Int) async throws {
        self.internalData = []
        
        // Execute all main fetches concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.fetchSitUps(for: year)
            }
            group.addTask {
                try await self.fetchSitAndReach(for: year)
            }
            group.addTask {
                try await self.fetchSBJ(for: year)
            }
            group.addTask {
                try await self.fetchShuttleRun(for: year)
            }
            group.addTask {
                try await self.fetchInclinedPullUps(for: year)
            }
            group.addTask {
                try await self.fetchTwoPointFourKm(for: year)
            }
            
            // Wait for all tasks to complete
            for try await _ in group { }
        }
        
        guard let level = NAPFALevel(rawValue: self.levelSelection) else {
            throw NAPFAError.invalidLevel
        }
        
        if level == .secondary2 {
            self.pullUps = []
        } else if level == .secondary4 {
            try await fetchPullUps(for: year)
        }
        
        sortAndAddToData()
        try await updateCache(for: year)
    }
    
    func updateValues(
        sitUps: [NAPFAResults],
        sitAndReach: [NAPFAResults],
        sbj: [NAPFAResults],
        shuttleRun: [NAPFAResults],
        inclinedPullUps: [NAPFAResults],
        pullUps: [NAPFAResults],
        twoPointFourKm: [NAPFAResults]
    ) {
        self.sitUps = sitUps.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.sitAndReach = sitAndReach.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.sbj = sbj.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.shuttleRun = shuttleRun.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.inclinedPullUps = inclinedPullUps.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.pullUps = pullUps.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        self.twoPointFourKm = twoPointFourKm.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        
        insertHeaders()
    }
    
    private func insertHeaders() {
        if !self.sitUps.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sitUps.insert(NAPFAResults(header: "Sit Ups"), at: 0)
        }
        if !self.sitAndReach.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sitAndReach.insert(NAPFAResults(header: "Sit And Reach"), at: 0)
        }
        if !self.sbj.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sbj.insert(NAPFAResults(header: "Standing Broad Jump"), at: 0)
        }
        if !self.shuttleRun.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.shuttleRun.insert(NAPFAResults(header: "Shuttle Run"), at: 0)
        }
        if !self.inclinedPullUps.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            guard let level = NAPFALevel(rawValue: self.levelSelection) else { return }
            if level == .secondary2 {
                self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups"), at: 0)
            } else if level == .secondary4 {
                self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups (Female)"), at: 0)
            }
        }
        if !self.pullUps.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.pullUps.insert(NAPFAResults(header: "Pull Ups (Male)"), at: 0)
        }
        if !self.twoPointFourKm.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.twoPointFourKm.insert(NAPFAResults(header: "2.4km Run"), at: 0)
        }
    }
    
    func updateValuesInFirebase() async throws {
        guard let level = NAPFALevel(rawValue: levelSelection) else {
            throw NAPFAError.invalidLevel
        }
        
        let data: [String: Any] = [
            "2.4km": stringifyNAPFAResultArray(self.twoPointFourKm),
            "inclinedpullups": stringifyNAPFAResultArray(self.inclinedPullUps),
            "pullups": stringifyNAPFAResultArray(self.pullUps),
            "sbj": stringifyNAPFAResultArray(self.sbj),
            "shuttle": stringifyNAPFAResultArray(self.shuttleRun),
            "sitandreach": stringifyNAPFAResultArray(self.sitAndReach),
            "situps": stringifyNAPFAResultArray(self.sitUps)
        ]
        
        do {
            guard let schoolCode = authManager.schoolCode else { throw NAPFAError.documentNotFound }
            try await Firestore.firestore()
                .collection("schools")
                .document(schoolCode)
                .collection("napfa")
                .document("\(level.firebaseCode)-\(String(year))")
                .setData(data)
        } catch {
            throw NAPFAError.firebaseError(error)
        }
    }
    
    internal func stringifyNAPFAResultArray(_ data: [NAPFAResults]) -> [String] {
        return data.compactMap { value in
            guard value.header.isEmpty else { return nil }
            return "\(value.rank)___\(value.name)___\(value.className)___\(value.result)"
        }
    }
    
    func updateCache(for year: Int) async throws {
        guard let level = NAPFALevel(rawValue: levelSelection) else {
            throw NAPFAError.invalidLevel
        }
        data["\(level.firebaseCode)-\(String(year))"] = internalData
    }
    
    func sortAndAddToData() {
        self.internalData = []
        self.internalData.append(contentsOf: twoPointFourKm)
        self.internalData.append(contentsOf: inclinedPullUps)
        
        if let level = NAPFALevel(rawValue: levelSelection), level == .secondary4 {
            self.internalData.append(contentsOf: pullUps)
        }
        
        self.internalData.append(contentsOf: shuttleRun)
        self.internalData.append(contentsOf: sitAndReach)
        self.internalData.append(contentsOf: sitUps)
        self.internalData.append(contentsOf: sbj)
    }
    
    func getDocumentData(for year: Int) async throws -> [String : [String]] {
        return try await self.fetchDocument(for: year)
    }
    
    nonisolated internal func fetchDocument(for year: Int) async throws -> [String : [String]] {
        guard let level = await NAPFALevel(rawValue: levelSelection) else {
            throw NAPFAError.invalidLevel
        }
        
        do {
            guard let schoolCode = await authManager.schoolCode else { throw NAPFAError.documentNotFound }

            let document = try await Firestore.firestore()
                .collection("schools")
                .document(schoolCode)
                .collection("napfa")
                .document("\(level.firebaseCode)-\(String(year))")
                .getDocument()
            
            guard document.exists else {
                throw NAPFAError.documentNotFound
            }
            
            guard let data = document.data() as? [String: [String]] else {
                throw NAPFAError.invalidDocumentData
            }
            
            return data
        } catch {
            if error is NAPFAError {
                throw error
            } else {
                throw NAPFAError.firebaseError(error)
            }
        }
    }
    
    private func parseNAPFAResults(from fieldArray: [String], header: String) -> [NAPFAResults] {
        let results = fieldArray.compactMap { value -> NAPFAResults? in
            let parts = value.components(separatedBy: "___")
            guard parts.count == 4 else { return nil }
            
            return NAPFAResults(
                rank: Int(parts[0]) ?? 0,
                name: String(parts[1]),
                className: String(parts[2]),
                result: String(parts[3])
            )
        }.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
        
        if !results.filter({ $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            var finalResults = results
            finalResults.insert(NAPFAResults(header: header), at: 0)
            return finalResults
        }
        
        return results
    }
    
    internal func fetchSitUps(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["situps"] ?? []
            self.sitUps = parseNAPFAResults(from: fieldArray, header: "Sit Ups")
        } catch {
            self.sitUps = []
            if !(error is NAPFAError) {
                print("Error fetching sit ups: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchSitAndReach(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["sitandreach"] ?? []
            self.sitAndReach = parseNAPFAResults(from: fieldArray, header: "Sit And Reach")
        } catch {
            self.sitAndReach = []
            if !(error is NAPFAError) {
                print("Error fetching sit and reach: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchSBJ(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["sbj"] ?? []
            self.sbj = parseNAPFAResults(from: fieldArray, header: "Standing Broad Jump")
        } catch {
            self.sbj = []
            if !(error is NAPFAError) {
                print("Error fetching SBJ: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchShuttleRun(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["shuttle"] ?? []
            self.shuttleRun = parseNAPFAResults(from: fieldArray, header: "Shuttle Run")
        } catch {
            self.shuttleRun = []
            if !(error is NAPFAError) {
                print("Error fetching shuttle run: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchInclinedPullUps(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["inclinedpullups"] ?? []
            let header: String
            
            guard let level = NAPFALevel(rawValue: self.levelSelection) else {
                throw NAPFAError.invalidLevel
            }
            
            if level == .secondary2 {
                header = "Inclined Pull Ups"
            } else if level == .secondary4 {
                header = "Inclined Pull Ups (Female)"
            } else {
                header = "Inclined Pull Ups"
            }
            
            self.inclinedPullUps = parseNAPFAResults(from: fieldArray, header: header)
        } catch {
            self.inclinedPullUps = []
            if !(error is NAPFAError) {
                print("Error fetching inclined pull ups: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchPullUps(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["pullups"] ?? []
            self.pullUps = parseNAPFAResults(from: fieldArray, header: "Pull Ups (Male)")
        } catch {
            self.pullUps = []
            if !(error is NAPFAError) {
                print("Error fetching pull ups: \(error)")
            }
            throw error
        }
    }
    
    internal func fetchTwoPointFourKm(for year: Int) async throws {
        do {
            let documentData = try await getDocumentData(for: year)
            
            let fieldArray = documentData["2.4km"] ?? []
            self.twoPointFourKm = parseNAPFAResults(from: fieldArray, header: "2.4km Run")
        } catch {
            self.twoPointFourKm = []
            if !(error is NAPFAError) {
                print("Error fetching 2.4km run: \(error)")
            }
            throw error
        }
    }
}
