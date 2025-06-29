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
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @EnvironmentObject var adminManager: AdminManager
    
    @Environment(\.dismiss) var dismiss

    init(event: Binding<EventItem>) {
        self._event = event

        if #available(iOS 16.0, *) {
        } else {
            UIScrollView.appearance().keyboardDismissMode = .onDrag
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            main
                .scrollDismissesKeyboard(.interactively)
        } else {
            main
        }
    }

    var main: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    title
                    if let name = event.name {
                        authorName(authorName: name)
                    }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
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
                    .font(.title.weight(.heavy))
            } else {
                Text(event.title)
                    .font(.title.weight(.heavy))
            }
        }
    }
    
    @ViewBuilder
    func authorName(authorName: String) -> some View {
        HStack {
            Image(systemName: "pencil.line")
            Text(authorName)
        }
        .font(.headline)
        .foregroundColor(.gray)
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
                if #available(iOS 16.0, *) {
                    TextField("Event Description", text: $editableDescription, axis: .vertical)
                } else {
                    TextEditor(text: $editableDescription)
                }
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
            Label("Options", systemImage: "ellipsis.circle")
        }
    }
    
    var saveEditButton: some View {
        Button {
            confirmEdits()
        } label: {
            if !saveIsLoading {
                Text("Save")
            } else {
                ProgressView()
            }
        }
        .disabled(editableTitle.isEmpty || editableDescription.isEmpty || editableVenue.isEmpty)
    }
    
    func confirmEdits() {
        if !editableTitle.isEmpty && !editableDescription.isEmpty && !editableVenue.isEmpty {
            if editableTitle != event.title || editableDate.formatted(date: .long, time: .omitted) != event.date || editableVenue != event.venue || editableDescription != event.description {
                saveIsLoading = true
                Task {
                    do {
                        try await adminManager.editEvent(
                            eventUUID: event.id,
                            title: editableTitle,
                            description: editableDescription,
                            eventDate: editableDate,
                            eventVenues: editableVenue
                        )
                        try await announcementManager.retrieveAllPosts()
                    } catch {
                        alertHeader = "Error"
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                    saveIsLoading = false
                    isEditing = false
                }
            } else {
                isEditing = false
            }
        }
    }
    
    func confirmDelete() {
        Task {
            do {
                try await adminManager.deleteEvent(eventUUID: event.id)
                dismiss.callAsFunction()
                try await announcementManager.retrieveAllPosts()
            } catch {
                alertHeader = "Error"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}
