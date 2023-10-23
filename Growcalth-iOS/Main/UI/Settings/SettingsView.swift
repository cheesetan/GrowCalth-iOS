//
//  SettingsView.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct SettingsView: View {
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

            NavigationLink {
                EmptyView()
            } label: {
                Label("More quotes", systemImage: "quote.opening")
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
                EmptyView()
            } label: {
                Label("Account info", systemImage: "person.fill")
            }
            
            NavigationLink {
                EmptyView()
            } label: {
                Label("House", systemImage: "house.fill")
            }
        }
    }
    
    var signOutButton: some View {
        Section {
            Button {
                
            } label: {
                Text("Sign out")
            }
            .tint(.red)
        }
    }
}

#Preview {
    SettingsView()
}
