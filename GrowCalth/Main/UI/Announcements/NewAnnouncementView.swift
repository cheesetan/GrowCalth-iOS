//
//  NewAnnouncementView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 2/11/23.
//

import SwiftUI

struct NewAnnouncementView: View {
    
    @State var title = ""
    @State var description = ""
    
    @State var eventDate = Date()
    @State var eventVenue = ""
    
    @State var showingAlert = false
    @State var alertTitle = ""
    @State var alertDescription = ""
    
    @State var postType: AnnouncementType
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @EnvironmentObject var adminManager: AdminManager
    
    @EnvironmentObject var apnManager: ApplicationPushNotificationsManager
    
    @Environment(\.dismiss) var dismiss
    
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
        VStack {
            picker
                .padding(.top, -15)
                .padding([.bottom, .horizontal])

            TextField("\(postType == .announcements ? "Announcement" : "Event") Title", text: $title)
                .font(.largeTitle.weight(.heavy))

            if postType == .events {
                eventItems
            }

            Divider()
                .padding(.vertical, 10)

            if #available(iOS 16.0, *) {
                TextField("\(postType == .announcements ? "Announcement" : "Event") Description", text: $description, axis: .vertical)
            } else {
                TextEditor(text: $description)
            }

            Spacer()

            createButton
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        .animation(.default, value: postType)
        .navigationTitle("Create a Post")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top)
        .padding(.horizontal, 30)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertDescription)
        }
        .onChange(of: eventDate) { _ in
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            eventDate = calendar.startOfDay(for: eventDate)
        }
        .onAppear {
            let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
            eventDate = calendar.startOfDay(for: eventDate)
        }
    }

    var picker: some View {
        VStack {
            Picker("Post Type", selection: $postType) {
                ForEach(AnnouncementType.allCases, id: \.hashValue) { type in
                    Text(type.rawValue == "Events" ? "Event" : "Announcement")
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    var eventItems: some View {
        VStack {
            DatePicker(selection: $eventDate, in: Date()..., displayedComponents: .date) {
                Label("Event Date", systemImage: "calendar")
                    .foregroundColor(.secondary)
            }
            
            TextField(LocalizedStringKey("\(Image(systemName: "mappin.and.ellipse")) Event Venue(s)"), text: $eventVenue)
        }
    }
    
    var createButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        switch postType {
                        case .announcements:
                            createAnnouncement()
                        case .events:
                            createEvent()
                        }
                    }
                } label: {
                    Text("Create \(postType == .announcements ? "Announcement" : "Event")")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .font(.body.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
                .glassEffect()
            } else {
                Button {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        switch postType {
                        case .announcements:
                            createAnnouncement()
                        case .events:
                            createEvent()
                        }
                    }
                } label: {
                    Text("Create \(postType == .announcements ? "Announcement" : "Event")")
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .font(.body.weight(.bold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.bottom, 30)
        .disabled(title.isEmpty)
        .disabled(description.isEmpty)
        .disabled(postType == .events ? eventVenue.isEmpty : false)
    }
    
    func createAnnouncement() {
        adminManager.postAnnouncement(title: title, description: description) { result in
            switch result {
            case .success(_):
                successfullyCreatedPost()
            case .failure(let failure):
                alertTitle = "Error"
                alertDescription = failure.localizedDescription
                showingAlert = true
            }
        }
    }
    
    func createEvent() {
        adminManager.postEvent(title: title, description: description, eventDate: eventDate, eventVenues: eventVenue) { result in
            switch result {
            case .success(_):
                successfullyCreatedPost()
            case .failure(let failure):
                alertTitle = "Error"
                alertDescription = failure.localizedDescription
                showingAlert = true
            }
        }
    }
    
    func successfullyCreatedPost() {
        apnManager.sendPushNotificationsToEveryone(title: "New \(postType == .announcements ? "Announcement" : "Event")", subtitle: title, body: description)
        title = ""
        description = ""
        eventDate = Date()
        eventVenue = ""
        dismiss.callAsFunction()
        announcementManager.retrieveAllPosts() {}
    }
}

//#Preview {
//    NewAnnouncementView()
//}
