//
//  NAPFA.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseFirestore

struct NAPFA: View {
    
    @State var isLoading = false
    
    @State var showingNAPFAEditing = false
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var napfaManager: NAPFAManager = .shared

    var body: some View {
        NavigationStack {
            VStack {
                picker
                table
            }
            .animation(.default, value: napfaManager.year)
            .animation(.default, value: napfaManager.levelSelection)
            .animation(.default, value: napfaManager.data)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNAPFAEditing) {
                EditingNAPFA(
                    yearSelection: napfaManager.year,
                    twoPointFourKm: napfaManager.twoPointFourKm,
                    inclinedPullUps: napfaManager.inclinedPullUps,
                    pullUps: napfaManager.pullUps,
                    shuttleRun: napfaManager.shuttleRun,
                    sitAndReach: napfaManager.sitAndReach,
                    sitUps: napfaManager.sitUps,
                    sbj: napfaManager.sbj
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { previousButton }
                ToolbarItem(placement: .principal) { title }
                ToolbarItem(placement: .navigationBarTrailing) { nextButton }
            }
            .onAppear {
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                napfaManager.fetchAllData(for: napfaManager.year) {
                    isLoading = false
                }
            }
            .refreshable {
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                if !showingNAPFAEditing {
                    napfaManager.fetchAllData(for: napfaManager.year) {
                        isLoading = false
                    }
                }
            }
            .onChange(of: napfaManager.year) { newYear in
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                napfaManager.fetchAllData(for: newYear) {
                    isLoading = false
                }
            }
            .onChange(of: napfaManager.levelSelection) { _ in
                adminManager.checkIfAppForcesUpdates()
                adminManager.checkIfUnderMaintenance() { }
                napfaManager.fetchAllData(for: napfaManager.year) {
                    isLoading = false
                }
            }
        }
    }
    
    var previousButton: some View {
        Button {
            if napfaManager.year > 2023 {
                napfaManager.year -= 1
            }
        } label: {
            Label("Previous year", systemImage: "chevron.left.circle.fill")
                .fontWeight(.bold)
        }
        .disabled(napfaManager.year <= 2023)
    }
    
    var title: some View {
        VStack {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                Button {
                    showingNAPFAEditing.toggle()
                } label: {
                    HStack {
                        Text("NAPFA \(String(napfaManager.year))")
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .symbolRenderingMode(.hierarchical)
                            .padding(.leading, -3)
                    }
                }
                .foregroundColor(.primary)
                .buttonStyle(.bordered)
                .mask(Capsule())
            } else {
                Text("NAPFA \(String(napfaManager.year))")
                    .font(.headline)
            }
        }
    }
    
    var nextButton: some View {
        Button {
            if napfaManager.year < Calendar.current.component(.year, from: Date()) {
                napfaManager.year += 1
            }
        } label: {
            Label("Next year", systemImage: "chevron.right.circle.fill")
                .fontWeight(.bold)
        }
        .disabled(napfaManager.year >= Calendar.current.component(.year, from: Date()))
    }
    
    var picker: some View {
        VStack {
            Picker(selection: $napfaManager.levelSelection) {
                ForEach(NAPFALevel.allCases, id: \.rawValue) { level in
                    Text(level.rawValue)
                        .tag(level.rawValue)
                }
            } label: {
                Text("NAPFA Secondary Level")
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
        }
    }
    
    var table: some View {
        VStack {
            if let cachedDataForYear = napfaManager.data["\(NAPFALevel(rawValue: napfaManager.levelSelection)!.firebaseCode)-\(String(napfaManager.year))"], !cachedDataForYear.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                MultiColumnTable(headers: ["Rank", "Name", "Class", "Result"], data: .constant(cachedDataForYear))
                    .padding(.top)
            } else {
                noDataAvailable(year: napfaManager.year)
            }
        }
    }
    
    @ViewBuilder
    func noDataAvailable(year: Int) -> some View {
        VStack {
            if #available(iOS 17, *) {
                ContentUnavailableView {
                    Label("No Data", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("There is no data available for \(String(year)) \(napfaManager.levelSelection) NAPFA at the moment.")
                } actions: {
                    Button {
                        isLoading = true
                        napfaManager.fetchAllData(for: napfaManager.year) {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 15) {
                    Spacer()
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("There is no data available for \(String(year)) \(napfaManager.levelSelection) NAPFA at the moment.")
                        .multilineTextAlignment(.center)
                    Button {
                        isLoading = true
                        napfaManager.fetchAllData(for: napfaManager.year) {
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NAPFA()
}
