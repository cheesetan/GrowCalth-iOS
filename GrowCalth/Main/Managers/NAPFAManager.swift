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

class NAPFAManager: ObservableObject {
    static let shared: NAPFAManager = .init()
    
    @AppStorage("yearSelection", store: .standard) private var year: Int = Calendar.current.component(.year, from: Date())
    
    @Published internal var sitUps: [NAPFAResults] = []
    @Published internal var sitAndReach: [NAPFAResults] = []
    @Published internal var sbj: [NAPFAResults] = []
    @Published internal var shuttleRun: [NAPFAResults] = []
    @Published internal var pullUps: [NAPFAResults] = []
    @Published internal var twoPointFourKm: [NAPFAResults] = []
    
    @Published var data: [NAPFAResults] = []
    @Persistent("cachedNAPFAData", store: .fileManager) private var cachedData: [Int : [NAPFAResults]] = [:]
    
    init() {
        self.fetchAllData(for: self.year)
    }
    
    func fetchAllData(for year: Int) {
        self.data = []
        self.fetchSitUps(for: year) {
            self.fetchSitAndReach(for: year) {
                self.fetchSBJ(for: year) {
                    self.fetchShuttleRun(for: year) {
                        self.fetchPullUps(for: year) {
                            self.fetchTwoPointFourKm(for: year) {
                                self.sortData() {
                                    self.updateCache(for: year)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateCache(for year: Int) {
        cachedData[year] = data
    }
    
    internal func sortData(_ completion: @escaping (() -> Void)) {
        self.data = []
        twoPointFourKm.forEach { data in
            self.data.append(data)
        }
        pullUps.forEach { data in
            self.data.append(data)
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
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sitUps = []
                    let fieldArray = documentData["situps"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sitUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.sitUps.insert(NAPFAResults(header: "Sit Ups"), at: 0)
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
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sitAndReach = []
                    let fieldArray = documentData["sitandreach"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sitAndReach = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.sitAndReach.insert(NAPFAResults(header: "Sit And Reach"), at: 0)
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
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.sbj = []
                    let fieldArray = documentData["sbj"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.sbj = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.sbj.insert(NAPFAResults(header: "Standing Broad Jump"), at: 0)
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
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.shuttleRun = []
                    let fieldArray = documentData["shuttle"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.shuttleRun = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.shuttleRun.insert(NAPFAResults(header: "Shuttle Run"), at: 0)
                    completion()
                }
            } else {
                self.shuttleRun = []
                print("document not found")
                completion()
            }
        }
    }
    
    internal func fetchPullUps(for year: Int, _ completion: @escaping (() -> Void)) {
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.pullUps = []
                    let fieldArray = documentData["pullups"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.pullUps = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.pullUps.insert(NAPFAResults(header: "Pull Ups"), at: 0)
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
        Firestore.firestore().collection("napfa").document(String(year)).getDocument { (document, error) in
            if let document = document, document.exists {
                if let documentData = document.data() {
                    self.twoPointFourKm = []
                    let fieldArray = documentData["2.4km"] as! [String]
                    var internalData: [NAPFAResults] = []
                    fieldArray.forEach { value in
                        let parts = value.split(separator: "___")
                        internalData.append(NAPFAResults(rank: Int(parts[0]) ?? 0, name: String(parts[1]), className: String(parts[2]), result: String(parts[3])))
                    }
                    self.twoPointFourKm = internalData.sorted(by: { $0.name < $1.name }).sorted(by: { $0.rank < $1.rank })
                    self.twoPointFourKm.insert(NAPFAResults(header: "2.4km Run"), at: 0)
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
