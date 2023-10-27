//
//  AnnouncementDetailView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct AnnouncementDetailView: View {
    @State var announcement: Announcement
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
    }
}
