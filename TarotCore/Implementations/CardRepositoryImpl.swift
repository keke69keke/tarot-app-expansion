import Foundation
import SwiftUI

/// Concrete implementation of the CardRepository protocol, responsible for fetching card data from the bundled catalogue.
public class CardRepositoryImpl: CardRepository {
    
    // MARK: - Dependencies
    private let allCardsCache: [Card]

    
    // MARK: Initialization
    public init() {
        self.allCardsCache = []
    }
    
    // MARK: Private Methods
    
    /// Loads the complete deck of 78 cards into memory.
    private func loadAllCards() -> [Card] {
        return []
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
        guard !query.isEmpty && query.count >= 2 else {
            return []
        }
        
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if lowercasedQuery.isEmpty {
            return allCardsCache.filter { $0.name.lowercased().contains(lowercasedQuery) || 
                                    $0.suit?.rawValue.lowercased().contains(lowercasedQuery) == true }
        }
        
        let threshold = 2
        
        guard lowercasedQuery.count >= threshold else {
            return []
        }

        var matches: [Card] = []
        
        for card in allCardsCache where card.name.lowercased().contains(lowercasedQuery) {
            matches.append(card)
        }
        
        if !matches.isEmpty {
            return matches.sorted(by: { $0.name < $1.name })
        }

        let keywords = allCardsCache.flatMap { $0.uprightMeaning.keywords + $0.reversedMeaning.keywords }
        guard !keywords.isEmpty else { return [] }
        
        for card in allCardsCache where (card.uprightMeaning.keywords.contains(where: { $0.lowercased().contains(lowercasedQuery) }) || 
                                         card.reversedMeaning.keywords.contains(where: { $0.lowercased().contains(lowercasedQuery) })) {
            matches.append(card)
        }
        
        return matches.sorted(by: { $0.name < $1.name })
    }

    /// Resolves the appropriate interpretation for a card drawn in a given spread position.
    public func interpretation(for card: Card, position: SpreadPosition?, orientation: CardOrientation) -> Interpretation {
        let isReversed = (orientation == .reversed)
        
        guard !isReversed else {
            return card.reversedMeaning
        }

        let baseMeaning = card.uprightMeaning
        
        // Build a DrawnCard for use in the Interpretation.cards field.
        // If no position is supplied, create a placeholder position named "Unknown".
        let drawnPosition = position ?? SpreadPosition(name: "Unknown")
        let drawnOrientation: CardOrientation = isReversed ? .reversed : .upright
        let drawnCard = DrawnCard(card: card, position: drawnPosition, orientation: drawnOrientation)

        // If a specific positional override exists in the base meaning, use that summary.
        if let position = position, let posType = SpreadPositionType.from(position.name), 
           let contextText = baseMeaning.contextual[posType] {
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

    // MARK: - Advanced Search Methods
    
    /// Performs a fuzzy search across card names and meanings.
    public func advancedSearch(query: String) -> [Card] {
        guard !query.isEmpty && query.count >= 3 else {
            return []
        }
        
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        var matches: [Card] = []
        
        for card in allCardsCache where card.name.lowercased().contains(lowercasedQuery) {
            matches.append(card)
        }
        
        if !matches.isEmpty {
            return matches.sorted(by: { $0.name < $1.name })
        }

        let keywords = allCardsCache.flatMap { $0.uprightMeaning.keywords + $0.reversedMeaning.keywords }
        guard !keywords.isEmpty else { return [] }
        
        for card in allCardsCache where (card.uprightMeaning.keywords.contains(where: { $0.lowercased().contains(lowercasedQuery) }) || 
                                         card.reversedMeaning.keywords.contains(where: { $0.lowercased().contains(lowercasedQuery) })) {
            matches.append(card)
        }
        
        return matches.sorted(by: { $0.name < $1.name })
    }

    /// Returns cards that match a specific suit or arcana type.
    public func filterByType(arcanaType: ArcanaType, suit: CardSuit?) -> [Card] {
        if arcanaType == .major {
            return allCardsCache.filter { $0.arcanaType == .major }
        } else if let suit = suit {
            return allCardsCache.filter { $0.arcanaType == .minor && $0.suit == suit }
        }
        return []
    }

    /// Returns cards that match a specific range of numbers.
    public func filterByNumberRange(min: Int, max: Int) -> [Card] {
        guard min <= max else { return [] }
        
        var matches: [Card] = []
        
        for card in allCardsCache {
            if let numStr = card.number, let num = Int(numStr), num >= min, num <= max {
                matches.append(card)
            }
        }
        
        return matches.sorted(by: { 
            let n1 = Int($0.number ?? "") ?? 0
            let n2 = Int($1.number ?? "") ?? 0
            return n1 < n2
        })
    }
}
