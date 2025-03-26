//
//  DeveloperView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 31/3/24.
//

import SwiftUI

struct DeveloperView: View {
    
    @State var showAlert = false
    @State var showAlertAndroid = false
    
    @State var newVersionToBlock = ""
    @State var newVersionToBlockAndroid = ""
    
    @State var isLoading = false
    
    @State var appForcesUpdates: Bool
    @State var appIsUnderMaintenance: Bool
    @State var bypass: Bool
    @State var blockedVersions: [String]?
    @State var blockedVersionsAndroid: [String]?
    
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
                    Text("Blocked Versions (iOS)")
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
            
            Section {
                if let blockedVersionsAndroid = blockedVersionsAndroid {
                    ForEach(blockedVersionsAndroid, id: \.self) { version in
                        Text(version)
                    }
                    .onDelete { indexSet in
                        withAnimation {
                            self.blockedVersionsAndroid?.remove(atOffsets: indexSet)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Blocked Versions (Android)")
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
                        .disabled(blockedVersionsAndroid == nil || blockedVersionsAndroid?.count == 0)
                    Button {
                        showAlertAndroid.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationTitle("Developer Controls")
        .alert("Add Version (iOS)", isPresented: $showAlert) {
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
        .alert("Add Version (Android)", isPresented: $showAlertAndroid) {
            TextField("Enter a Version Number", text: $newVersionToBlockAndroid)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                withAnimation {
                    blockedVersionsAndroid?.append(newVersionToBlockAndroid)
                    blockedVersionsAndroid?.sort()
                    newVersionToBlockAndroid = ""
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
        .onChange(of: blockedVersionsAndroid) { newValue in
            if let newValue = newValue {
                developerManager.changeVersionsBlockedValueForAndroid(to: newValue) { _ in }
            }
        }
        .onChange(of: bypass) { newValue in
            if newValue {
                developerManager.changeBypassValue(to: true)
            } else {
                developerManager.changeBypassValue(to: false)
            }
        }
    }
}
