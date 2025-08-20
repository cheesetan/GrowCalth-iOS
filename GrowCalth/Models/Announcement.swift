//
//  Announcement.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

struct Announcement: Identifiable, Equatable, Codable {
    var id: String
    var date: Date
    var title: String
    var description: String
}
