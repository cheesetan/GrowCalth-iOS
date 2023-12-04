//
//  EventDetailView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

struct EventDetailView: View {
    
    @Binding var event: EventItem
    
    @State var isEditing = false
    @State var editableTitle = ""
    @State var editableDate = Date()
    @State var editableVenue = ""
    @State var editableDescription = ""
    
    @State var saveIsLoading = false
    
    @State var showingAlert = false
    @State var showingDeleteAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    title
                    date
                    venue
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                description
            }
            .padding()
            .animation(.default, value: isEditing)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editableTitle = event.title
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MMMM/yyyy"
            editableDate = dateFormatter.date(from: event.date) ?? Date()
            
            editableVenue = event.venue
            if let description = event.description {
                editableDescription = description
            } else {
                editableDescription = ""
            }
        }
        .toolbar {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack {
                        if isEditing {
                            saveEditButton
                        } else {
                            menuOptions
                        }
                    }
                    .animation(.default, value: isEditing)
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
                confirmDelete()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    var title: some View {
        VStack {
            if isEditing {
                TextField("Event Title", text: $editableTitle)
                    .font(.title)
                    .fontWeight(.heavy)
            } else {
                Text(event.title)
                    .font(.title)
                    .fontWeight(.heavy)
            }
        }
    }
    
    var date: some View {
        VStack {
            if isEditing {
                DatePicker(selection: $editableDate, in: Date()..., displayedComponents: .date) {
                    Label("Event Date", systemImage: "calendar")
                        .font(.headline)
                }
            } else {
                HStack {
                    Image(systemName: "calendar")
                    Text(event.date)
                }
                .font(.headline)
                .foregroundColor(.gray)
            }
        }
    }
    
    var venue: some View {
        VStack {
            if isEditing {
                TextField(LocalizedStringKey("\(Image(systemName: "mappin.and.ellipse")) Event Venue(s)"), text: $editableVenue)
                    .font(.headline)
            } else {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(event.venue)
                }
                .font(.headline)
                .foregroundColor(.gray)
            }
        }
    }
    
    var description: some View {
        VStack {
            if isEditing {
                TextField("Event Description", text: $editableDescription, axis: .vertical)
            } else {
                if let description = event.description {
                    Text(LocalizedStringKey(description))
                }
            }
        }
    }
    
    var menuOptions: some View {
        Menu {
            Button {
                isEditing = true
            } label: {
                Label("Edit Event", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                alertHeader = "Delete Event"
                alertMessage = "Are you sure you want to delete this event? This action cannot be undone."
                showingDeleteAlert = true
            } label: {
                Label("Delete Event", systemImage: "trash")
            }
        } label: {
            Label("Post Options", systemImage: "ellipsis.circle")
        }
    }
    
    var saveEditButton: some View {
        VStack {
            if !saveIsLoading {
                Button {
                    confirmEdits()
                } label: {
                    Text("Save")
                }
                .disabled(editableTitle.isEmpty || editableDescription.isEmpty || editableVenue.isEmpty)
            } else {
                ProgressView()
            }
        }
    }
    
    func confirmEdits() {
        if !editableTitle.isEmpty && !editableDescription.isEmpty && !editableVenue.isEmpty {
            if editableTitle != event.title || editableDate.formatted(date: .long, time: .omitted) != event.date || editableVenue != event.venue || editableDescription != event.description {
                saveIsLoading = true
                adminManager.editEvent(
                    eventUUID: event.id,
                    title: editableTitle,
                    description: editableDescription,
                    eventDate: editableDate,
                    eventVenues: editableVenue
                ) { result in
                    switch result {
                    case .success(_):
                        saveIsLoading = false
                        isEditing = false
                        announcementManager.retrieveAllPosts()
                    case .failure(let failure):
                        saveIsLoading = false
                        isEditing = false
                        alertHeader = "Error"
                        alertMessage = failure.localizedDescription
                        showingAlert = true
                    }
                }
            } else {
                isEditing = false
            }
        }
    }
    
    func confirmDelete() {
        adminManager.deleteEvent(eventUUID: event.id) { result in
            switch result {
            case .success(_):
                dismiss.callAsFunction()
                announcementManager.retrieveAllPosts()
            case .failure(let failure):
                alertHeader = "Error"
                alertMessage = failure.localizedDescription
                showingAlert = true
            }
        }
    }
}
//
//#Preview {
//    EventDetailView()
//}
