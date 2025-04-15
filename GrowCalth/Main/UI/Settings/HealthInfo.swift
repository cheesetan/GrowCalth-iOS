//
//  HealthInfo.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct HealthInfoItem: Codable, Identifiable {
    var id = UUID()
    var text: String
}

class HealthInfoManager: ObservableObject {
    static let shared: HealthInfoManager = .init()

    @Published var healthInfoItems: [HealthInfoItem] = [] {
        didSet {
            save()
        }
    }

    init() {
        load()
    }

    private func getArchiveURL() -> URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory.appending(path: "healthInfoItems.json")
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("healthInfoItems.json")
        }
    }

    private func save() {
        let archiveURL = getArchiveURL()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let HealthInfoItems = try? jsonEncoder.encode(healthInfoItems)
        try? HealthInfoItems?.write(to: archiveURL, options: .noFileProtection)
    }

    private func load() {
        let archiveURL = getArchiveURL()
        let jsonDecoder = JSONDecoder()

        if let HealthInfoItemData = try? Data(contentsOf: archiveURL),
           let healthInfoItemsDecoded = try? jsonDecoder.decode([HealthInfoItem].self, from: HealthInfoItemData) {
            healthInfoItems = healthInfoItemsDecoded
        }
    }
}

struct HealthInfo: View {
    
    @State var text = ""
    
    @ObservedObject private var healthInfoManager: HealthInfoManager = .shared

    var body: some View {
        VStack {
            if !healthInfoManager.healthInfoItems.isEmpty {
                List {
                    ForEach(healthInfoManager.healthInfoItems, id: \.id) { item in
                        VStack(alignment: .leading) {
                            Text(item.text)
                                .lineLimit(2)
                        }
                    }
                    .onDelete { indexSet in
                        healthInfoManager.healthInfoItems.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        healthInfoManager.healthInfoItems.move(fromOffsets: from, toOffset: to)
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
                        healthInfoManager.healthInfoItems.append(HealthInfoItem(text: text))
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
        .navigationTitle("Health Information")
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
