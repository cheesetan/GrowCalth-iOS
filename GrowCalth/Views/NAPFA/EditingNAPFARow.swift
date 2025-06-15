//
//  EditingNAPFARow.swift
//  GrowCalth
//
//  Created by Tristan Chay on 6/1/24.
//

import SwiftUI

struct EditingNAPFARow: View {
    
    @Binding var levelSelection: String
    @Binding var rank: Int
    @Binding var name: String
    @Binding var className: String
    @Binding var result: String
    
    var levelClassStart: String {
        switch NAPFALevel(rawValue: levelSelection)! {
            case .secondary2: return "S2"
            case .secondary4: return "S4"
        }
    }
    
    var body: some View {
        List {
            Section {
                rankView
                nameView
                classView
                resultView
            } header: {
                Text("Information")
            } footer: {
                Text("All fields must be filled up for this person to show up on the leaderboards.")
            }
        }
    }
    
    var rankView: some View {
        Picker("Rank", selection: $rank) {
            if rank == -1 {
                Text("Select a Rank").tag(-1)
                Divider()
            }
            Text("1").tag(1)
            Text("2").tag(2)
            Text("3").tag(3)
            Text("4").tag(4)
            Text("5").tag(5)
        }
    }
    
    var nameView: some View {
        HStack {
            Text("Name")
            Spacer()
            TextField("Name", text: $name)
                .multilineTextAlignment(.trailing)
        }
    }
    
    var classView: some View {
        Picker("Class", selection: $className) {
            if className == "" {
                Text("Select a Class").tag("")
                Divider()
            }
            Text("\(levelClassStart)-01").tag("\(levelClassStart)-01")
            Text("\(levelClassStart)-02").tag("\(levelClassStart)-02")
            Text("\(levelClassStart)-03").tag("\(levelClassStart)-03")
            Text("\(levelClassStart)-04").tag("\(levelClassStart)-04")
            Text("\(levelClassStart)-05").tag("\(levelClassStart)-05")
            Text("\(levelClassStart)-06").tag("\(levelClassStart)-06")
            Text("\(levelClassStart)-07").tag("\(levelClassStart)-07")
            Text("\(levelClassStart)-08").tag("\(levelClassStart)-08")
            Text("\(levelClassStart)-09").tag("\(levelClassStart)-09")
            Text("\(levelClassStart)-10").tag("\(levelClassStart)-10")
        }
    }
    
    var resultView: some View {
        HStack {
            Text("Result")
            Spacer()
            TextField("Result", text: $result)
                .multilineTextAlignment(.trailing)
        }
    }
}
