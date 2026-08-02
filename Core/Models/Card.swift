import Foundation
import SwiftUI // For potential UI-related helpers or just good practice

/// Defines whether a card is upright or reversed.
public enum CardOrientation: String, CaseIterable, Codable {
    case upright = "Upright"
    case reversed = "Reversed"
}

/// Represents the core data for a single tarot card in the deck.
public struct Card: Identifiable, Hashable {
    public let id: UUID = UUID() // Unique ID for SwiftUI lists/state management
    public var name: String // e.g., "The Fool", "Three of Swords"
    public var suit: Suit // The suit (if applicable)
    public var number: Int? // 1-10, or nil for Major Arcana
    public var keywords: [String] // Core concepts associated with the card (e.g., ["New Beginnings", "Innocence"])
    public var generalInterpretation: String // The standard meaning when upright
    
    // *** TEXTURE/ASSET IDENTIFIER ADDED/CONFIRMED ***
    /// The name of the asset file or texture to use for this card (e.g., "fool_upright", "three_swords_reversed").
    public var imageName: String // This is what SwiftUI uses to load the visual representation!
    // -----------------------------------------------

    // Contextual interpretations are stored here to allow easy lookup by SpreadPosition ID
    /// Dictionary mapping a specific spread position's UUID to its unique interpretation text.
    public var contextualInterpretations: [UUID: String] = [:]

    // MARK: Initializers
    
    public init(name: String, suit: Suit, number: Int?, keywords: [String], generalInterpretation: String, imageName: String, orientation: CardOrientation = .upright) {
        self.name = name
        self.suit = suit
        self.number = number
        self.keywords = keywords
        self.generalInterpretation = generalInterpretation
        self.imageName = imageName // Initialize the new property
        self.orientation = orientation // Initialize the existing property
    }

    // MARK: Hashable conformance (required for use in Sets/Dictionaries)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }
}
