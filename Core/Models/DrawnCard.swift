import Foundation
import SwiftUI // For potential UI-related helpers or just good practice

/// Represents the core data for a single card in the reading, enriched with contextual interpretation.
public struct DrawnCard: Identifiable, Hashable {
    public let id = UUID()
    public var card: Card // The base card data (name, suit, keywords, etc.)
    public var position: SpreadPosition // Where this card was drawn from in the spread
    // --- NOTE: This property is now redundant if we rely on card.orientation, but keeping it for explicit state tracking ---
    public var orientation: CardOrientation 
    // ---------------------------------------------------------------------------------------------------------------
    
    /// The narrative summary specific to *this* card's role in *this* spread.
    /// This is populated by the SpreadSynthesizer/CardRepositoryImpl.
    public var positionalInterpretation: String? 

    // MARK: Initializers
    
    /// Initializes a DrawnCard with all necessary components.
    public init(card: Card, position: SpreadPosition, orientation: CardOrientation) {
        self.card = card
        self.position = position
        self.orientation = orientation // Set the explicit state
        self.positionalInterpretation = nil // Will be populated by the UseCase/Service layer
    }

    // MARK: Hashable conformance (required for use in Sets/Dictionaries)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DrawnCard, rhs: DrawnCard) -> Bool {
        return lhs.id == rhs.id
    }
}
