//
//  QuotesManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

class QuotesManager: ObservableObject {
    
    @Published var quote: Quote?
    
    init() {
        generateNewQuote() { _ in }
    }
    
    func generateNewQuote(_ completion: @escaping ((Result<Bool, Error>) -> Void)) {
        do {
            try pickRandomQuote()
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }

    func pickRandomQuote() throws {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            throw QuotesError.couldNotFindJsonFile
        }

        guard let data = try? Data(contentsOf: url) else {
            throw QuotesError.couldNotLoad
        }

        let decoder = JSONDecoder()
        guard let loadedFile = try? decoder.decode([Quote].self, from: data) else {
            throw QuotesError.couldNotDecode
        }

        guard let quote = loadedFile.randomElement() else {
            throw QuotesError.couldNotRandomlySelectQuote
        }

        Task {
            setQuote(
                newQuote: Quote(
                    text: quote.text,
                    author: quote.author
                )
            )
        }
    }

//    private func fetchQuote() throws {
//        var request = URLRequest(url: URL(string: "https://dummyjson.com/quotes/random")!,timeoutInterval: Double.infinity)
//        request.httpMethod = "GET"
//
//        let task = URLSession.shared.dataTask(with: request) {
//            [self] data,
//            response,
//            error in
//            guard let data = data else {
//                print(error)
//                return
//            }
//            Task {
//                let decoded = try JSONDecoder().decode(Quote.self, from: data)
//                setQuote(
//                    newQuote: Quote(
//                        id: decoded.id,
//                        quote: decoded.quote,
//                        author: decoded.author
//                    )
//                )
//            }
//        }
//
//        task.resume()
//    }

    private func setQuote(newQuote: Quote) {
        DispatchQueue.main.async {
            withAnimation(.default) {
                self.quote = newQuote
            }
        }
    }
}

extension QuotesManager {
    internal enum QuotesError: LocalizedError {
        case couldNotFindJsonFile
        case couldNotLoad
        case couldNotDecode
        case couldNotRandomlySelectQuote

        var errorDescription: String? {
            switch self {
            case .couldNotFindJsonFile: return "Could not find quotes JSON file."
            case .couldNotLoad: return "Could not load quotes JSON file."
            case .couldNotDecode: return "Could not decode quotes JSON file."
            case .couldNotRandomlySelectQuote: return "Could not randomly select quote."
            }
        }
    }
}
