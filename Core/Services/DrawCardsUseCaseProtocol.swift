import Foundation
// Assuming TarotApp.Core.Models contains Spread, ReadingResult, etc.
public typealias ResultType = ReadingResult 

// MARK: - Supporting Types (Moved to the top to resolve ambiguity!)

/// Defines the configuration for a specific reading spread (e.g., "Celtic Cross").
public struct Spread { 
    // In a real app, this might be an array of CardPosition enums defining the order/number of cards.
    public let positions: [CardPosition] 
    // Added name property based on usage in TarotReadingViewModel.swift
    public var name: String // <-- ADDED THIS PROPERTY!
}

/// Represents a single card drawn, holding its metadata and interpretation.
public struct DrawnCard { 
    public let card: Card // The base card data (name, suit, keywords, etc.)
    public let position: SpreadPosition // Where in the spread it is located
    public var orientation: CardOrientation // How it was drawn (Upright/Reversed)
    public var positionalInterpretation: String? = nil // The summary fetched from the repository
}

/// Defines the possible positions within a card reading spread.
public enum CardPosition { 
    case past // e.g., "The Past"
    case present // e.g., "The Present"
    case future // e.g., "The Future"
    case outcome // e.g., "Final Outcome"
    // Add more positions as needed for different spreads
}

/// Defines the orientation of the drawn card.
public enum CardOrientation { 
    case upright
    case reversed
}

/// A structure holding the interpretation data fetched from the repository.
public struct InterpretationSummary { 
    public let summary: String // The actual narrative text snippet
}


// MARK: - Protocols (Defining contracts first)

/// Defines the contract for a Use Case responsible for executing the entire card drawing and interpretation process.
public protocol DrawCardsUseCaseProtocol {
    
    /// Executes the full reading sequence: Drawing cards based on the spread configuration, 
    /// enriching them with interpretations (using CardRepository), and synthesizing the final narrative.
    /// - Parameter spread: The specific Spread configuration to use for this reading.
    /// - Returns: A `ReadingResult` containing all drawn cards, the spread used, and the summary.
    func execute(for spread: Spread) async throws -> ResultType
}

// MARK: - Concrete Implementation (Optional but highly recommended next step)
/* 
 * To make this runnable immediately, you will likely want a concrete implementation 
 * that uses your existing services (CardRepositoryImpl and SpreadSynthesizerImpl).
 */
public class DrawCardsUseCaseImpl: DrawCardsUseCaseProtocol {
    
    // Dependencies needed to perform the work
    private let cardRepository: CardRepository // Needs definition/injection
    private let synthesizer: SpreadSynthesizerProtocol // Already defined!

    public init(cardRepository: CardRepository, synthesizer: SpreadSynthesizerProtocol) {
        self.cardRepository = cardRepository
        self.synthesizer = synthesizer
    }
    
    // MARK: DrawCardsUseCaseProtocol Conformance
    
    public func execute(for spread: Spread) async throws -> ReadingResult {
        // 1. Simulate Card Drawing (In a real app, this would involve shuffling and random selection)
        let drawnCards = try await drawRandomCards(for: spread)
        
        // 2. Synthesis (Using the provided synthesizer implementation)
        let summary = synthesizer.synthesize(for: spread, drawnCards: drawnCards)
        
        // 3. Return the final result package
        return ReadingResult(spread: spread, drawnCards: drawnCards, synthesisSummary: summary)
    }

    /// Helper function to simulate drawing cards (needs implementation detail).
    private func drawRandomCards(for spread: Spread) async throws -> [DrawnCard] {
        // --- SIMULATION LOGIC START ---
        print("⚙️ UseCase: Simulating card draws for \(spread.name)...")
        
        var drawnCards: [DrawnCard] = []
        let allDeckCards = cardRepository.allCards() // Get the full deck from the repository

        for position in spread.positions {
            // In a real scenario, you'd pick one card randomly and ensure it hasn't been picked yet.
            guard let randomCard = allDeckCards.randomElement() else {
                throw NSError(domain: "TarotError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Could not find any cards in the deck."])
            }
            
            // Simulate a random orientation (50/50 chance)
            let orientation: CardOrientation = Bool.random() ? .upright : .reversed
            
            // Create the drawn card instance using the canonical definition!
            var drawnCard = DrawnCard(card: randomCard, position: position, orientation: orientation)
            
            // OPTIONAL: Enrich the card immediately by getting its positional interpretation from the repository
            let interpretation = cardRepository.interpretation(for: randomCard, position: position, orientation: orientation)
            drawnCard.positionalInterpretation = interpretation.summary
            
            drawnCards.append(drawnCard)
        }
        // --- SIMULATION LOGIC END ---
        return drawnCards
    }
}
