//
//  Houses.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import SwiftUI

enum Houses: String, CaseIterable {
    case selectHouse = "Select your house"
    case black = "Black"
    case blue = "Blue"
    case green = "Green"
    case red = "Red"
    case yellow = "Yellow"

    var color: Color {
        switch self {
        case .selectHouse: Color.gray
        case .black: Color.black
        case .blue: Color.blue
        case .green: Color.green
        case .red: Color.red
        case .yellow: Color.yellow
        }
    }

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
