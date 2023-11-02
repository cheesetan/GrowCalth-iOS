//
//  Announcements.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct Announcements: View {
    
    @State var showingNewAnnouncementView = false
    @State var selection: AnnouncementType = .announcements
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    picker
                        .listRowBackground(Color.clear)
                    switch selection {
                    case .announcements:
                        ForEach(announcementManager.announcements, id: \.id) { item in
                            NavigationLink {
                                AnnouncementDetailView(announcement: item)
                            } label: {
                                announcementItem(title: item.title, description: item.description)
                            }
                        }
                    case .events:
                        ForEach(announcementManager.events, id: \.id) { item in
                            NavigationLink {
                                EventDetailView(event: item)
                            } label: {
                                eventItem(title: item.title, description: item.description, date: item.date, venue: item.venue)
                            }
                        }

                    }
                }
                .animation(.default, value: selection)
            }
            .listStyle(.grouped)
            .navigationTitle(selection == .announcements ? "Announcements" : "Events")
            .refreshable {
                announcementManager.retrieveInformations()
            }
            .onAppear {
                announcementManager.retrieveInformations()
            }
            .toolbar {
                if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        createPostButton
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewAnnouncementView) {
            NewAnnouncementView()
        }
    }
    
    var createPostButton: some View {
        Button {
            showingNewAnnouncementView.toggle()
        } label: {
            Label("Create a Post", systemImage: "square.and.pencil")
        }
    }
    
    var picker: some View {
        VStack {
            Picker("Filters", selection: $selection) {
                ForEach(AnnouncementType.allCases, id: \.hashValue) { type in
                    Text(type.rawValue)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func announcementItem(title: String, description: String?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.bold)
            if let description = description {
                Text(description)
                    .lineLimit(2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    func eventItem(title: String, description: String?, date: String, venue: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.bold)
            if let description = description {
                Text(description)
                    .lineLimit(2)
                    .foregroundColor(.gray)
            }
            HStack {
                Image(systemName: "calendar")
                Text(date)
            }
            .foregroundColor(.gray)
            .font(.subheadline)
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(venue)
            }
            .foregroundColor(.gray)
            .font(.subheadline)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    Announcements()
}
