import Foundation

// MARK: - CardSuit

/// The four suits of the Minor Arcana.
public enum CardSuit: String, CaseIterable, Codable {
    case wands      = "wands"      // Bastos
    case cups       = "cups"       // Copas
    case swords     = "swords"     // Espadas
    case pentacles  = "pentacles"  // Oros
}

// MARK: - ArcanaType

/// Distinguishes Major from Minor Arcana cards.
public enum ArcanaType: String, Codable {
    case major
    case minor
}

// MARK: - CardGroup

/// Logical grouping used for browsing the card library.
public enum CardGroup: Hashable {
    case majorArcana
    case minorArcana(suit: CardSuit)
}

// MARK: - CardOrientation

/// Orientation at which a card was drawn during a spread.
public enum CardOrientation {
    case upright
    case reversed
}
