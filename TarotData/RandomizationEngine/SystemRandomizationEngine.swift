import Foundation
import TarotCore

/// Concrete implementation of `RandomizationEngine` using a Fisher-Yates shuffle
/// and probabilistic reversed-orientation assignment (Requirements 1.2, 1.3, 6.3).
///
/// `SystemRandomizationEngine` is initialised with the full 78-card deck so that
/// it can be composed before `BundleCardRepository` is available.
public struct SystemRandomizationEngine: RandomizationEngine {

    /// The deck of cards to draw from. Typically all 78 cards of the Rider-Waite deck.
    private let deck: [Card]

    /// The probability that any single drawn card will be assigned a reversed
    /// orientation when `allowReversed` is `true`.
    private let reversedProbability: Double

    // MARK: - Init

    /// Creates an engine backed by the supplied deck.
    ///
    /// - Parameters:
    ///   - deck: The source card collection. Must contain at least as many unique
    ///           cards as will ever be requested via `drawCards(count:…)`.
    ///   - reversedProbability: Probability [0, 1) that a drawn card is reversed.
    ///                          Defaults to `0.30` per the design specification.
    public init(deck: [Card], reversedProbability: Double = 0.30) {
        self.deck = deck
        self.reversedProbability = reversedProbability
    }

    // MARK: - RandomizationEngine

    /// Draws exactly `count` unique cards from the deck, binds each to the
    /// corresponding spread position, and optionally marks cards as reversed.
    ///
    /// - Parameters:
    ///   - count: Number of cards to draw. Clamped to `1 … deck.count`.
    ///   - allowReversed: When `true`, each card has a `reversedProbability`
    ///                    chance of being reversed. When `false`, all cards
    ///                    are returned upright (`isReversed = false`).
    ///   - positions: Spread positions to bind drawn cards to. Must have the
    ///                same length as `count`; if fewer positions are supplied
    ///                the remaining cards receive the last available position.
    /// - Returns: Array of `DrawnCard` with unique cards in draw order.
    public func drawCards(count: Int, allowReversed: Bool, positions: [SpreadPosition]) -> [DrawnCard] {
        let drawCount = max(1, min(count, deck.count))

        // Work on a mutable copy so the source deck is never mutated.
        var shuffled = deck
        fisherYatesShuffle(&shuffled)

        // Take the first `drawCount` cards from the shuffled deck.
        let selected = shuffled.prefix(drawCount)

        return selected.enumerated().map { index, card in
            let isReversed = allowReversed && Double.random(in: 0..<1) < reversedProbability
            // Bind to the matching position, or fall back to the last position if
            // `positions` is shorter than expected.
            let position: SpreadPosition
            if positions.isEmpty {
                // Safety fallback: create a generic position by name.
                position = SpreadPosition(name: "Position \(index + 1)")
            } else {
                position = positions[min(index, positions.count - 1)]
            }
            let orientation: CardOrientation = isReversed ? .reversed : .upright
            return DrawnCard(card: card, position: position, orientation: orientation)
        }
    }

    // MARK: - Private Helpers

    /// Performs an in-place Fisher-Yates (Knuth) shuffle on `array`.
    ///
    /// Each permutation is equally probable, yielding an unbiased shuffle
    /// of the full 78-card deck.
    private func fisherYatesShuffle(_ array: inout [Card]) {
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            array.swapAt(i, j)
        }
    }

    // MARK: - RandomizationEngine protocol compatibility
    /// Returns the underlying deck and a matching set of placeholder positions for each card.
    public func getCardsAndPositions() -> ([Card], [SpreadPosition]) {
        let positions = deck.indices.map { idx in SpreadPosition(name: "Position \(idx + 1)") }
        return (deck, positions)
    }
}

// MARK: - Convenience Factory

extension SystemRandomizationEngine {

    /// Creates a `SystemRandomizationEngine` backed by a minimal placeholder deck
    /// of 78 cards (ids 0…77). Useful for tests before `BundleCardRepository` is
    /// available. Each card is assigned a stub name and upright/reversed meanings.
    public static func withPlaceholderDeck() -> SystemRandomizationEngine {
        // Create a minimal placeholder drawn card to satisfy Interpretation's 'cards' parameter.
        let placeholderCard = Card(
            id: 0,
            name: "Card 0",
            number: nil,
            suit: nil,
            arcanaType: .major,
            imageName: "card_placeholder",
            uprightMeaning: Interpretation(cards: [], summary: "Placeholder", keywords: ["placeholder"], contextual: [:]),
            reversedMeaning: Interpretation(cards: [], summary: "Placeholder", keywords: ["placeholder"], contextual: [:])
        )
        let placeholderDrawn = DrawnCard(card: placeholderCard, position: SpreadPosition(name: "Placeholder"), orientation: .upright)
        let placeholderInterpretation = Interpretation(cards: [placeholderDrawn], summary: "Placeholder interpretation for testing purposes.", keywords: ["placeholder", "test", "stub"], contextual: [:])

        let cards = (0..<78).map { id in
            Card(
                id: id,
                name: "Card \(id)",
                number: nil,
                suit: nil,
                arcanaType: .major,
                imageName: "card_placeholder",
                uprightMeaning: placeholderInterpretation,
                reversedMeaning: placeholderInterpretation
            )
        }
        return SystemRandomizationEngine(deck: cards)
    }
}
