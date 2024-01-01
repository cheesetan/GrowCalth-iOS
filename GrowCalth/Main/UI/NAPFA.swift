//
//  NAPFA.swift
//  GrowCalth-iOS
//
//  Created by Tristan Chay on 23/10/23.
//

import SwiftUI

struct NAPFAResults: Identifiable {
    var id = UUID()
    var header: String = ""
    var rank: Int = -1
    var name: String = ""
    var className: String = ""
    var result: String = ""
}

struct NAPFA: View {
    
    @AppStorage("yearSelection", store: .standard) private var yearSelection: Int = Calendar.current.component(.year, from: Date())
    
    @State var data2023 = [
        NAPFAResults(header: "Sit Ups"),
        NAPFAResults(rank: 1, name: "RISHAV GANGULY", className: "S2-04", result: "58"),
        NAPFAResults(rank: 2, name: "YAAN WOON YU ZHE", className: "S2-02", result: "56"),
        NAPFAResults(rank: 2, name: "ANDERS CHARLES LEE EKBERG", className: "S2-02", result: "56"),
        NAPFAResults(rank: 4, name: "SHAI MING KONG (XIAO MINGJIANG)", className: "S2-07", result: "55"),
        NAPFAResults(rank: 5, name: "CHOW YONG JUN", className: "S2-06", result: "54"),
        
        NAPFAResults(header: "Inclined Pull Ups"),
        NAPFAResults(rank: 1, name: "YANN WOON YU ZHE", className: "S2-02", result: "41"),
        NAPFAResults(rank: 2, name: "KEITH LIM KAI FOO", className: "S2-08", result: "39"),
        NAPFAResults(rank: 3, name: "RIVERA ADRIEL HUYATID", className: "S2-03", result: "38"),
        NAPFAResults(rank: 4, name: "EDGAR KYAW", className: "S2-01", result: "37"),
        NAPFAResults(rank: 5, name: "FU CAI GUI", className: "S2-08", result: "35"),
        
        NAPFAResults(header: "2.4km Run"),
        NAPFAResults(rank: 1, name: "KUAH YONG CHUAN, EZEKIEL", className: "S2-01", result: "9min 36s"),
        NAPFAResults(rank: 2, name: "TAN QI JUN", className: "S2-02", result: "9min 57s"),
        NAPFAResults(rank: 3, name: "ETHAN CHEONG XING HUA", className: "S2-02", result: "10min 24s"),
        NAPFAResults(rank: 4, name: "SAMUEL CHEN YI", className: "S2-02", result: "10min 32s"),
        NAPFAResults(rank: 5, name: "VARCHEL HO ZI XIONG", className: "S2-02", result: "10min 36s"),
        
        NAPFAResults(header: "Shuttle Run"),
        NAPFAResults(rank: 1, name: "RISHAV GANGULY", className: "S2-04", result: "9.4s"),
        NAPFAResults(rank: 2, name: "MARTIN FUN JERN WENG", className: "S2-04", result: "9.6s"),
        NAPFAResults(rank: 2, name: "NG TZE RAYE (HUANG ZIRUI)", className: "S2-08", result: "9.6s"),
        NAPFAResults(rank: 2, name: "LIM WEI AN JORDAN", className: "S2-01", result: "9.6s"),
        NAPFAResults(rank: 5, name: "SHAI MING KONG (XIAO MINGJIANG)", className: "S2-07", result: "9.7s"),
        
        NAPFAResults(header: "Sit And Reach"),
        NAPFAResults(rank: 1, name: "FU CAI GUI", className: "S2-08", result: "67"),
        NAPFAResults(rank: 2, name: "TAN YU NING", className: "S2-01", result: "61"),
        NAPFAResults(rank: 3, name: "TIFFANY TAN XUAN YING", className: "S2-08", result: "56"),
        NAPFAResults(rank: 4, name: "KEITH LIM KAI FOO", className: "S2-08", result: "54"),
        NAPFAResults(rank: 5, name: "CHARIS TAN HUI WEN", className: "S2-02", result: "54"),
        
        NAPFAResults(header: "Standing Broad Jump"),
        NAPFAResults(rank: 1, name: "NG TZE RAYE (HUANG ZIRUI)", className: "S2-08", result: "253"),
        NAPFAResults(rank: 2, name: "JOVAN LEE KAI WEN", className: "S2-03", result: "252"),
        NAPFAResults(rank: 3, name: "YE MYINT MYAT RYAN", className: "S2-03", result: "245"),
        NAPFAResults(rank: 4, name: "ANDERS CHARLES LEE EKBERG", className: "S2-02", result: "241"),
        NAPFAResults(rank: 5, name: "VIJAY GANESH LATHISH", className: "S2-07", result: "235"),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                switch yearSelection {
                case 2023:
                    MultiColumnTable(headers: ["Rank", "Name", "Class", "Result"], data: data2023)
                        .padding(.top)
                default:
                    noDataAvailable(year: yearSelection)
                }
            }
            .animation(.default, value: yearSelection)
            .navigationTitle("NAPFA \(String(yearSelection))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if yearSelection > 2023 {
                            yearSelection -= 1
                        }
                    } label: {
                        Label("Previous year", systemImage: "chevron.left.circle.fill")
                    }
                    .disabled(yearSelection <= 2023)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if yearSelection < Calendar.current.component(.year, from: Date()) {
                            yearSelection += 1
                        }
                    } label: {
                        Label("Next year", systemImage: "chevron.right.circle.fill")
                    }
                    .disabled(yearSelection >= Calendar.current.component(.year, from: Date()))
                }
            }
        }
    }
    
    @ViewBuilder
    func noDataAvailable(year: Int) -> some View {
        VStack {
            if #available(iOS 17, *) {
                ContentUnavailableView {
                    Label("No Data", systemImage: "questionmark.square.dashed")
                } description: {
                    Text("There is no data available for NAPFA \(String(year)) yet.")
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("There is no data available for NAPFA \(String(year)) yet.")
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

#Preview {
    NAPFA()
}
