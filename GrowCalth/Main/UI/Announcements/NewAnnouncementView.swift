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
    
    @State var postType = AnnouncementType.announcements
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                picker
                    .padding(.top, -15)
                    .padding([.bottom, .horizontal])
                
                TextField("\(postType == .announcements ? "Announcement" : "Event") Title", text: $title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                
                if postType == .events {
                    eventItems
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                TextField("\(postType == .announcements ? "Announcement" : "Event") Description", text: $description, axis: .vertical)
                
                Spacer()
                
                createButton
            }
            .animation(.default, value: postType)
            .navigationTitle("Create a Post")
            .navigationBarTitleDisplayMode(.inline)
            .padding(.top)
            .padding(.horizontal, 30)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
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
            TextField(LocalizedStringKey("\(Image(systemName: "mappin.and.ellipse")) Event Venue(s)"), text: $eventVenue)
            
            DatePicker(selection: $eventDate, in: Date()..., displayedComponents: .date) {
                Label("Event Date", systemImage: "calendar")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var createButton: some View {
        Button {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) {
                switch postType {
                case .announcements:
                    createAnnouncement()
                case .events:
                    createEvent()
                }
            }
        } label: {
            Text("Create \(postType == .announcements ? "Announcement" : "Event")")
                .minimumScaleFactor(0.1)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(16)
                .fontWeight(.bold)
        }
        .buttonStyle(.plain)
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
        title = ""
        description = ""
        eventDate = Date()
        eventVenue = ""
        dismiss.callAsFunction()
        announcementManager.retrieveInformations()
    }
}

#Preview {
    NewAnnouncementView()
}
