//
//  AnnouncementDetailView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct AnnouncementDetailView: View {
    
    @Binding var announcement: Announcement
    
    @State var isEditing = false
    @State var editableTitle = ""
    @State var editableDescription = ""
    
    @State var saveIsLoading = false
    
    @State var showingAlert = false
    @State var alertHeader: String = ""
    @State var alertMessage: String = ""
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var announcementManager: AnnouncementManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                title
                Divider()
                    .padding(.vertical, 5)
                description
            }
            .padding()
            .animation(.default, value: isEditing)
        }
        .navigationTitle("Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editableTitle = announcement.title
            if let description = announcement.description {
                editableDescription = description
            }
        }
        .toolbar {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) {
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
    }
    
    var title: some View {
        VStack {
            if isEditing {
                TextField("Announcement Title", text: $editableTitle)
                    .font(.title)
                    .fontWeight(.heavy)
            } else {
                Text(announcement.title)
                    .font(.title)
                    .fontWeight(.heavy)
            }
        }
    }
    
    var description: some View {
        VStack {
            if isEditing {
                TextField("Announcement Description", text: $editableDescription, axis: .vertical)
            } else {
                if let description = announcement.description {
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
                Label("Edit Announcement", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                adminManager.deleteAnnouncement()
            } label: {
                Label("Delete Announcement", systemImage: "trash")
            }
        } label: {
            Label("Post Options", systemImage: "ellipsis.circle")
        }
    }
    
    var saveEditButton: some View {
        VStack {
            if !saveIsLoading {
                Button {
                    if !editableTitle.isEmpty && !editableDescription.isEmpty {
                        adminManager.editAnnouncement(announcementUUID: announcement.id, title: editableTitle, description: editableDescription) { result in
                            switch result {
                            case .success(_):
                                isEditing = false
                            case .failure(let failure):
                                isEditing = false
                                alertHeader = "Error"
                                alertMessage = failure.localizedDescription
                                showingAlert = true
                            }
                            announcementManager.retrieveAllPosts()
                        }
                    }
                } label: {
                    Text("Save")
                }
                .disabled(editableTitle.isEmpty || editableDescription.isEmpty)
            } else {
                ProgressView()
            }
        }
        .animation(.default, value: saveIsLoading)
    }
}
