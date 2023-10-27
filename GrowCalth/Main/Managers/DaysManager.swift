//
//  DaysManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

class DaysManager: ObservableObject {
    static let shared: DaysManager = .init()
    
    @Published var daysInApp: Int?
    @AppStorage("lastDate", store: .standard) private var lastDate: String = ""
    @AppStorage("daysInAppAppStorage", store: .standard) private var daysInAppAppStorage: Int = 1
    
    init() {
        refreshNumberOfDaysInApp()
    }
    
    func refreshNumberOfDaysInApp() {
        updateLastEnteredAppDate()
        daysInApp = daysInAppAppStorage
    }
    
    private func updateLastEnteredAppDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        guard let date = fetchLastEnteredAppDate() else { return }
        if date != Calendar.current.startOfDay(for: .now) {
            if Date().timeIntervalSince(date) > 86400 && Date().timeIntervalSince(date) < 172800 {
                daysInAppAppStorage += 1
                lastDate = dateFormatter.string(from: Date())
            } else {
                daysInAppAppStorage = 1
                lastDate = dateFormatter.string(from: Date())
            }
        }
    }
    
    private func fetchLastEnteredAppDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        if lastDate.isEmpty {
            lastDate = dateFormatter.string(from: Date())
        }
        return dateFormatter.date(from: lastDate)
    }
}


