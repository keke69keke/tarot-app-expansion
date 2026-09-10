import Foundation

/// A single Tarot card from the 78-card Rider-Waite deck.
public struct Card: Identifiable, Hashable {

    /// Unique identifier in the range 0…77.
    /// 0–21: Major Arcana; 22–77: Minor Arcana (grouped by suit).
    public let id: Int

    /// Display name, e.g. "El Loco", "As de Bastos".
    public let name: String

    /// Roman or Arabic numeral string where applicable (nil for most Minor Arcana pip cards).
    public let number: String?

    /// Suit for Minor Arcana cards; nil for Major Arcana.
    public let suit: CardSuit?

    /// Arcana classification.
    public let arcanaType: ArcanaType

    /// Name of the image asset in the asset catalog or bundle.
    public let imageName: String

    /// Interpretation when the card is drawn in the upright orientation.
    public let uprightMeaning: Interpretation

    /// Interpretation when the card is drawn in the reversed (inverted) orientation.
    public let reversedMeaning: Interpretation

    /// Content extracted from the Rider-Waite Guía Definitiva book via OCR (Fiebig & Bürger).
    public let bookContent: String?
    
    // MARK: - Encyclopedic Data
    
    /// Astrological correspondence (e.g., "Aries", "Uranus").
    public let astrology: String?
    
    /// Kabbalistic path or association on the Tree of Life.
    public let kabbalah: String?
    
    /// Numerological significance.
    public let numerology: String?
    
    /// Associated element (Fire, Water, Air, Earth).
    public let element: String?
    
    /// Deep dive into the light vs shadow aspects of the card.
    public let lightShadow: String?
    
    // Phase 3 Extensions
    public let yesNo: String?
    public let chakras: String?
    public let crystals: String?
    public let affirmation: String?
    public let mythology: String?
    public let zodiacalDecan: String?

    public init(
        id: Int,
        name: String,
        number: String?,
        suit: CardSuit?,
        arcanaType: ArcanaType,
        imageName: String,
        uprightMeaning: Interpretation,
        reversedMeaning: Interpretation,
        bookContent: String? = nil,
        astrology: String? = nil,
        kabbalah: String? = nil,
        numerology: String? = nil,
        element: String? = nil,
        lightShadow: String? = nil,
        yesNo: String? = nil,
        chakras: String? = nil,
        crystals: String? = nil,
        affirmation: String? = nil,
        mythology: String? = nil,
        zodiacalDecan: String? = nil
    ) {
        self.id = id
        self.name = name
        self.number = number
        self.suit = suit
        self.arcanaType = arcanaType
        self.imageName = imageName
        self.uprightMeaning = uprightMeaning
        self.reversedMeaning = reversedMeaning
        self.bookContent = bookContent
        self.astrology = astrology
        self.kabbalah = kabbalah
        self.numerology = numerology
        self.element = element
        self.lightShadow = lightShadow
        self.yesNo = yesNo
        self.chakras = chakras
        self.crystals = crystals
        self.affirmation = affirmation
        self.mythology = mythology
        self.zodiacalDecan = zodiacalDecan
    }

    // MARK: Hashable
    public static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Texture support (computed)
public extension Card {
    /// Computed texture image name. By convention, textures can be provided in
    /// the asset catalog using the card image name with a `_texture` suffix.
    /// This is a computed property so existing initializers are not affected.
    var textureImageName: String { "\(imageName)_texture" }
}