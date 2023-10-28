//
//  QuotesManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

struct Quote: Codable {
    var content: String
    var author: String
}

class QuotesManager: ObservableObject {
    static let shared: QuotesManager = .init()
    
    @Published var quote: Quote?
    
    init() {
        generateNewQuote()
    }
    
    func generateNewQuote() {
        do {
            try fetchQuote()
        } catch {
            print("error")
        }
    }
    
    private func fetchQuote() throws {
        Task {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.quotable.io/random")!)
            let decoded = try JSONDecoder().decode(Quote.self, from: data)
            print("decoded \(data)")
            setQuote(newQuote: Quote(content: decoded.content, author: decoded.author))
        }
    }
    
    private func setQuote(newQuote: Quote) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                self.quote = newQuote
            }
        }
    }
}
