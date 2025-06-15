//
//  AnnouncementType.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation

enum AnnouncementType: String, CaseIterable {
    case announcements = "Announcements"
    case events = "Events"

    var icon: String {
        switch self {
        case .announcements: "megaphone.fill"
        case .events: "calendar"
        }
    }
}
