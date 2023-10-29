//
//  SettingsView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftPersistence

struct SettingsView: View {
    
    @State var settingsColorScheme: PreferredColorScheme = .automatic
    @State var showingSignOutAlert = false
    @ObservedObject var authManager: AuthenticationManager = .shared
    
    @ObservedObject var csManager: ColorSchemeManager = .shared
    
    @Persistent("preferredColorSchemeAppStorage", store: .fileManager) private var preferredColorSchemeAppStorage: PreferredColorScheme = .automatic
        
    var body: some View {
        NavigationStack {
            List {
                general
                appearance
                health
                preferences
                signOutButton
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            settingsColorScheme = preferredColorSchemeAppStorage
        }
    }
    
    var general: some View {
        Section("General") {
            NavigationLink {
                About()
            } label: {
                Label("About", systemImage: "questionmark.circle.fill")
            }
        }
    }
    
    var appearance: some View {
        Section("Appearance") {
            Picker("Preferred Color Scheme", selection: $settingsColorScheme) {
                Text("Light")
                    .tag(PreferredColorScheme.light)
                Text("Automatic")
                    .tag(PreferredColorScheme.automatic)
                Text("Dark")
                    .tag(PreferredColorScheme.dark)
            }
            .pickerStyle(.segmented)
            .onChange(of: settingsColorScheme) { newValue in
                csManager.updatePreferredColorScheme(to: newValue)
            }
        }
    }
    
    var health: some View {
        Section("Health") {
            NavigationLink {
                HealthInfo()
            } label: {
                Label("Health Information", systemImage: "heart.text.square.fill")
            }
        }
    }
    
    var preferences: some View {
        Section("Preferences") {
            NavigationLink {
                AccountInfo()
            } label: {
                Label("Account Information", systemImage: "person.fill")
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
