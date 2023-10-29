//
//  About.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct About: View {
    var body: some View {
        List {
            Section {
                Text(LocalizedStringKey("We are a group of students from School of Science and Technology, Singapore. We built this app together with a team of 4. We did this with the aim of wanting to benefit the community throught fitness. We hope that you have enjoyed our app while you used it and if you have any enquiries or feedback, please email us at growcalth.main@gmail.com."))
            } header: {
                Label("About GrowCalth", systemImage: "questionmark.circle.fill")
            }
            
            Section {
                acknowledgement(title: "Caleb Han - CEO of GrowCalth", description: "Class of 2024", image: "person.bust.fill")
                acknowledgement(title: "Tristan Chay - Developer of GrowCalth iOS", description: "Class of 2024", image: "hammer.fill")
            } header: {
                Label("Development Team", systemImage: "person.3.fill")
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/firebase/firebase-ios-sdk")!) {
                    acknowledgement(title: "Firebase iOS SDK", description: "Developed by Google. Licensed under the Apache License 2.0.", image: "server.rack")
                }
                
                Link(destination: URL(string: "https://github.com/cheesetan/SwiftPersistence")!) {
                    HStack {
                        acknowledgement(title: "SwiftPersistence", description: "Developed by Tristan Chay. Licensed under the MIT License.", image: "square.and.arrow.down.on.square")
                    }
                }
            } header: {
                Label("Packages & Libraries", systemImage: "shippingbox.fill")
            }
        }
        .navigationTitle("About")
    }
    
    @ViewBuilder
    func acknowledgement(title: String, description: String, image: String) -> some View {
        HStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .foregroundColor(.blue)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    About()
}
