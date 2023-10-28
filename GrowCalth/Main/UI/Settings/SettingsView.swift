//
//  SettingsView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SettingsView: View {
    
    @State var showingSignOutAlert = false
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    var body: some View {
        NavigationStack {
            List {
                general
                health
                preferences
                signOutButton
            }
            .navigationTitle("Settings")
        }
    }
    
    var general: some View {
        Section("General") {
            NavigationLink {
                AboutUs()
            } label: {
                Label("About us", systemImage: "questionmark.circle.fill")
            }
        }
    }
    
    var health: some View {
        Section("Health") {
            NavigationLink {
                HealthInfo()
            } label: {
                Label("Health information", systemImage: "heart.text.square.fill")
            }
        }
    }
    
    var preferences: some View {
        Section("Preferences") {
            NavigationLink {
                AccountInfo()
            } label: {
                Label("Account info", systemImage: "person.fill")
            }
            
            NavigationLink {
                HouseInfo()
            } label: {
                Label("House", systemImage: "house.fill")
            }
        }
    }
    
    var signOutButton: some View {
        Section {
            Button {
                showingSignOutAlert = true
            } label: {
                Text("Sign out")
            }
            .tint(.red)
            .alert("Sign out", isPresented: $showingSignOutAlert) {
                Button(role: .destructive) {
                    authManager.signOut()
                } label: {
                    Text("Sign out")
                }
            } message: {
                Text("Are you sure you want to sign out? You can always sign back in with your email and password.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
