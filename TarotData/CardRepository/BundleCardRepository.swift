import Foundation
import TarotCore

// MARK: - BundleCardRepository

/// Loads the card catalog from cards.json in the bundle and implements CardRepository.
public final class BundleCardRepository: CardRepository {
    
    private let cards: [Card]
    
    /// Initializes the repository by loading and decoding cards.json from the given bundle.
    ///
    /// - Parameter bundle: The bundle containing cards.json (defaults to .main).
    /// - Throws: `TarotError.contentLoadFailed` if the file cannot be loaded or decoded.
    public init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "cards", withExtension: "json") else {
            throw TarotError.contentLoadFailed(
                underlying: NSError(
                    domain: "BundleCardRepository",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "cards.json not found in bundle"]
                )
            )
        }
        
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw TarotError.contentLoadFailed(underlying: error)
        }
        
        let catalogDTO: CardCatalogDTO
        do {
            catalogDTO = try JSONDecoder().decode(CardCatalogDTO.self, from: data)
        } catch {
            throw TarotError.contentLoadFailed(underlying: error)
        }
        
        // Convert DTOs to domain models and sort by id
        self.cards = catalogDTO.cards.map { $0.toDomain() }.sorted { $0.id < $1.id }
    }
    
    // MARK: - CardRepository Protocol
    
    public func allCards() -> [Card] {
        return cards
    }
    
    public func cards(in group: CardGroup) -> [Card] {
        switch group {
        case .majorArcana:
            return cards.filter { $0.arcanaType == .major }
        case .minorArcana(let suit):
            return cards.filter { $0.arcanaType == .minor && $0.suit == suit }
        }
    }
    
    public func search(query: String) -> [Card] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        
        var results: [(card: Card, relevance: Int)] = []
        
        for card in cards {
            var relevance = 0
            
            // Exact name match (highest relevance)
            if card.name.lowercased() == lowercaseQuery {
                relevance = 1000
            }
            // Name starts with query
            else if card.name.lowercased().hasPrefix(lowercaseQuery) {
                relevance = 500
            }
            // Name contains query
            else if card.name.lowercased().contains(lowercaseQuery) {
                relevance = 100
            }
            
            // Number match (if present)
            if let number = card.number, number.lowercased().contains(lowercaseQuery) {
                relevance += 50
            }
            
            // Suit match (for minor arcana)
            if let suit = card.suit, suit.rawValue.lowercased().contains(lowercaseQuery) {
                relevance += 25
            }
            
            if relevance > 0 {
                results.append((card: card, relevance: relevance))
            }
        }
        
        // Sort by relevance (highest first), then by id
        results.sort { lhs, rhs in
            if lhs.relevance != rhs.relevance {
                return lhs.relevance > rhs.relevance
            }
            return lhs.card.id < rhs.card.id
        }
        
        return results.map { $0.card }
    }
    
    public func interpretation(
        for card: Card,
        position: SpreadPosition?,
        orientation: CardOrientation
    ) -> Interpretation {
        // Select base interpretation based on orientation
        let baseInterpretation = orientation == .upright
            ? card.uprightMeaning
            : card.reversedMeaning
        
        // If no position specified, return the base interpretation
        guard let position = position else {
            return baseInterpretation
        }
        
        // Check if there's a contextual override for this position
        if let posType = SpreadPositionType(rawValue: position.name), let contextualText = baseInterpretation.contextual[posType] {
            // Build a DrawnCard to include as the source of the interpretation
            let drawn = DrawnCard(card: card, position: position, orientation: orientation)
            // Return interpretation with contextual text as summary
            return Interpretation(cards: [drawn], summary: contextualText, keywords: baseInterpretation.keywords, contextual: baseInterpretation.contextual)
        }
        
        // No contextual override, return base interpretation adapted to this draw
        let drawn = DrawnCard(card: card, position: position, orientation: orientation)
        return Interpretation(cards: [drawn], summary: baseInterpretation.summary, keywords: baseInterpretation.keywords, contextual: baseInterpretation.contextual)
    }
}

// MARK: - DTOs (Codable structures matching cards.json)

/// Root structure of cards.json
private struct CardCatalogDTO: Codable {
    let cards: [CardDTO]
}

/// DTO for a single card in cards.json
private struct CardDTO: Codable {
    let id: Int
    let name: String
    let arcanaType: String
    let imageName: String
    let upright: InterpretationDTO
    let reversed: InterpretationDTO
    let number: String?
    let suit: String?
    let bookContent: String?
    let astrology: String?
    let kabbalah: String?
    let numerology: String?
    let element: String?
    let lightShadow: String?
    
    // Phase 3 Extensions
    let yesNo: String?
    let chakras: String?
    let crystals: String?
    let affirmation: String?
    let mythology: String?
    let zodiacalDecan: String?
    
    /// Converts this DTO to a domain Card model
    func toDomain() -> Card {
        let arcanaType: ArcanaType = self.arcanaType == "major" ? .major : .minor
        let suit: CardSuit? = self.suit.flatMap { CardSuit(rawValue: $0) }
        
        return Card(
            id: id,
            name: name,
            number: number,
            suit: suit,
            arcanaType: arcanaType,
            imageName: imageName,
            uprightMeaning: upright.toDomain(),
            reversedMeaning: reversed.toDomain(),
            bookContent: bookContent,
            astrology: astrology,
            kabbalah: kabbalah,
            numerology: numerology,
            element: element,
            lightShadow: lightShadow,
            yesNo: yesNo,
            chakras: chakras,
            crystals: crystals,
            affirmation: affirmation,
            mythology: mythology,
            zodiacalDecan: zodiacalDecan
        )
    }
}

/// DTO for card interpretation in cards.json
private struct InterpretationDTO: Codable {
    let summary: String
    let keywords: [String]
    let contextual: [String: String]
    let aspects: [String: String]?
    
    /// Converts this DTO to a domain Interpretation model
    func toDomain() -> Interpretation {
        // Map string keys from JSON to SpreadPositionType enum values
        var contextualMap: [SpreadPositionType: String] = [:]
        
        for (key, value) in contextual {
            if let positionType = SpreadPositionType.from(key) {
                contextualMap[positionType] = value
            }
        }
        
        return Interpretation(cards: [], summary: summary, keywords: keywords, contextual: contextualMap, aspects: aspects ?? [:])
    }
}
