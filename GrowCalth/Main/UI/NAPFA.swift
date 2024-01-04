//
//  NAPFA.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI
import SwiftPersistence

struct NAPFA: View {
    
    @AppStorage("yearSelection", store: .standard) private var yearSelection: Int = Calendar.current.component(.year, from: Date())
    
    @State var showingNAPFAEditing = false
    @ObservedObject var adminManager: AdminManager = .shared
    @ObservedObject var authManager: AuthenticationManager = .shared
    @ObservedObject var napfaManager: NAPFAManager = .shared
    
    @Persistent("cachedNAPFAData", store: .fileManager) private var cachedData: [Int : [NAPFAResults]] = [:]
    
    var body: some View {
        NavigationStack {
            VStack {
               if let cachedDataForYear = cachedData[yearSelection], !cachedDataForYear.isEmpty {
                    MultiColumnTable(headers: ["Rank", "Name", "Class", "Result"], data: .constant(cachedDataForYear))
                        .padding(.top)
                } else {
                    noDataAvailable(year: yearSelection)
                }
            }
            .animation(.default, value: yearSelection)
            .animation(.default, value: cachedData)
            .animation(.default, value: napfaManager.data)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingNAPFAEditing) {
                Text("Editing NAPFA")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { previousButton }
                ToolbarItem(placement: .principal) { title }
                ToolbarItem(placement: .navigationBarTrailing) { nextButton }
            }
            .onAppear {
                napfaManager.fetchAllData(for: yearSelection)
            }
            .refreshable {
                napfaManager.fetchAllData(for: yearSelection)
            }
            .onChange(of: yearSelection) { newYear in
                napfaManager.fetchAllData(for: newYear)
            }
        }
    }
    
    var previousButton: some View {
        Button {
            if yearSelection > 2023 {
                yearSelection -= 1
            }
        } label: {
            Label("Previous year", systemImage: "chevron.left.circle.fill")
                .fontWeight(.bold)
        }
        .disabled(yearSelection <= 2023)
    }
    
    var title: some View {
        VStack {
            if let email = authManager.email, adminManager.approvedEmails.contains(email) || email.contains("@sst.edu.sg") {
                Button {
                    showingNAPFAEditing.toggle()
                } label: {
                    HStack {
                        Text("NAPFA \(String(yearSelection))")
                            .font(.headline)
                        Image(systemName: "chevron.right")
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
                Text("NAPFA \(String(yearSelection))")
                    .font(.headline)
            }
        }
    }
    
    var nextButton: some View {
        Button {
            if yearSelection < Calendar.current.component(.year, from: Date()) {
                yearSelection += 1
            }
        } label: {
            Label("Next year", systemImage: "chevron.right.circle.fill")
                .fontWeight(.bold)
        }
        .disabled(yearSelection >= Calendar.current.component(.year, from: Date()))
    }
    
    @ViewBuilder
    func noDataAvailable(year: Int) -> some View {
        VStack {
            if #available(iOS 17, *) {
                ContentUnavailableView {
                    Label("No Data", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("There is no data available for NAPFA \(String(year)) yet.")
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("There is no data available for NAPFA \(String(year)) yet.")
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

#Preview {
    NAPFA()
}
