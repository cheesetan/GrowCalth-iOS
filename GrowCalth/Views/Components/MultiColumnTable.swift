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

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
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
