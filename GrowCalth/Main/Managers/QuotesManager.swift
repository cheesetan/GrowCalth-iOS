//
//  QuotesManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

struct Quote: Codable {
    var id: Int
    var quote: String
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
            print("error fetching quote")
            completion(.failure(QuoteGenerationError.errorOccurredWhileFetchingQuote))
        }
    }

    private func fetchQuote() throws {
        var request = URLRequest(url: URL(string: "https://dummyjson.com/quotes/random")!,timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) {
            [self] data,
            response,
            error in
            guard let data = data else {
                print(error)
                return
            }
            Task {
                let decoded = try JSONDecoder().decode(Quote.self, from: data)
                setQuote(
                    newQuote: Quote(
                        id: decoded.id,
                        quote: decoded.quote,
                        author: decoded.author
                    )
                )
            }
        }

        task.resume()
    }

    private func setQuote(newQuote: Quote) {
        DispatchQueue.main.async {
            withAnimation(.default) {
                self.quote = newQuote
            }
        }
    }
}
