//
//  ChallengesView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 19/8/25.
//

import SwiftUI

struct ChallengesView: View {
    var body: some View {
        NavigationStack {
            if #available(iOS 17.0, *) {
                main
                    .toolbarTitleDisplayMode(.inlineLarge)
            } else {
                main
            }
        }
    }

    var main: some View {
        List {
            Text("Challenges")
        }
        .navigationTitle("Challenges")
    }
}

#Preview {
    ChallengesView()
}
