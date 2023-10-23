//
//  MultiColumnTable.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct MultiColumnTable: View {
    
    @State var headers: [String]
    @State var data: [NAPFAResults]
    
    var body: some View {
        ScrollView {
            HStack {
                ForEach(headers, id: \.self) { header in
                    Text(header)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
            }
            Divider()
            ForEach(data, id: \.id) { data in
                HStack {
                    Text(data.name)
                        .frame(maxWidth: .infinity)
                    Text(data.className)
                        .frame(maxWidth: .infinity)
                    Text("\(data.result)")
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 5)
                Divider()
            }
        }
    }
}

#Preview {
    MultiColumnTable(headers: ["Name", "Class", "Result"],
                     data: [
                        NAPFAResults(name: "Caleb Han", className: "S3-01", result: 100),
                        NAPFAResults(name: "Tristan Chay", className: "S3-04", result: 100)
                     ])
}
