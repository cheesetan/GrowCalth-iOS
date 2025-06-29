//
//  NAPFAResults.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

struct NAPFAResults: Identifiable, Codable, Equatable {
    var id = UUID()
    var header: String = ""
    var rank: Int = -1
    var name: String = ""
    var className: String = ""
    var result: String = ""
}
