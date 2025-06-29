//
//  AnnouncementsView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct AnnouncementsView: View {

    @State var showingNewAnnouncementView = false
    @State var selection: AnnouncementType = .announcements
    
    @State var showingAlert = false
    @State var showingDeleteAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @State var stateUUID = ""
    @State var isLoading = false
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @EnvironmentObject var adminManager: AdminManager

    @Namespace private var namespace

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                main
            }
        } else {
            NavigationView {
                main
            }
            .navigationViewStyle(.stack)
        }
    }

    var main: some View {
        VStack(spacing: 0) {
            if #unavailable(iOS 26.0) {
                picker
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                Spacer()
            }
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
            if #unavailable(iOS 26.0) {
                Spacer()
            }
        }
        .animation(.default, value: selection)
        .animation(.default, value: announcementManager.announcements)
        .animation(.default, value: announcementManager.events)
        .navigationTitle(selection == .announcements ? "Announcements" : "Events")
        .refreshable {
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                try await announcementManager.retrieveAllPosts()
            }
        }
        .onAppear {
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                try await announcementManager.retrieveAllPosts()
            }
        }
        .onChange(of: announcementManager.announcements) { _ in
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
            }
        }
        .onChange(of: announcementManager.events) { _ in
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
            }
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        createPostButton
                    }
                }
                .matchedTransitionSource(id: "createpost", in: namespace)
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        createPostButton
                    }
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
        .sheet(isPresented: $showingNewAnnouncementView) {
            if #available(iOS 26.0, *) {
                NewAnnouncementView(postType: selection)
                    .navigationTransition(.zoom(sourceID: "createpost", in: namespace))
            } else {
                NewAnnouncementView(postType: selection)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if #available(iOS 26.0, *) {
                picker
                    .padding(8)
                    .pickerStyle(.menu)
                    .labelStyle(.iconOnly)
                    .glassEffect()
                    .padding()
                    .padding(.horizontal, 4)
            }
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
                .accessibilityLabel("\(announcementManager.announcements.firstIndex(where: { $0.id == item.id })! + 1)")
                .swipeActions {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
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
                .accessibilityLabel("\(announcementManager.events.firstIndex(where: { $0.id == item.id })! + 1)")
                .swipeActions {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
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
                        Task {
                            try await announcementManager.retrieveAllPosts()
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
                        Task {
                            try await announcementManager.retrieveAllPosts()
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.body.weight(.bold))
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
        Picker("Filters", selection: $selection) {
            ForEach(AnnouncementType.allCases, id: \.hashValue) { type in
                Label(type.rawValue, systemImage: type.icon)
                    .tag(type)
            }
        }
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
            Task {
                do {
                    try await adminManager.deleteAnnouncement(announcementUUID: uuid)
                    try await announcementManager.retrieveAllPosts()
                } catch {
                    alertHeader = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        case .events:
            Task {
                do {
                    try await adminManager.deleteEvent(eventUUID: uuid)
                    try await announcementManager.retrieveAllPosts()
                } catch {
                    alertHeader = "Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    AnnouncementsView()
}
