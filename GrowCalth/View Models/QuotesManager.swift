//
//  QuotesManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 27/10/23.
//

import SwiftUI

@MainActor
final class QuotesManager: ObservableObject {

    @Published var quote: Quote?

    enum QuotesError: LocalizedError {
        case couldNotFindJsonFile
        case couldNotLoad
        case couldNotDecode
        case couldNotRandomlySelectQuote
        case fileReadError(Error)

        var errorDescription: String? {
            switch self {
            case .couldNotFindJsonFile:
                return "Could not find quotes JSON file"
            case .couldNotLoad:
                return "Could not load quotes JSON file"
            case .couldNotDecode:
                return "Could not decode quotes JSON file"
            case .couldNotRandomlySelectQuote:
                return "Could not randomly select quote"
            case .fileReadError(let error):
                return "File read error: \(error.localizedDescription)"
            }
        }
    }

    init() {
        Task {
            try? await generateNewQuote()
        }
    }

    func generateNewQuote() async throws {
        try await pickRandomQuote()
    }

    private func pickRandomQuote() async throws {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            throw QuotesError.couldNotFindJsonFile
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw QuotesError.fileReadError(error)
        }

        let decoder = JSONDecoder()
        let loadedFile: [Quote]
        do {
            loadedFile = try decoder.decode([Quote].self, from: data)
        } catch {
            throw QuotesError.couldNotDecode
        }

        guard let selectedQuote = loadedFile.randomElement() else {
            throw QuotesError.couldNotRandomlySelectQuote
        }

        await setQuote(
            newQuote: Quote(
                text: selectedQuote.text,
                author: selectedQuote.author
            )
        )
    }

    private func setQuote(newQuote: Quote) async {
        withAnimation(.default) {
            self.quote = newQuote
        }
    }
}
