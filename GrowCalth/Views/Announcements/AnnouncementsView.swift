//
//  AnnouncementsView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct Journal: Identifiable {
    var id = UUID()
    var title: String
}

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

    @Environment(\.colorScheme) private var colorScheme

    let journals: [Journal] = []

    var body: some View {
        if #available(iOS 17.0, *) {
            NavigationStack {
                main
                    .toolbarTitleDisplayMode(.inlineLarge)
            }
        } else if #available(iOS 16.0, *) {
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
        ZStack {
            Color.background.ignoresSafeArea()
            GeometryReader { geometry in
                VStack {
                    picker
                        .padding(.horizontal, AppState.padding)
//                        .padding([.horizontal, .top], AppState.padding)
                    ScrollView {
                        VStack {
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
                        }
                        .padding([.horizontal, .bottom], AppState.padding)
                        .padding(.top, geometry.size.height*0.02)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .navigationTitle(selection == .announcements ? "Announcements" : "Events")
        .overlay(alignment: .bottomTrailing) {
            Group {
                if #available(iOS 26.0, *) {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        createPostButton
                            .padding()
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .mask(Circle())
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive())
                    }
                } else {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        createPostButton
                            .padding()
                            .font(.title)
                            .foregroundColor(.accentColor)
                            .background(.thickMaterial)
                            .mask(Circle())
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .animation(.default, value: selection)
        .animation(.default, value: announcementManager.announcements)
        .animation(.default, value: announcementManager.events)
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
            NewAnnouncementView(postType: selection)
        }
    }

    var announcementsList: some View {
        VStack(spacing: 15) {
            ForEach($announcementManager.announcements, id: \.id) { item in
                NavigationLink {
                    AnnouncementDetailView(announcement: item)
                } label: {
                    if #available(iOS 17.0, *) {
                        announcementItem(
                            date: item.date.wrappedValue,
                            title: item.title.wrappedValue,
                            description: item.description.wrappedValue
                        )
                        .scrollTransition { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.8)
                        }
                    } else {
                        announcementItem(
                            date: item.date.wrappedValue,
                            title: item.title.wrappedValue,
                            description: item.description.wrappedValue
                        )
                    }
                }
                .buttonStyle(.plain)
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
        VStack(spacing: 15) {
            ForEach($announcementManager.events, id: \.id) { item in
                NavigationLink {
                    EventDetailView(event: item)
                } label: {
                    if #available(iOS 17.0, *) {
                        eventItem(
                            dateAdded: item.dateAdded.wrappedValue,
                            title: item.title.wrappedValue,
                            description: item.description.wrappedValue,
                            date: item.date.wrappedValue,
                            venue: item.venue.wrappedValue
                        )
                        .scrollTransition { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.8)
                        }
                    } else {
                        eventItem(
                            dateAdded: item.dateAdded.wrappedValue,
                            title: item.title.wrappedValue,
                            description: item.description.wrappedValue,
                            date: item.date.wrappedValue,
                            venue: item.venue.wrappedValue
                        )
                    }
                }
                .buttonStyle(.plain)
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
            if #available(iOS 26.0, *) {
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
                    .buttonStyle(.glassProminent)
                }
            } else if #available(iOS 17, *) {
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
            Image(systemName: "square.and.pencil")
        }
    }

    var picker: some View {
        Picker("Update Type", selection: $selection) {
            ForEach(AnnouncementType.allCases, id: \.rawValue) { type in
                Text(type.rawValue)
                    .tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    var customPicker: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation {
                    selection = .announcements
                }
            } label: {
                Text("Announcements")
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .fontWeight(.bold)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == .announcements {
                            Capsule()
                                .fill(.shadow(.inner(
                                    color: Color.pickerActiveInnerShadow,
                                    radius: colorScheme == .dark ? 4.2 : 6.5
                                )))
                                .foregroundStyle(Color.pickerActiveBackground)
                        } else {
                            Capsule()
                                .fill(.shadow(.inner(color: Color.pickerInactiveInnerShadow, radius: 5)))
                                .foregroundStyle(Color.announcementEventBackground)
                        }
                    }
                    .overlay {
                        if selection == .announcements {
                            Capsule()
                                .stroke(
                                    colorScheme == .dark ? Color.pickerOutlineDark : Color.pickerOutlineLight,
                                    lineWidth: 1
                                )
                        }
                    }
                    .shadow(color: Color.pickerOuterShadow, radius: 17.5, x: 0 , y: 5)
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation {
                    selection = .events
                }
            } label: {
                Text("Events")
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .fontWeight(.bold)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == .events {
                            Capsule()
                                .fill(.shadow(.inner(
                                    color: Color.pickerActiveInnerShadow,
                                    radius: colorScheme == .dark ? 4.2 : 6.5
                                )))
                                .foregroundStyle(Color.pickerActiveBackground)
                        } else {
                            Capsule()
                                .fill(.shadow(.inner(color: Color.pickerInactiveInnerShadow, radius: 5)))
                                .foregroundStyle(Color.announcementEventBackground)
                        }
                    }
                    .overlay {
                        if selection == .events {
                            Capsule()
                                .stroke(
                                    colorScheme == .dark ? Color.pickerOutlineDark : Color.pickerOutlineLight,
                                    lineWidth: 1
                                )
                        }
                    }
                    .shadow(color: Color.pickerOuterShadow, radius: 17.5, x: 0 , y: 5)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    func announcementItem(date: Date, title: String, description: String?) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                    .lineLimit(2)
                if let description = description, !description.isEmpty {
                    Text(description.replacingOccurrences(of: "\n", with: " "))
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)

            VStack(alignment: .trailing) {
                if let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day {
                    Text("\(daysAgo)d ago")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.gray)
            }
            .multilineTextAlignment(.trailing)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .mask(RoundedRectangle(cornerRadius: 24))
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.shadow(.inner(
                    color: Color.announcementEventInnerShadow,
                    radius: colorScheme == .dark ? 6.5 : 32.5
                )))
                .foregroundStyle(Color.announcementEventBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.announcementEventOutline, lineWidth: 1)
        }
        .shadow(color: Color.announcementEventOuterShadow, radius: 12.5, x: 0, y: 5)
    }
    
    @ViewBuilder
    func eventItem(dateAdded: Date, title: String, description: String?, date: String, venue: String) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(title)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let daysAgo = Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day {
                    Text("\(daysAgo)d ago")
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                }
            }

            if let description = description, !description.isEmpty {
                Text(description.replacingOccurrences(of: "\n", with: " "))
                    .lineLimit(2)
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Label(date, systemImage: "calendar")
                    Label(venue, systemImage: "mappin.and.ellipse")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

                Spacer()

                Image(systemName: "arrowtriangle.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(.gray)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(20)
        .frame(maxWidth: .infinity)
        .mask(RoundedRectangle(cornerRadius: 24))
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.shadow(.inner(
                    color: Color.announcementEventInnerShadow,
                    radius: colorScheme == .dark ? 6.5 : 32.5
                )))
                .foregroundStyle(Color.announcementEventBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.announcementEventOutline, lineWidth: 1)
        }
        .shadow(color: Color.announcementEventOuterShadow, radius: 12.5, x: 0, y: 5)
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
