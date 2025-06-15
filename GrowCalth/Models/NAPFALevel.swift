//
//  NAPFALevel.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

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
