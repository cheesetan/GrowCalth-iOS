//
//  HealthInfo.swift
//  Growcalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct HealthInfo: View {
    
    @State var text = ""
    
    @ObservedObject var healthInfoManager: HealthInfoManager = .shared
    
    var body: some View {
        VStack {
            List {
                ForEach(healthInfoManager.healthinfos, id: \.id) { item in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.text)
                                .lineLimit(2)
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
            HStack {
                VStack {
                    TextField("Enter something", text: $text)
                        .textFieldStyle(.roundedBorder)
                }
                Button {
                    healthInfoManager.healthinfos.append(HealthInfoItem(text: text))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Health information")
    }
}

#Preview {
    HealthInfo()
}
