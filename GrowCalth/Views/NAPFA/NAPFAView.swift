//
//  NAPFAView.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import FirebaseFirestore

struct NAPFAView: View {

    @State var isLoading = false
    
    @State var showingNAPFAEditing = false
    @EnvironmentObject var adminManager: AdminManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var napfaManager: NAPFAManager

    @Namespace private var namespace

    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                main
                    .navigationTitle("NAPFA")
            }
        } else if #available(iOS 16.0, *) {
            NavigationStack {
                main
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) { previousButton }
                        ToolbarItem(placement: .principal) { title }
                        ToolbarItem(placement: .navigationBarTrailing) { nextButton }
                    }
            }
        } else {
            NavigationView {
                main
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) { previousButton }
                        ToolbarItem(placement: .principal) { title }
                        ToolbarItem(placement: .navigationBarTrailing) { nextButton }
                    }
            }
            .navigationViewStyle(.stack)
        }
    }
    
    var main: some View {
        VStack {
            if #unavailable(iOS 26.0) {
                picker
                    .pickerStyle(.segmented)
                    .padding([.horizontal, .top])
            }
            table
        }
        .animation(.default, value: napfaManager.year)
        .animation(.default, value: napfaManager.levelSelection)
        .animation(.default, value: napfaManager.data)
        .sheet(isPresented: $showingNAPFAEditing) {
            if #available(iOS 26.0, *) {
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
                .navigationTransition(.zoom(sourceID: "napfaediting", in: namespace))
            } else {
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
        }
        .onAppear {
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                isLoading = true
                try await napfaManager.fetchAllData(for: napfaManager.year)
                isLoading = false
            }
        }
        .refreshable {
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                if !showingNAPFAEditing {
                    isLoading = true
                    try await napfaManager.fetchAllData(for: napfaManager.year)
                    isLoading = false
                }
            }
        }
        .onChange(of: napfaManager.year) { newYear in
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                try await napfaManager.fetchAllData(for: newYear)
                isLoading = false
            }
        }
        .onChange(of: napfaManager.levelSelection) { _ in
            Task {
                try await adminManager.checkIfAppForcesUpdates()
                try await adminManager.checkIfUnderMaintenance()
                isLoading = true
                try await napfaManager.fetchAllData(for: napfaManager.year)
                isLoading = false
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if #available(iOS 26.0, *) {
                HStack {
                    showNAPFAEditButton
                        .matchedTransitionSource(id: "napfaediting", in: namespace)

                    HStack {
                        previousButton
                            .padding(8)
                        title
                            .frame(maxWidth: .infinity)
                        nextButton
                            .padding(8)
                    }
                    .frame(maxWidth: .infinity)
                    .glassEffect()

                    picker
                        .padding(8)
                        .pickerStyle(.menu)
                        .glassEffect()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.horizontal, 4)
                .labelStyle(.iconOnly)
            }
        }
    }

    var showNAPFAEditButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                        showingNAPFAEditing.toggle()
                    }
                } label: {
                    Label("Create a Post", systemImage: "square.and.pencil")
                        .padding(8)
                        .foregroundStyle(.accent)
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(.glass)
            }
        }
    }

    var previousButton: some View {
        Button {
            if napfaManager.year > 2023 {
                napfaManager.year -= 1
            }
        } label: {
            Group {
                if #available(iOS 26.0, *) {
                    Label("Previous year", systemImage: "chevron.left")
                        .padding(8)
                        .foregroundStyle(napfaManager.year <= 2023 ? Color.secondary : .accentColor)
                } else {
                    Label("Previous year", systemImage: "chevron.left.circle.fill")
                }
            }
            .font(.body.weight(.bold))
        }
        .disabled(napfaManager.year <= 2023)
    }
    
    var title: some View {
        VStack {
            if #available(iOS 26.0, *) {
                Text("\(String(napfaManager.year))")
                    .font(.headline)
            } else {
                if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                    Button {
                        if let email = authManager.email, GLOBAL_ADMIN_EMAILS.contains(email) || email.contains("@sst.edu.sg") {
                            showingNAPFAEditing.toggle()
                        }
                    } label: {
                        HStack {
                            Text("NAPFA \(String(napfaManager.year))")
                                .font(.headline)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
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
    }
    
    var nextButton: some View {
        Button {
            if napfaManager.year < Calendar.current.component(.year, from: Date()) {
                napfaManager.year += 1
            }
        } label: {
            Group {
                if #available(iOS 26.0, *) {
                    Label("Next year", systemImage: "chevron.right")
                        .padding(8)
                        .foregroundStyle(napfaManager.year >= Calendar.current.component(.year, from: Date()) ? Color.secondary : .accentColor)
                } else {
                    Label("Next year", systemImage: "chevron.right.circle.fill")
                }
            }
            .font(.body.weight(.bold))
        }
        .disabled(napfaManager.year >= Calendar.current.component(.year, from: Date()))
    }
    
    var picker: some View {
        Picker(selection: $napfaManager.levelSelection) {
            ForEach(NAPFALevel.allCases, id: \.rawValue) { level in
                Label(level.rawValue, systemImage: level.icon)
                    .tag(level.rawValue)
                    .accessibilityLabel(level.accessibilityLabel)
            }
        } label: {
            Text("Year")
        }
    }

    var table: some View {
        VStack {
            if let cachedDataForYear = napfaManager.data["\(NAPFALevel(rawValue: napfaManager.levelSelection)!.firebaseCode)-\(String(napfaManager.year))"], !cachedDataForYear.filter( { $0.rank != -1 && !$0.className.isEmpty && !$0.name.isEmpty && !$0.result.isEmpty }).isEmpty {
                if #available(iOS 26.0, *) {
                    MultiColumnTable(headers: ["Rank", "Name", "Class", "Result"], data: .constant(cachedDataForYear))
                } else {
                    MultiColumnTable(headers: ["Rank", "Name", "Class", "Result"], data: .constant(cachedDataForYear))
                        .padding(.top)
                }
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
                        Task {
                            try await napfaManager.fetchAllData(for: napfaManager.year)
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
                        Task {
                            try await napfaManager.fetchAllData(for: napfaManager.year)
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.body.weight(.bold))
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
    NAPFAView()
}
