import Foundation
import SwiftUI // For potential UI-related helpers or just good practice

/// Concrete implementation of the CardRepository protocol, responsible for fetching card data from the bundled catalogue.
public class CardRepositoryImpl: CardRepository {
    
    // MARK: - Dependencies (If we needed to inject more services later)
    private let allCardsCache: [Card] // In a real app, this would be loaded from JSON/DB on init
    
    // MARK: Initialization
    public init() {
        // TODO: Load the full 78-card deck from bundle or DB. Using an empty array for now
        // to avoid a compile-time dependency on a catalogue singleton that may not exist.
        self.allCardsCache = []
    }

    // MARK: CardRepository Protocol Conformance
    
    public func allCards() -> [Card] {
        return allCardsCache
    }

    public func cards(in group: CardGroup) -> [Card] {
        switch group {
        case .majorArcana:
            return allCardsCache.filter { $0.arcanaType == .major }
        case .minorArcana(let suit):
            return allCardsCache.filter { $0.arcanaType == .minor && $0.suit == suit }
        }
    }

    public func search(query: String) -> [Card] {
        let lowercasedQuery = query.lowercased()
        return allCardsCache.filter { card in
            let suitMatch = card.suit?.rawValue.lowercased().contains(lowercasedQuery) ?? false
            let nameMatch = card.name.lowercased().contains(lowercasedQuery)
            // Collect keywords from upright and reversed meanings (guarding against duplicates)
            let keywords = card.uprightMeaning.keywords + card.reversedMeaning.keywords
            let keywordMatch = keywords.contains(where: { $0.lowercased().contains(lowercasedQuery) })
            return nameMatch || suitMatch || keywordMatch
        }
    }

    /// Resolves the appropriate interpretation for a card drawn in a given spread position.
    public func interpretation(for card: Card, position: SpreadPosition?, orientation: CardOrientation) -> Interpretation {
        // Determine which base interpretation to use (upright vs reversed)
        let isReversed = (orientation == .reversed)
        let baseMeaning = isReversed ? card.reversedMeaning : card.uprightMeaning

        // Build a DrawnCard for use in the Interpretation.cards field.
        // If no position is supplied, create a placeholder position named "Unknown".
        let drawnPosition = position ?? SpreadPosition(name: "Unknown")
        let drawnOrientation: CardOrientation = isReversed ? .reversed : .upright
        let drawnCard = DrawnCard(card: card, position: drawnPosition, orientation: drawnOrientation)

        // If a specific positional override exists in the base meaning, use that summary.
        if let position = position, let posType = SpreadPositionType.from(position.name), let contextText = baseMeaning.contextual[posType] {
            return Interpretation(
                cards: [drawnCard],
                summary: contextText,
                keywords: baseMeaning.keywords,
                contextual: baseMeaning.contextual
            )
        }

        // Fallback: return the base meaning adapted to the drawn card context.
        return Interpretation(
            cards: [drawnCard],
            summary: baseMeaning.summary,
            keywords: baseMeaning.keywords,
            contextual: baseMeaning.contextual
        )
    }
}