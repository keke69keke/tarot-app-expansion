import Foundation

/// Represents possible positions within a tarot spread.
public enum SpreadPositionType: String, Codable {
    case daily = "Daily"
    case past = "Past"
    case present = "Present"
    case future = "Future"
    case advice = "Advice"
    case outcome = "Outcome"
    case challenge = "Challenge"
    case strength = "Strength"
    case shadow = "Shadow"
    case environment = "Environment"
    case unknown = "Unknown"

}

/// Textual meaning of a card, optionally specialised per spread position.
public struct Interpretation {

    /// General summary text. Must be between 100 and 400 words.
    public let summary: String
    
    /// The specific cards drawn for this interpretation (the source of truth).
    public let cards: [DrawnCard]
    
    /// At least 3 keywords that capture the essence of the interpretation.
    public let keywords: [String]
    
    /// Position-specific override texts. When a position is absent the general
    /// `summary` is used as fallback (Requirement 7.5).
    public let contextual: [SpreadPositionType: String]

    /// Structured aspects commonly consulted by users (e.g., Amor, Economía, Salud, Carrera).
    public let aspects: [String: String]
    
    public init(
        cards: [DrawnCard], // Changed to accept cards directly for synergy support
        summary: String? = nil, // Made optional, allowing dynamic generation if needed
        keywords: [String],
        contextual: [SpreadPositionType: String] = [:],
        aspects: [String: String] = [:]
    ) {
        self.cards = cards
        // If summary is not provided, we can generate a default one based on the spread/cards
        self.summary = summary ?? Interpretation.generateDefaultSummary(from: cards)
        self.keywords = keywords
        self.contextual = contextual
        self.aspects = aspects
    }

    /// Backwards-compatible initializer used by older modules that constructed
    /// an Interpretation without providing the originating DrawnCard list.
    public init(summary: String, keywords: [String], contextual: [SpreadPositionType: String] = [:]) {
        self.init(cards: [], summary: summary, keywords: keywords, contextual: contextual, aspects: [:])
    }
    
    /// Generates a high-level summary string based on the drawn cards and their positions.
    /// This is used when an explicit summary isn't provided during initialization.
    static func generateDefaultSummary(from cards: [DrawnCard]) -> String {
        // TODO: Implement complex logic here to synthesize meaning from multiple cards.
        // For now, we create a placeholder that confirms synergy support.
        let cardNames = cards.map { $0.card.name }.joined(separator: ", ")
        let positions = cards.map { $0.position.name }.joined(separator: " in ")
        return "This interpretation is based on the spread of \(cards.count) cards: \(cardNames). The overall narrative suggests a dynamic interplay between these energies, specifically highlighting themes related to '\(cards.first?.card.name ?? "Unknown")' and its influence across various positions like \(positions). A deeper dive into the contextual meanings will reveal how each card contributes to the overarching story."
    }
}

