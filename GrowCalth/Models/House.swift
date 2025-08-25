//
//  House.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import SwiftUI

struct House: Identifiable, Codable {
    var id: String
    var name: String
    var color: Color
    var points: Int
    var icon: URL?

    static func getPlacingFrom(int: Int) -> String {
        if int == 0 {
            return "???"
        } else if int == 1 {
            return "1ST"
        } else if int == 2 {
            return "2ND"
        } else if int == 3 {
            return "3RD"
        } else {
            return "\(int)TH"
        }
    }
}
