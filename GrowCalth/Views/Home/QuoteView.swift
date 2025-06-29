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
    
    @EnvironmentObject var quotesManager: QuotesManager
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 15) {
                if let content = quotesManager.quote?.text {
                    Text(content)
                        .minimumScaleFactor(0.1)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                if let author = quotesManager.quote?.author {
                    Text(author)
                        .minimumScaleFactor(0.1)
                        .font(.subheadline.weight(.bold))
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            generateButton
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

    var generateButton: some View {
        Group {
            if #available(iOS 26.0, *) {
                Button {
                    generateNewQuote()
                } label: {
                    Text("Generate new quote")
                        .minimumScaleFactor(0.1)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isLoading ? .clear : .white)
                        .font(.body.weight(.bold))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonStyle(.glassProminent)
                .disabled(isLoading)
            } else {
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
                        .font(.body.weight(.bold))
                        .mask(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
        }
    }

    func generateNewQuote() {
        isLoading = true
        Task {
            do {
                try await quotesManager.generateNewQuote()
            } catch {
                alertTitle = "Error"
                alertDescription = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
}

//#Preview {
//    QuoteView()
//}
