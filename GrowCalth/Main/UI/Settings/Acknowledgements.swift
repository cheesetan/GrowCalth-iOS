//
//  About.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct Acknowledgements: View {
    var body: some View {
        List {
            Section {
                Text(LocalizedStringKey("We are a group of students from School of Science and Technology, Singapore. We built this app together with a team of 5. We did this with the aim of wanting to benefit the community throught fitness. We hope that you have enjoyed our app while you used it and if you have any enquiries or feedback, please email us at growcalth.main@gmail.com."))
            } header: {
                Label("About GrowCalth", systemImage: "questionmark.circle.fill")
            }
            
            Section {
                acknowledgement(title: "Han Jeong Seu, **Caleb** - Lead Developer of GrowCalth", description: "Class of 2024", image: "person.bust.fill")
                acknowledgement(title: "Chay Yu Hung **Tristan** - Lead Developer of GrowCalth (iOS)", description: "Class of 2024", image: "hammer.fill")
                acknowledgement(title: "**Felix** Forbes Dimjati - User Experience (UX) Specialist of GrowCalth", description: "Class of 2024", image: "hammer.fill")
                acknowledgement(title: "Bellam Nandakumar **Aravind** - GrowCalth's Marketing and Communications IC", description: "Class of 2024", image: "text.bubble.fill")
                acknowledgement(title: "**Darryan** Lim Yuan Sheng - GrowCalth's Designer", description: "Class of 2024", image: "paintbrush.pointed.fill")
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
    func acknowledgement(title: LocalizedStringKey, description: String, image: String) -> some View {
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
    Acknowledgements()
}
