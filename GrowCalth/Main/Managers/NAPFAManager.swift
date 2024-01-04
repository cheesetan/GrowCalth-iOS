//
//  NAPFAManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 3/1/24.
//

import SwiftUI
import SwiftPersistence
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
}

class NAPFAManager: ObservableObject {
    static let shared: NAPFAManager = .init()
    
    @AppStorage("levelSelection", store: .standard) private var levelSelection: String = NAPFALevel.secondary2.rawValue
    @AppStorage("yearSelection", store: .standard) private var year: Int = Calendar.current.component(.year, from: Date())
    
    @Published internal var sitUps: [NAPFAResults] = []
    @Published internal var sitAndReach: [NAPFAResults] = []
    @Published internal var sbj: [NAPFAResults] = []
    @Published internal var shuttleRun: [NAPFAResults] = []
    @Published internal var inclinedPullUps: [NAPFAResults] = []
    @Published internal var pullUps: [NAPFAResults] = []
    @Published internal var twoPointFourKm: [NAPFAResults] = []
    
    @Published var data: [NAPFAResults] = []
    @Persistent("cachedNAPFAData", store: .fileManager) private var cachedData: [String : [NAPFAResults]] = [:]
    
    init() {
        self.fetchAllData(for: self.year) {}
    }
    
    func fetchAllData(for year: Int, _ completion: @escaping (() -> Void)) {
        self.data = []
        self.fetchSitUps(for: year) {
            self.fetchSitAndReach(for: year) {
                self.fetchSBJ(for: year) {
                    self.fetchShuttleRun(for: year) {
                        self.fetchInclinedPullUps(for: year) {
                            self.fetchTwoPointFourKm(for: year) {
                                if NAPFALevel(rawValue: self.levelSelection)! == .secondary2 {
                                    self.sortData() {
                                        self.updateCache(for: year) {
                                            completion()
                                        }
                                    }
                                } else if NAPFALevel(rawValue: self.levelSelection)! == .secondary4 {
                                    self.fetchPullUps(for: year) {
                                        self.sortData() {
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
    
    func updateCache(for year: Int, _ completion: @escaping (() -> Void)) {
        cachedData["\(NAPFALevel(rawValue: levelSelection)!.firebaseCode)-\(String(year))"] = data
        completion()
    }
    
    internal func sortData(_ completion: @escaping (() -> Void)) {
        self.data = []
        twoPointFourKm.forEach { data in
            self.data.append(data)
        }
        inclinedPullUps.forEach { data in
            self.data.append(data)
        }
        if NAPFALevel(rawValue: levelSelection)! == .secondary4 {
            pullUps.forEach { data in
                self.data.append(data)
            }
        }
        shuttleRun.forEach { data in
            self.data.append(data)
        }
        sitAndReach.forEach { data in
            self.data.append(data)
        }
        sitUps.forEach { data in
            self.data.append(data)
        }
        sbj.forEach { data in
            self.data.append(data)
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sitUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sitUps.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sitAndReach = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sitAndReach.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sbj = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.sbj.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.shuttleRun = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.shuttleRun.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.inclinedPullUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.inclinedPullUps.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.pullUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.pullUps.isEmpty {
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
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.twoPointFourKm = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    if !self.twoPointFourKm.isEmpty {
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
