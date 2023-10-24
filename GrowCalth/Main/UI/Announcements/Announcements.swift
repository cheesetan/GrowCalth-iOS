//
//  Announcements.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct Announcements: View {
    
    enum AnnouncementType {
        case none, announcements, events
    }
    
    @State var selection: AnnouncementType = .none
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(1...7, id: \.self) { _ in
                    announcementItem
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Announcements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    picker
                }
            }
        }
    }
    
    var picker: some View {
        Menu {
            Picker(selection: $selection) {
                Text("None")
                    .tag(AnnouncementType.none)
                Divider()
                Text("Announcements")
                    .tag(AnnouncementType.announcements)
                Text("Events")
                    .tag(AnnouncementType.events)
            } label: {
                Text("Filters")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .overlay {
                    if selection != .none {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .offset(x: 5, y: 6)
                    }
                }
        }
    }
    
    var announcementItem: some View {
        VStack(alignment: .leading) {
            Text("Announcement")
                .fontWeight(.bold)
            Text("Details! Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                .lineLimit(2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    Announcements()
}
