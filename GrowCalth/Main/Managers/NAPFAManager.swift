//
//  NAPFAManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 3/1/24.
//

import SwiftUI
import FirebaseFirestore

struct NAPFAResults: Identifiable, Codable, Equatable {
    var id = UUID()
    var header: String = ""
    var rank: Int = -1
    var name: String = ""
    var className: String = ""
    var result: String = ""
}

enum NAPFALevel: String, Codable, CaseIterable {
    case secondary2 = "Secondary 2"
    case secondary4 = "Secondary 4"
    
    var firebaseCode: String {
        switch self {
        case .secondary2: return "s2"
        case .secondary4: return "s4"
        }
    }

    var icon: String {
        switch self {
        case .secondary2: return "2.circle.fill"
        case .secondary4: return "4.circle.fill"
        }
    }
}

class NAPFAManager: ObservableObject {
    static let shared: NAPFAManager = .init()
    
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
    
    init() {
        self.fetchAllData(for: self.year) {}
    }
    
    func fetchAllData(for year: Int, _ completion: @escaping (() -> Void)) {
        self.internalData = []
        self.fetchSitUps(for: year) {
            self.fetchSitAndReach(for: year) {
                self.fetchSBJ(for: year) {
                    self.fetchShuttleRun(for: year) {
                        self.fetchInclinedPullUps(for: year) {
                            self.fetchTwoPointFourKm(for: year) {
                                if NAPFALevel(rawValue: self.levelSelection)! == .secondary2 {
                                    self.pullUps = []
                                    self.sortAndAddToData() {
                                        self.updateCache(for: year) {
                                            completion()
                                        }
                                    }
                                } else if NAPFALevel(rawValue: self.levelSelection)! == .secondary4 {
                                    self.fetchPullUps(for: year) {
                                        self.sortAndAddToData() {
                                            self.updateCache(for: year) {
                                                completion()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
        
        if !self.sitUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sitUps.insert(NAPFAResults(header: "Sit Ups"), at: 0)
        }
        if !self.sitAndReach.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sitAndReach.insert(NAPFAResults(header: "Sit And Reach"), at: 0)
        }
        if !self.sbj.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.sbj.insert(NAPFAResults(header: "Standing Broad Jump"), at: 0)
        }
        if !self.shuttleRun.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.shuttleRun.insert(NAPFAResults(header: "Shuttle Run"), at: 0)
        }
        if !self.inclinedPullUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            if NAPFALevel(rawValue: self.levelSelection)! == .secondary2 {
                self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups"), at: 0)
            } else if NAPFALevel(rawValue: self.levelSelection)! == .secondary4 {
                self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups (Female)"), at: 0)
            }
        }
        if !self.pullUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.pullUps.insert(NAPFAResults(header: "Pull Ups (Male)"), at: 0)
        }
        if !self.twoPointFourKm.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
            self.twoPointFourKm.insert(NAPFAResults(header: "2.4km Run"), at: 0)
        }
    }
    
    func updateValuesInFirebase(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").setData([
            "2.4km": stringifyNAPFAResultArray(self.twoPointFourKm),
            "inclinedpullups": stringifyNAPFAResultArray(self.inclinedPullUps),
            "pullups": stringifyNAPFAResultArray(self.pullUps),
            "sbj": stringifyNAPFAResultArray(self.sbj),
            "shuttle": stringifyNAPFAResultArray(self.shuttleRun),
            "sitandreach": stringifyNAPFAResultArray(self.sitAndReach),
            "situps": stringifyNAPFAResultArray(self.sitUps)
        ]) { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(true))
            }
        }
    }
    
    internal func stringifyNAPFAResultArray(_ data: [NAPFAResults]) -> [String] {
        var dataStrings: [String] = []
        data.forEach { value in
            if value.header.isEmpty {
                dataStrings.append("\(value.rank)___\(value.name)___\(value.className)___\(value.result)")
            }
        }
        return dataStrings
    }
    
    func updateCache(for year: Int, _ completion: @escaping (() -> Void)) {
        data["\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))"] = internalData
        completion()
    }
    
    func sortAndAddToData(_ completion: @escaping (() -> Void)) {
        self.internalData = []
        twoPointFourKm.forEach { data in
            self.internalData.append(data)
        }
        inclinedPullUps.forEach { data in
            self.internalData.append(data)
        }
        if NAPFALevel(rawValue: levelSelection)! == .secondary4 {
            pullUps.forEach { data in
                self.internalData.append(data)
            }
        }
        shuttleRun.forEach { data in
            self.internalData.append(data)
        }
        sitAndReach.forEach { data in
            self.internalData.append(data)
        }
        sitUps.forEach { data in
            self.internalData.append(data)
        }
        sbj.forEach { data in
            self.internalData.append(data)
        }
        completion()
    }
    
    internal func fetchSitUps(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sitUps = []
                    let fieldArray = documentData["situps"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.sitUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sitUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.sitUps.insert(NAPFAResults(header: "Sit Ups"), at: 0)
                    }
                    completion()
                }
            } else {
                self.sitUps = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchSitAndReach(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sitAndReach = []
                    let fieldArray = documentData["sitandreach"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.sitAndReach = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sitAndReach.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.sitAndReach.insert(NAPFAResults(header: "Sit And Reach"), at: 0)
                    }
                    completion()
                }
            } else {
                self.sitAndReach = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchSBJ(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sbj = []
                    let fieldArray = documentData["sbj"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.sbj = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sbj.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.sbj.insert(NAPFAResults(header: "Standing Broad Jump"), at: 0)
                    }
                    completion()
                }
            } else {
                self.sbj = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchShuttleRun(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.shuttleRun = []
                    let fieldArray = documentData["shuttle"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.shuttleRun = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.shuttleRun.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.shuttleRun.insert(NAPFAResults(header: "Shuttle Run"), at: 0)
                    }
                    completion()
                }
            } else {
                self.shuttleRun = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchInclinedPullUps(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.inclinedPullUps = []
                    let fieldArray = documentData["inclinedpullups"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.inclinedPullUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.inclinedPullUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        if NAPFALevel(rawValue: self.levelSelection)! == .secondary2 {
                            self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups"), at: 0)
                        } else if NAPFALevel(rawValue: self.levelSelection)! == .secondary4 {
                            self.inclinedPullUps.insert(NAPFAResults(header: "Inclined Pull Ups (Female)"), at: 0)
                        }
                    }
                    completion()
                }
            } else {
                self.inclinedPullUps = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchPullUps(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.pullUps = []
                    let fieldArray = documentData["pullups"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.pullUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.pullUps.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.pullUps.insert(NAPFAResults(header: "Pull Ups (Male)"), at: 0)
                    }
                    completion()
                }
            } else {
                self.pullUps = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchTwoPointFourKm(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document("\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))").getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.twoPointFourKm = []
                    let fieldArray = documentData["2.4km"] as? [String] ?? []
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.components(separatedBy: "___")
                        internalData.append(
                            NAPFAResults(
                                rank: Int(parts[0]) ?? 0,
                                name: String(parts[1]),
                                className: String(parts[2]),
                                result: String(parts[3])
                            )
                        )
                    }
                    self.twoPointFourKm = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.twoPointFourKm.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                        self.twoPointFourKm.insert(NAPFAResults(header: "2.4km Run"), at: 0)
                    }
                    completion()
                }
            } else {
                self.twoPointFourKm = []
                print("document not found")
                completion()
            }
        }
    }
}
