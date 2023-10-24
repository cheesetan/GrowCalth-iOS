//
//  AboutUs.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct AboutUs: View {
    var body: some View {
        List {
            Section("About GrowCalth") {
                Text(LocalizedStringKey("We are a group of students from School of Science and Technology, Singapore. We built this app togheter with a team of 4. We did this with the aimof wanting to benefit the community throught fitness. We hope that you have enjoyed our app while you used it and if you have any enquiries or feedback, please email us at growcalth.main@gmail.com"))
            }
            
            Section("Acknowledgements") {
                Label("Caleb Han - CEO of GrowCalth", systemImage: "person.bust.fill")
                Label("Tristan Chay - Developer of GrowCalth iOS", systemImage: "hammer.fill")
            }
        }
        .navigationTitle("About us")
    }
}

#Preview {
    AboutUs()
}
