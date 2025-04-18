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
    
    @State var alertHeader = ""
    @State var alertMessage = ""
    @State var showingAlert = false
    
    @State var showingSignOutAlert = false
    
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var csManager: ColorSchemeManager = .shared
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var developerManager: DeveloperManager = .shared

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
        List {
            account
            appearance
            //                health
            permissions
            resources
            acknowledgements
            if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
                developer
            }
            signOutButton
        }
        .navigationTitle("Settings")
        .onAppear {
            adminManager.checkIfAppForcesUpdates()
            adminManager.checkIfUnderMaintenance() { }
        }
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    var account: some View {
        Section("Account") {
            NavigationLink {
                AccountInfo()
            } label: {
                HStack {
                    profileImage
                        .padding(.trailing, 10)
                    VStack(alignment: .leading) {
                        if let email = authManager.email {
                            Text(email)
                                .font(.body)
                                .fontWeight(.bold)
                            Text("Tap to view account information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding(.all, 10)
            }
        }
    }
    
    var profileImage: some View {
        Circle()
            .foregroundColor(.blue)
            .frame(width: 60)
            .overlay {
                VStack {
                    if let email = authManager.email {
                        let emailArray = Array(email)
                        Text(emailArray[0].uppercased())
                    } else {
                        Text("?")
                    }
                }
                .font(.system(size: 30.0).weight(.semibold))
                .foregroundColor(.white)
            }
    }
    
    var appearance: some View {
        Section {
            Picker("Preferred Appearance", selection: $csManager.colorScheme) {
                Text("Light")
                    .tag(PreferredColorScheme.light)
                Text("Automatic")
                    .tag(PreferredColorScheme.automatic)
                Text("Dark")
                    .tag(PreferredColorScheme.dark)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Automatic sets GrowCalth's appearance based on your device's appearance.")
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
    
    var permissions: some View {
        Section("Permissions") {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open GrowCalth in Settings")
            }
        }
    }
    
    var developer: some View {
        Section("Developer") {
            NavigationLink {
                if let appForcesUpdates = adminManager.appForcesUpdates, let appIsUnderMaintenance = adminManager.isUnderMaintenance, let blockedVersions = developerManager.blockedVersions, let blockedVersionsAndroid = developerManager.blockedVersionsAndroid {
                    DeveloperView(
                        appForcesUpdates: appForcesUpdates,
                        appIsUnderMaintenance: appIsUnderMaintenance,
                        bypass: developerManager.bypassed,
                        blockedVersions: blockedVersions,
                        blockedVersionsAndroid: blockedVersionsAndroid
                    )
                }
            } label: {
                Text("Developer Controls")
            }
        }
    }
    
    var resources: some View {
        Section("Resources") {
            NavigationLink {
                CalculatorResourcesView()
            } label: {
                Text("Calculators")
            }
        }
    }
    
    var acknowledgements: some View {
        Section {
            NavigationLink {
                Acknowledgements()
            } label: {
                Text("Acknowledgements")
            }
        }
    }
    
    var signOutButton: some View {
        Section {
            Link("Contact the Team", destination: URL(string: "mailto:chay_yu_hung@s2021.ssts.edu.sg,han_jeong_seu_caleb@s2021.ssts.edu.sg")!)
            
            Button {
                showingSignOutAlert = true
            } label: {
                Text("Sign out")
            }
            .tint(.red)
            .alert("Sign out", isPresented: $showingSignOutAlert) {
                Button(role: .destructive) {
                    authManager.signOut() { result in
                        switch result {
                        case .success(_):
                            break
                        case .failure(let failure):
                            alertHeader = "Error"
                            alertMessage = "\(failure.localizedDescription)"
                            showingAlert = true
                        }
                    }
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
