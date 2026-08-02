import Foundation

/// Read-only access to the card catalogue loaded from the bundle JSON.
public protocol CardRepository {

    /// Returns all 78 cards in the deck, ordered by id (0…77).
    func allCards() -> [Card]

    /// Returns the subset of cards belonging to the given arcana group.
    func cards(in group: CardGroup) -> [Card]

    /// Full-text search by card name, number, or suit name.
    ///
    /// Results are sorted by relevance (exact-name match first).
    /// Must return results within 500 ms on a real device (Requirement 2.3).
    func search(query: String) -> [Card]

    /// Resolves the appropriate interpretation for a card drawn in a given spread position.
    ///
    /// If a contextual interpretation for the `position` exists it is returned;
    /// otherwise the general `Interpretation` from the card's upright / reversed meaning
    /// is used as fallback (Requirement 7.5).
    ///
    /// - Parameters:
    ///   - card: The card whose interpretation is requested.
    ///   - position: The spread position, or `nil` (e.g. library detail view).
    ///   - orientation: Whether the card is upright or reversed.
    func interpretation(
        for card: Card,
        position: SpreadPosition?,
        orientation: CardOrientation
    ) -> Interpretation
}
