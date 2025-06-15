//
//  MultiColumnTable.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct MultiColumnTable: View {
    
    @State var headers: [String]
    @Binding var data: [NAPFAResults]

    var dataHeaders: [String] {
        return data.map({ $0.header }).filter({ !$0.isEmpty })
    }

    var napfaData: [String : [NAPFAResults]] {
        var filteredData: [String: [NAPFAResults]] = [:]
        var currentHeader: String = dataHeaders.first ?? ""
        self.data.forEach { data in
            if !data.header.isEmpty {
                currentHeader = data.header
            } else {
                if let existingData = filteredData[currentHeader] {
                    filteredData[currentHeader] = existingData + [data]
                } else {
                    filteredData[currentHeader] = [data]
                }
            }
        }
        return filteredData
    }

    @EnvironmentObject var csManager: ColorSchemeManager

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if #available(iOS 26.0, *) {
            List {
                ForEach(dataHeaders, id: \.self) { header in
                    Section(header) {
                        ForEach(napfaData[header] ?? [], id: \.id) { data in
                            if data.header.isEmpty && data.rank != -1 && !data.className.isEmpty && !data.name.isEmpty && !data.result.isEmpty {
                                HStack {
                                    Text("\(data.rank)")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    Text(data.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(data.className)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    Text(data.result)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                    }
                }
                Section { Spacer().listRowBackground(Color.clear) }
            }
        } else {
            ScrollView {
                ForEach(data, id: \.id) { data in
                    if data.header != "" {
                        HStack {
                            Text(data.header)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 10)
                        .background(.ultraThickMaterial)
                        Divider()
                    } else if data.rank != -1 && !data.className.isEmpty && !data.name.isEmpty && !data.result.isEmpty {
                        HStack {
                            Text("\(data.rank)")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(data.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(data.className)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(data.result)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal)
                        Divider()
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack {
                    HStack {
                        ForEach(headers, id: \.self) { header in
                            Text(header)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    Divider()
                }
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(csManager.colorScheme == .dark ? .black : csManager.colorScheme == .automatic ? colorScheme == .dark ? .black : .white : .white)
            }
        }
    }
}

#Preview {
    MultiColumnTable(headers: ["Name", "Class", "Result"],
                     data: .constant([
                        NAPFAResults(name: "Caleb Han", className: "S3-01", result: "100"),
                        NAPFAResults(name: "Tristan Chay", className: "S3-04", result: "100")
                     ]))
}
