//
//  EventItem.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

struct EventItem: Identifiable, Equatable, Codable {
    var id: String
    var dateAdded: Date
    var title: String
    var description: String
    var venue: String
    var eventDate: Date
}
