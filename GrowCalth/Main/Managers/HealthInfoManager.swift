//
//  HealthInfoManager.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

import Foundation
import SwiftUI

struct HealthInfoItem: Codable, Identifiable {
    var id = UUID()
    var text: String
}

class HealthInfoManager: ObservableObject {
    static let shared: HealthInfoManager = .init()
    
    @Published var healthinfos: [HealthInfoItem] = [] {
        didSet {
            save()
        }
    }
        
    init() {
        load()
    }
    
    func getArchiveURL() -> URL {
        let plistName = "healthinfo.plist"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        return documentsDirectory.appendingPathComponent(plistName)
    }
    
    func save() {
        let archiveURL = getArchiveURL()
        let propertyListEncoder = PropertyListEncoder()
        let encodedHealthinfos = try? propertyListEncoder.encode(healthinfos)
        try? encodedHealthinfos?.write(to: archiveURL, options: .noFileProtection)
    }
    
    func load() {
        let archiveURL = getArchiveURL()
        let propertyListDecoder = PropertyListDecoder()
                
        if let retrievedHealthInfoData = try? Data(contentsOf: archiveURL),
            let healthinfosDecoded = try? propertyListDecoder.decode([HealthInfoItem].self, from: retrievedHealthInfoData) {
            healthinfos = healthinfosDecoded
        }
    }
}

