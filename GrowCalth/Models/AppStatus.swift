//
//  AppStatus.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import Foundation

enum AppStatus: Sendable {
    case home, login, noNetwork, updateAvailable, underMaintenance, loading(String)
}
