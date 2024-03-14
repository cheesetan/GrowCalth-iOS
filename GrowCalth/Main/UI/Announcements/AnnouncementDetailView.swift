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
                    if let name = announcement.name {
                        authorName(authorName: name)
                    }
                }
                
                Divider()
                    .padding(.vertical, 5)
                description
            }
            .padding()
            .animation(.default, value: isEditing)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editableTitle = announcement.title
            if let description = announcement.description {
                editableDescription = description
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
    
    @ViewBuilder
    func authorName(authorName: String) -> some View {
        HStack {
            Image(systemName: "pencil.line")
            Text(authorName)
        }
        .font(.headline)
        .foregroundColor(.gray)
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
                alertHeader = "Delete Announcement"
                alertMessage = "Are you sure you want to delete this announcement? This action cannot be undone."
                showingDeleteAlert = true
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
                    confirmEdits()
                } label: {
                    Text("Save")
                }
                .disabled(editableTitle.isEmpty || editableDescription.isEmpty)
            } else {
                ProgressView()
            }
        }
    }
    
    func confirmEdits() {
        if !editableTitle.isEmpty && !editableDescription.isEmpty {
            if editableTitle != announcement.title || editableDescription != announcement.description {
                saveIsLoading = true
                adminManager.editAnnouncement(announcementUUID: announcement.id, title: editableTitle, description: editableDescription) { result in
                    switch result {
                    case .success(_):
                        saveIsLoading = false
                        isEditing = false
                    case .failure(let failure):
                        saveIsLoading = false
                        isEditing = false
                        alertHeader = "Error"
                        alertMessage = failure.localizedDescription
                        showingAlert = true
                    }
                    announcementManager.retrieveAllPosts() {}
                }
            } else {
                isEditing = false
            }
        }
    }
    
    func confirmDelete() {
        adminManager.deleteAnnouncement(announcementUUID: announcement.id) { result in
            switch result {
            case .success(_):
                dismiss.callAsFunction()
                announcementManager.retrieveAllPosts() {}
            case .failure(let failure):
                alertHeader = "Error"
                alertMessage = failure.localizedDescription
                showingAlert = true
            }
        }
    }
}
