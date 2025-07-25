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
    
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var developerManager: DeveloperManager
    @EnvironmentObject var motionManager: MotionManager

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
        ZStack {
            Color.background.ignoresSafeArea()
            List {
                account
                appearance
                specularHighlights
                permissions
                resources
                acknowledgements
                if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) {
                    developer
                }
                signOutButton
            }
            .scrollIndicators(.hidden)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .onAppear {
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
            }
        }
        .alert(alertHeader, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    var account: some View {
        Section {
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
        } header: {
            Text("Account")
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
        }
    }
    
    var profileImage: some View {
        Circle()
            .foregroundColor(.accent)
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
            .accessibilityLabel("Account")
    }
    
    var appearance: some View {
        Section {
            Picker("Preferred Appearance", selection: $settingsManager.colorScheme) {
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
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
        } footer: {
            Text("Automatic sets GrowCalth's appearance based on your device's appearance.")
        }
    }

    var specularHighlights: some View {
        Section {
            Toggle(isOn: $settingsManager.specularHighlightsEnabled) {
                Text("Motion-based Specular Highlights")
            }
            .disabled(!motionManager.motionManager.isDeviceMotionAvailable)
        } header: {
            Text("Specular Highlights")
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
        } footer: {
            Text("Motion-based specular highlights shifts the angle of reflection of light based on device rotation. Enabling this feature might impact performance.")
        }
    }

    var permissions: some View {
        Section {
            Button {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open GrowCalth Notification Settings")
            }
        } header: {
            Text("Permissions")
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
        }
    }
    
    var developer: some View {
        Section {
            NavigationLink {
                if let appForcesUpdates = adminManager.appForcesUpdates, let appIsUnderMaintenance = adminManager.isUnderMaintenance, let blockedVersions = developerManager.blockedVersions, let blockedVersionsAndroid = developerManager.blockedVersionsAndroid {
                    DeveloperView(
                        appForcesUpdates: appForcesUpdates,
                        appIsUnderMaintenance: appIsUnderMaintenance,
                        blockedVersions: blockedVersions,
                        blockedVersionsAndroid: blockedVersionsAndroid
                    )
                }
            } label: {
                Text("Developer Controls")
            }
        } header: {
            Text("Developer")
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
        }
    }
    
    var resources: some View {
        Section {
            NavigationLink {
                CalculatorResourcesView()
            } label: {
                Text("Calculators")
            }
        } header: {
            Text("Resources")
                .textCase(.none)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.gray)
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
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await authManager.signOut()
                        } catch {
                            alertHeader = "Error"
                            alertMessage = "\(error.localizedDescription)"
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
