//
//  NAPFA.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct NAPFAResults: Identifiable {
    var id = UUID()
    var name: String
    var className: String
    var result: Int
}

struct NAPFA: View {
    
    @State var yearSelection = "NAPFA 2023"
    @State var dummyData = [
        NAPFAResults(name: "Caleb Han", className: "S3-01", result: 100),
        NAPFAResults(name: "Tristan Chay", className: "S3-04", result: 100)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker(selection: $yearSelection) {
                    Text("NAPFA 2023")
                        .tag("NAPFA 2023")
                    Text("NAPFA 2024")
                        .tag("NAPFA 2024")
                } label: {
                    Text("NAPFA Year")
                }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                MultiColumnTable(headers: ["Name", "Class", "Result"],
                                 data: dummyData)
                    .padding(.top)
            }
            .navigationTitle("NAPFA")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu {
//                        Picker(selection: $yearSelection) {
//                            Text("NAPFA 2023")
//                            Text("NAPFA 2024")
//                        } label: {
//                            Text("NAPFA Year")
//                        }
//                    } label: {
//                        Image(systemName: "calendar")
//                    }
//
//                }
//            }
        }
    }
}

#Preview {
    NAPFA()
}
