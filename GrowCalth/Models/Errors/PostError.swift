//
//  PostError.swift
//  GrowCalth
//
//  Created by Tristan Chay on 25/7/25.
//

import Foundation

enum PostError: LocalizedError, Sendable {
    case failedToGetEmail
    case failedToPostAnnouncement
    case failedToPostEvent
    case failedToUpdateAnnouncement
    case failedToUpdateEvent
    case failedToDeleteAnnouncement
    case failedToDeleteEvent

    var errorDescription: String? {
        switch self {
        case .failedToGetEmail:
            "An error has occurred while attempting to fetch your account details. Please sign out and sign back in again."
        case .failedToPostAnnouncement:
            "An error has occurred while attempting to post your announcement. Please try again later."
        case .failedToPostEvent:
            "An error has occurred while attempting to post your event. Please try again later."
        case .failedToUpdateAnnouncement:
            "An error has occurred while attempting to update your announcement. Please try again later."
        case .failedToUpdateEvent:
            "An error has occurred while attempting to update your event. Please try again later."
        case .failedToDeleteAnnouncement:
            "An error has occurred while attempting to delete your announcement. Please try again later."
        case .failedToDeleteEvent:
            "An error has occurred while attempting to delete your event. Please try again later."
        }
    }
}
