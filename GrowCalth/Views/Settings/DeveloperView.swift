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
    @State var blockedVersions: [String]?
    @State var blockedVersionsAndroid: [String]?
    
    @EnvironmentObject var developerManager: DeveloperManager
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            List {
                Section {
                    Toggle("App Forces Updates", isOn: $appForcesUpdates)
                    Toggle("App Under Maintenance", isOn: $appIsUnderMaintenance)
                    Toggle("Bypass Restrictions", isOn: Binding(get: {
                        developerManager.bypassed
                    }, set: { value in
                        withAnimation {
                            developerManager.bypassed = value
                        }
                    }))
                } header: {
                    Text("App Controls")
                        .textCase(.none)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.gray)
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
                            .textCase(.none)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.gray)
                        Button {
                            isLoading = true
                            Task {
                                try await developerManager.updateValues()
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
                            .textCase(.none)
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
                            .textCase(.none)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.gray)
                        Button {
                            isLoading = true
                            Task {
                                try await developerManager.updateValues()
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
                            .textCase(.none)
                            .disabled(blockedVersionsAndroid == nil || blockedVersionsAndroid?.count == 0)
                        Button {
                            showAlertAndroid.toggle()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
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
            Task {
                if newValue {
                    try await developerManager.changeAppForcesUpdatesValue(to: true)
                } else {
                    try await developerManager.changeAppForcesUpdatesValue(to: false)
                }
            }
        }
        .onChange(of: appIsUnderMaintenance) { newValue in
            Task {
                if newValue {
                    try await developerManager.changeAppIsUnderMaintenanceValue(to: true)
                } else {
                    try await developerManager.changeAppIsUnderMaintenanceValue(to: false)
                }
            }
        }
        .onChange(of: blockedVersions) { newValue in
            Task {
                if let newValue = newValue {
                    try await developerManager.changeVersionsBlockedValue(to: newValue)
                }
            }
        }
        .onChange(of: blockedVersionsAndroid) { newValue in
            Task {
                if let newValue = newValue {
                    try await developerManager.changeVersionsBlockedValueForAndroid(to: newValue)
                }
            }
        }
    }
}
