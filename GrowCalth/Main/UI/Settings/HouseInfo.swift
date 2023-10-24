//
//  HouseInfo.swift
//  GrowCalth
//
//  Created by Tristan Chay on 24/10/23.
//

import SwiftUI

struct HouseInfo: View {
    
    enum HouseRole {
        case captain, vicecaptain
    }
    
    var body: some View {
        List {
            Section {
                houseItem(role: .captain, email: "chng_wei_ian@s2021.ssts.edu.sg")
                houseItem(role: .vicecaptain, email: "song_jun_hao_jarell@s2021.ssts.edu.sg")
            } header: {
                Text("⚫️ Black House")
            }
            
            Section {
                houseItem(role: .captain, email: "theshyan_thirun@s2021.ssts.edu.sg")
                houseItem(role: .vicecaptain, email: "aravind_b_n@s2021.ssts.edu.sg")
            } header: {
                Text("🔵 Blue House")
            }
            
            Section {
                houseItem(role: .captain, email: "teng_rui_jie@s2021.ssts.edu.sg")
                houseItem(role: .vicecaptain, email: "foo_g_wyinn@s2021.ssts.edu.sg")
            } header: {
                Text("🟢 Green House")
            }
            
            Section {
                houseItem(role: .captain, email: "ng_kian_ping@s2021.ssts.edu.sg")
                houseItem(role: .vicecaptain, email: "u_warisa@s2021.ssts.edu.sg")
            } header: {
                Text("🔴 Red House")
            }
            
            Section {
                houseItem(role: .captain, email: "zac_gan_yu_chieh@s2021.ssts.edu.sg")
                houseItem(role: .vicecaptain, email: "jesse_chia_kah_sim@s2021.ssts.edu.sg")
            } header: {
                Text("🟡 Yellow House")
            }
        }
        .navigationTitle("House info")
    }
    
    @ViewBuilder
    func houseItem(role: HouseRole, email: String) -> some View {
        HStack {
            switch role {
            case .captain:
                Text("Captain")
            case .vicecaptain:
                Text("Vice-Captain")
            }
            Spacer()
            Text(LocalizedStringKey(email))
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    HouseInfo()
}
