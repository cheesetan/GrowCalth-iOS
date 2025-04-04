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
    
    @State var showingAlert = false
    @State var showingDeleteAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @State var stateUUID = ""
    @State var isLoading = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                picker
                Spacer()
                switch selection {
                case .announcements:
                    if !announcementManager.announcements.isEmpty {
                        announcementsList
                    } else {
                        noContentView(keyword: "Announcements", systemImage: "megaphone.fill")
                    }
                case .events:
                    if !announcementManager.events.isEmpty {
                        eventsList
                    } else {
                        noContentView(keyword: "Events", systemImage: "calendar")
                    }
                }
                Spacer()
            }
            .animation(.default, value: selection)
            .animation(.default, value: announcementManager.announcements)
            .animation(.default, value: announcementManager.events)
            .listStyle(.grouped)
            .navigationTitle(selection == .announcements ? "Announcements" : "Events")
            .refreshable {
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                announcementManager.retrieveAllPosts() {}
            }
            .onAppear {
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                announcementManager.retrieveAllPosts() {}
            }
            .onChange(of: announcementManager.announcements) { _ in
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
            }
            .onChange(of: announcementManager.events) { _ in
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
            }
            .toolbar {
                if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        createPostButton
                    }
                }
            }
            .alert(alertHeader, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert(alertHeader, isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    confirmDelete(uuid: stateUUID)
                }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingNewAnnouncementView) {
            NewAnnouncementView(postType: selection)
        }
    }
    
    var announcementsList: some View {
        List {
            ForEach($announcementManager.announcements, id: \.id) { item in
                NavigationLink {
                    AnnouncementDetailView(announcement: item)
                } label: {
                    announcementItem(
                        title: item.title.wrappedValue,
                        description: item.description.wrappedValue
                    )
                }
                .swipeActions {
                    if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                        Button(role: .destructive) {
                            stateUUID = item.id
                            alertHeader = "Delete Announcement"
                            alertMessage = "Are you sure you want to delete this Announcement? This action cannot be undone."
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Announcement", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
    
    var eventsList: some View {
        List {
            ForEach($announcementManager.events, id: \.id) { item in
                NavigationLink {
                    EventDetailView(event: item)
                } label: {
                    eventItem(
                        title: item.title.wrappedValue,
                        description: item.description.wrappedValue,
                        date: item.date.wrappedValue,
                        venue: item.venue.wrappedValue
                    )
                }
                .swipeActions {
                    if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                        Button(role: .destructive) {
                            stateUUID = item.id
                            alertHeader = "Delete Event"
                            alertMessage = "Are you sure you want to delete this Event? This action cannot be undone."
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Event", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func noContentView(keyword: String, systemImage: String) -> some View {
        VStack {
            if #available(iOS 17, *) {
                ContentUnavailableView {
                    Label("No \(keyword)", systemImage: systemImage)
                } description: {
                    Text("There are no \(keyword) available at the moment.")
                } actions: {
                    Button {
                        isLoading = true
                        announcementManager.retrieveAllPosts() {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: systemImage)
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("There are no \(keyword) available at the moment.")
                        .multilineTextAlignment(.center)
                    Button {
                        isLoading = true
                        announcementManager.retrieveAllPosts() {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
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
            if let description = description, !description.isEmpty {
                Text(description.replacingOccurrences(of: "\n", with: " "))
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
            if let description = description, !description.isEmpty, description != " " {
                Text(description.replacingOccurrences(of: "\n", with: " "))
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
    
    func confirmDelete(uuid: String) {
        switch selection {
        case .announcements:
            adminManager.deleteAnnouncement(announcementUUID: uuid) { result in
                switch result {
                case .success(_):
                    announcementManager.retrieveAllPosts() {}
                case .failure(let failure):
                    alertHeader = "Error"
                    alertMessage = failure.localizedDescription
                    showingAlert = true
                }
            }
        case .events:
            adminManager.deleteEvent(eventUUID: uuid) { result in
                switch result {
                case .success(_):
                    announcementManager.retrieveAllPosts() {}
                case .failure(let failure):
                    alertHeader = "Error"
                    alertMessage = failure.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    Announcements()
}
