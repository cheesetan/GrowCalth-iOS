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
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var announcementManager: AnnouncementManager
    @EnvironmentObject var adminManager: AdminManager
    
    @Environment(\.dismiss) var dismiss

    init(announcement: Binding<Announcement>) {
        self._announcement = announcement

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
        .navigationTitle("Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editableTitle = announcement.title
            if let description = announcement.description {
                editableDescription = description
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
                TextField("Announcement Title", text: $editableTitle)
                    .font(.title.weight(.heavy))
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
                if #available(iOS 16.0, *) {
                    TextField("Announcement Description", text: $editableDescription, axis: .vertical)
                } else {
                    TextEditor(text: $editableDescription)
                }
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
                Task {
                    do {
                        try await adminManager.editAnnouncement(announcementUUID: announcement.id, title: editableTitle, description: editableDescription)
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
                try await adminManager.deleteAnnouncement(announcementUUID: announcement.id)
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
