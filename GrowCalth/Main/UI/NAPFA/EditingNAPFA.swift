//
//  EditingNAPFA.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/1/24.
//

import SwiftUI

struct EditingNAPFA: View {
    
    @State var saveLoading = false
    
    @State var yearSelection: Int
    
    @State var showingAlert = false
    @State var alertHeader = ""
    @State var alertMessage = ""
    
    @State var twoPointFourKm: [NAPFAResults]
    @State var inclinedPullUps: [NAPFAResults]
    @State var pullUps: [NAPFAResults]
    @State var shuttleRun: [NAPFAResults]
    @State var sitAndReach: [NAPFAResults]
    @State var sitUps: [NAPFAResults]
    @State var sbj: [NAPFAResults]
    
    @AppStorage("levelSelection", store: .standard) private var levelSelection: String = NAPFALevel.secondary2.rawValue
    @ObservedObject var napfaManager: NAPFAManager = .shared
    
    @Environment(\.dismiss) var dismiss
    
    var saveButtonDisabled: Bool {
        if self.twoPointFourKm == napfaManager.twoPointFourKm && self.inclinedPullUps == napfaManager.inclinedPullUps && self.pullUps == napfaManager.pullUps && self.shuttleRun == napfaManager.shuttleRun && self.sitAndReach == napfaManager.sitAndReach && self.sitUps == napfaManager.sitUps && self.sbj == napfaManager.sbj {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                twoPointFourKmView
                inclinedPullUpsView
                if NAPFALevel(rawValue: levelSelection)! == .secondary4 {
                    pullUpsView
                }
                shuttleRunView
                sitAndReachView
                sitUpsView
                sbjView
            }
            .alert(alertHeader, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .navigationTitle("\(String(yearSelection)) \(NAPFALevel(rawValue: levelSelection)!.rawValue) NAPFA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if saveLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(saveButtonDisabled)
                }
            }
        }
    }
    
    var twoPointFourKmView: some View {
        dataSections(data: self.$twoPointFourKm, sectionHeader: "2.4km Run")
    }
    
    var inclinedPullUpsView: some View {
        dataSections(data: self.$inclinedPullUps, sectionHeader: "Inclined Pull Ups \(NAPFALevel(rawValue: levelSelection)! == .secondary4 ? "(Female)" : "")")
    }
    
    var pullUpsView: some View {
        dataSections(data: self.$pullUps, sectionHeader: "Pull Ups (Male)")
    }
    
    var shuttleRunView: some View {
        dataSections(data: self.$shuttleRun, sectionHeader: "Shuttle Run")
    }
    
    var sitAndReachView: some View {
        dataSections(data: self.$sitAndReach, sectionHeader: "Sit And Reach")
    }
    
    var sitUpsView: some View {
        dataSections(data: self.$sitUps, sectionHeader: "Sit Ups")
    }
    
    var sbjView: some View {
        dataSections(data: self.$sbj, sectionHeader: "Standing Broad Jump")
    }
    
    func save() {
        saveLoading = true
        napfaManager.updateValues(
            sitUps: self.sitUps,
            sitAndReach: self.sitAndReach,
            sbj: self.sbj,
            shuttleRun: self.shuttleRun,
            inclinedPullUps: self.inclinedPullUps,
            pullUps: self.pullUps,
            twoPointFourKm: self.twoPointFourKm
        )
        napfaManager.sortAndAddToData {
            napfaManager.updateCache(for: yearSelection) {
                napfaManager.updateValuesInFirebase { result in
                    saveLoading = false
                    switch result {
                    case .success(_):
//                        napfaManager.fetchAllData(for: self.yearSelection) {}
                        dismiss.callAsFunction()
                    case .failure(let failure):
                        alertHeader = "Error"
                        alertMessage = failure.localizedDescription
                        showingAlert = true
                    }
                }
            }
        }
    }
    
    func hasEmptyFields(_ data: NAPFAResults) -> Bool {
        if data.rank != -1 && !data.result.isEmpty && !data.className.isEmpty && !data.name.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    @ViewBuilder
    func dataSections(data: Binding<[NAPFAResults]>, sectionHeader: String) -> some View {
        Section(sectionHeader) {
            ForEach(data, id: \.id) { $data in
                if $data.header.wrappedValue.isEmpty {
                    NavigationLink {
                        EditingNAPFARow(
                            levelSelection: $levelSelection,
                            rank: $data.rank,
                            name: $data.name,
                            className: $data.className,
                            result: $data.result
                        )
                    } label: {
                        VStack(alignment: .leading) {
                            Text($data.wrappedValue.name)
                                .foregroundStyle(hasEmptyFields($data.wrappedValue) ? .primary : .secondary)
                            if data.rank != -1 && !data.result.isEmpty && !data.className.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        if data.rank != -1 {
                                            dataSectionTags(systemImage: "medal.fill", text: "\($data.wrappedValue.rank)", backgroundColor: .yellow)
                                        }
                                        if !data.className.isEmpty {
                                            dataSectionTags(systemImage: "studentdesk", text: "\($data.wrappedValue.className)", backgroundColor: .blue)
                                        }
                                        if !data.result.isEmpty {
                                            dataSectionTags(systemImage: "chart.bar.doc.horizontal", text: "\($data.wrappedValue.result)", backgroundColor: .red)
                                        }
                                    }
                                }
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .onDelete { indexOffset in
                data.wrappedValue.remove(atOffsets: indexOffset)
            }
            Button {
                withAnimation {
                    data.wrappedValue.append(NAPFAResults(name: "Person"))
                }
            } label: {
                Image(systemName: "plus")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    @ViewBuilder
    func dataSectionTags(systemImage: String, text: String, backgroundColor: Color) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(text)
                .padding(.leading, -5)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .padding(5)
        .background(backgroundColor.opacity(0.5))
        .cornerRadius(8)
    }
}
