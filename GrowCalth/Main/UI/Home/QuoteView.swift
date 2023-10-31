//
//  QuoteView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

struct QuoteView: View {
    
    @ObservedObject var quotesManager: QuotesManager = .shared
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 15) {
                if let content = quotesManager.quote?.content {
                    Text(content)
                        .minimumScaleFactor(0.1)
                        .fontWeight(.semibold)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                if let author = quotesManager.quote?.author {
                    Text(author)
                        .minimumScaleFactor(0.1)
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            Button {
                quotesManager.generateNewQuote()
            } label: {
                Text("Generate new quote")
                    .minimumScaleFactor(0.1)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationTitle("Quotes")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            quotesManager.generateNewQuote()
        }
    }
}

//#Preview {
//    QuoteView()
//}
