//
//  AccountType.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

enum AccountType {
    case student, alumnus, teacher, special, admin, unknown

    var name: String {
        switch self {
        case .student: "Student"
        case .alumnus: "Alumnus"
        case .teacher: "Teacher"
        case .special: "Special"
        case .admin: "Admin"
        case .unknown: "Unknown"
        }
    }

    var canAddPoints: Bool {
        switch self {
        case .student: true
        case .alumnus: false
        case .teacher: true
        case .special: false
        case .admin: false
        case .unknown: false
        }
    }
}
