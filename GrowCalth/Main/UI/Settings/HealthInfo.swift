//
//  HealthInfo.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct HealthInfo: View {
    
    @State var text = ""
    
    @ObservedObject var healthInfoManager: HealthInfoManager = .shared
    
    var body: some View {
        VStack {
            if !healthInfoManager.healthinfos.isEmpty {
                List {
                    ForEach(healthInfoManager.healthinfos, id: \.id) { item in
                        VStack(alignment: .leading) {
                            Text(item.text)
                                .lineLimit(2)
                        }
                    }
                    .onDelete { indexSet in
                        healthInfoManager.healthinfos.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        healthInfoManager.healthinfos.move(fromOffsets: from, toOffset: to)
                    }
                }
            } else {
                Spacer()
                Text(LocalizedStringKey("Add and keep track of your health information here. To start, enter something in the text field and click the \(Image(systemName: "plus.circle.fill")) button below. \(Image(systemName: "arrow.turn.right.down"))"))
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            HStack(spacing: 10) {
                VStack {
                    TextField("Enter something", text: $text)
                        .textFieldStyle(.roundedBorder)
                }
                Button {
                    if !text.isEmpty {
                        healthInfoManager.healthinfos.append(HealthInfoItem(text: text))
                        text = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                }
                .disabled(text.isEmpty)
            }
            .padding(.bottom, 5)
            .padding(.horizontal, 10)
        }
        .navigationTitle("Health information")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
}

#Preview {
    HealthInfo()
}
