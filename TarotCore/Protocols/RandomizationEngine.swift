import Foundation

/// Responsible for drawing cards from the 78-card deck with fair randomisation
/// and probabilistic reversal assignment (Requirements 1.2, 1.3).
public protocol RandomizationEngine {

    /// Draws exactly `count` unique cards from the full 78-card deck.
    ///
    /// - Parameters:
    ///   - count: Number of cards to draw. Must be in 1 … 78.
    ///   - allowReversed: When `true`, each drawn card has a 30 % chance of being reversed.
    ///                    When `false`, all cards are returned upright.
    ///   - positions: The spread positions to bind each drawn card to. Must have the same
    ///                count as `count`.
    /// - Returns: Array of `DrawnCard` with unique cards, in draw order.
    func drawCards(count: Int, allowReversed: Bool, positions: [SpreadPosition]) -> [DrawnCard]

    /// Convenience method to retrieve the underlying raw cards and their assigned spread positions.
    /// This simplifies feeding data into Interpretation.synergy().
    /// - Returns: A tuple containing an array of `Card` objects and an array of corresponding `SpreadPosition`.
    func getCardsAndPositions() -> ([Card], [SpreadPosition])
}
