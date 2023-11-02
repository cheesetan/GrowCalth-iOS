//
//  AnnouncementDetailView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct AnnouncementDetailView: View {
    
    @State var announcement: Announcement
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(announcement.title)
                    .font(.title)
                    .fontWeight(.heavy)
                Divider()
                    .padding(.vertical, 5)
                if let description = announcement.description {
                    Text(LocalizedStringKey(description))
                }
            }
            .padding()
        }
        .navigationTitle("Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            adminManager.editAnnouncement()
                        } label: {
                            Label("Edit Announcement", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            adminManager.deleteAnnouncement()
                        } label: {
                            Label("Delete Announcement", systemImage: "trash")
                        }
                    } label: {
                        Label("Post Options", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
}
