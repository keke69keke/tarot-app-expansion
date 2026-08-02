import Foundation
import SwiftUI // Assuming this is used heavily in presentation layer

/// Represents a single card drawn within a spread, along with its context.
public struct DrawnCard {
    /// The actual Tarot Card object (containing name, suit, etc.).
    public let card: Card
    
    /// The position this card occupies in the spread (e.g., .past, .goal).
    public let position: SpreadPosition
    
    /// The orientation at which the card was drawn (upright or reversed).
    public let orientation: CardOrientation

    /// Backwards-compatible boolean flag used by older code.
    public var isReversed: Bool { orientation == .reversed }
    
    /// **NEW**: The specific interpretation text generated for this card *in its assigned spread position*.
    /// This allows the synthesizer to pull rich data directly from the card instance.
    public var positionalInterpretation: String?

    public init(card: Card, position: SpreadPosition, orientation: CardOrientation) {
        self.card = card
        self.position = position
        self.orientation = orientation
        self.positionalInterpretation = nil
    }

    /// Backwards-compatible convenience initializer matching older call-sites.
    public init(card: Card, isReversed: Bool, position: SpreadPosition) {
        let orientation: CardOrientation = isReversed ? .reversed : .upright
        self.init(card: card, position: position, orientation: orientation)
    }

    /// Convenience initializer for when we only have raw data and need to create a card instance.
    public init(card: Card, position: SpreadPosition) {
        self.init(card: card, position: position, orientation: .upright) // Default to upright
    }

    /// Generates a high-level summary string based on the drawn cards and their positions.
    public static func generateDefaultSummary(from cards: [DrawnCard]) -> String {
        let cardNames = cards.map { $0.card.name }.joined(separator: ", ")
        let positions = cards.map { $0.position.displayName }.joined(separator: " in ")
        let firstCardName = cards.first?.card.name ?? "Unknown"
        return "This interpretation is based on the spread of \(cards.count) cards: \(cardNames). The overall narrative suggests a dynamic interplay between these energies, specifically highlighting themes related to '\(firstCardName)' and its influence across various positions like \(positions). A deeper dive into the contextual meanings will reveal how each card contributes to the overarching story."
    }
}

extension DrawnCard: Identifiable {
    public var id: String { "\(card.id)-\(position.displayName)" }
}
