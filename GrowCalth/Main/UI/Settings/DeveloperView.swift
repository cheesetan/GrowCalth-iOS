//
//  DeveloperView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 31/3/24.
//

import SwiftUI

struct DeveloperView: View {
    
    @State var showAlert = false
    @State var newVersionToBlock = ""
    @State var isLoading = false
    
    @State var appForcesUpdates: Bool
    @State var appIsUnderMaintenance: Bool
    @State var bypass: Bool
    @State var blockedVersions: [String]?
    
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var developerManager: DeveloperManager = .shared
    
    var body: some View {
        List {
            Section("App Controls") {
                Toggle("App Forces Updates", isOn: $appForcesUpdates)
                Toggle("App Under Maintenance", isOn: $appIsUnderMaintenance)
                Toggle("Bypass Restrictions", isOn: $bypass)
            }
            
            Section {
                if let blockedVersions = blockedVersions {
                    ForEach(blockedVersions, id: \.self) { version in
                        Text(version)
                    }
                    .onDelete { indexSet in
                        withAnimation {
                            self.blockedVersions?.remove(atOffsets: indexSet)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Blocked Versions")
                    Button {
                        isLoading = true
                        developerManager.updateValues() {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.leading, 2.5)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoading)
                    Spacer()
                    EditButton()
                        .textCase(nil)
                        .disabled(blockedVersions == nil || blockedVersions?.count == 0)
                    Button {
                        showAlert.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationTitle("Developer Controls")
        .alert("Add Version", isPresented: $showAlert) {
            TextField("Enter a Version Number", text: $newVersionToBlock)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                withAnimation {
                    blockedVersions?.append(newVersionToBlock)
                    blockedVersions?.sort()
                    newVersionToBlock = ""
                }
            }
        }
        .onChange(of: appForcesUpdates) { newValue in
            if newValue {
                developerManager.changeAppForcesUpdatesValue(to: true) { _ in }
            } else {
                developerManager.changeAppForcesUpdatesValue(to: false) { _ in }
            }
        }
        .onChange(of: appIsUnderMaintenance) { newValue in
            if newValue {
                developerManager.changeAppIsUnderMaintenanceValue(to: true) { _ in }
            } else {
                developerManager.changeAppIsUnderMaintenanceValue(to: false) { _ in }
            }
        }
        .onChange(of: blockedVersions) { newValue in
            if let newValue = newValue {
                developerManager.changeVersionsBlockedValue(to: newValue) { _ in }
            }
        }
        .onChange(of: bypass) { newValue in
            if newValue {
                adminManager.changeBypassValue(to: true)
            } else {
                adminManager.changeBypassValue(to: false)
            }
        }
    }
}
