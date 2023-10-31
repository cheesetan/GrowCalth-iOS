//
//  ProgressBar.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

struct ProgressBar: View {
    
    @State var text: String
    @State var color: Color
    @State var height: CGFloat
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(width: geometry.size.width, height: height)
                    .opacity(0.3)
                    .foregroundColor(color)
                
                ForEach(0...Int(value), id: \.self) { i in
                    
                    var width: CGFloat {
                        if (value - Double(i)) >= 1 { // if bar is completely filled
                            return CGFloat(
                                geometry.size.width -
                                (Double(i) * (geometry.size.width / 60)) // minuses a bit of width for layering effect
                            )
                        } else { // if bar is not completely filled
                            return CGFloat(
                                (value - Double(i)) * CGFloat(geometry.size.width - ((Double(i) - 1) * (geometry.size.width / 60))) // minuses a bit of width due to layering effect, making total progressbar length smaller
                            )
                        }
                    }
                    
                    Capsule()
                        .frame(width: width, height: height)
                        .foregroundColor(color)
                        .shadow(color: .black, radius: 4)
                }
                
                HStack {
//                    Text("\(text) - \(value.truncatingRemainder(dividingBy: 1) * 100, specifier: "%.1f")%")
                    Text("\(text) - \(value * 100, specifier: "%.1f")%")
                }
                .minimumScaleFactor(0.1)
                .padding(10)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
            }
            .mask(Capsule())
        }
        .frame(height: height)
        .shadow(color: .black, radius: 4)
    }
}
//
//#Preview {
//    ProgressBar()
//}
