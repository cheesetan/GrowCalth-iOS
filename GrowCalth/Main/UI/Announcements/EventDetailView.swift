//
//  EventDetailView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

struct EventDetailView: View {
    
    @State var event: EventItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(event.title)
                        .font(.title)
                        .fontWeight(.heavy)
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.date)
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(event.venue)
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                }
                Divider()
                    .padding(.vertical, 5)
                if let description = event.description {
                    Text(LocalizedStringKey(description))
                }
            }
            .padding()
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}
//
//#Preview {
//    EventDetailView()
//}
