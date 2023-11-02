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
        generateNewQuote() { _ in }
    }
    
    enum QuoteGenerationError: LocalizedError {
        case errorOccurredWhileFetchingQuote
        var errorDescription: String? { return "An error has occurred while attempting to generate a new quote." }
    }
    
    func generateNewQuote(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        do {
            try fetchQuote()
            completion(.success(true))
        } catch {
            print("error")
            completion(.failure(QuoteGenerationError.errorOccurredWhileFetchingQuote))
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
            withAnimation(.default) {
                self.quote = newQuote
            }
        }
    }
}
