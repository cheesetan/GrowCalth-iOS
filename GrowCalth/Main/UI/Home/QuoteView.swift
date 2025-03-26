//
//  QuoteView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 28/10/23.
//

import SwiftUI

struct QuoteView: View {
    
    @State var isLoading = false
    
    @State var alertTitle = ""
    @State var alertDescription = ""
    @State var showingAlert = false
    
    @ObservedObject var quotesManager: QuotesManager = .shared
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 15) {
                if let content = quotesManager.quote?.quote {
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
                generateNewQuote()
            } label: {
                Text("Generate new quote")
                    .minimumScaleFactor(0.1)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .foregroundColor(isLoading ? .clear : .white)
                    .fontWeight(.bold)
                    .cornerRadius(16)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding()
        .navigationTitle("Quotes")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertDescription)
        }

    }
    
    func generateNewQuote() {
        isLoading = true
        quotesManager.generateNewQuote() { result in
            switch result {
            case .success(_):
                isLoading = false
            case .failure(let failure):
                isLoading = false
                alertTitle = "Error"
                alertDescription = failure.localizedDescription
                showingAlert = true
            }
        }
    }
}

//#Preview {
//    QuoteView()
//}
