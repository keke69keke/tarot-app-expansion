// Feature: tarot-iphone-app
// Tests: Properties 4, 5 (CardRepository completeness and search correctness)
// Implemented in Tasks 3.3 and 3.4.

import XCTest
import SwiftCheck
@testable import TarotCore
@testable import TarotData
@testable import TarotContent

final class CardRepositoryTests: XCTestCase {

    // MARK: - Property 4: Completitud de datos de cartas
    
    /// **Validates: Requirements 2.2, 2.5, 7.1**
    func testProperty4_cardDataCompleteness() throws {
        // Feature: tarot-iphone-app, Property 4: Completitud de datos de cartas
        // For SPM tests, load cards.json directly from the file system
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        let cardsJSONPath = "\(currentDirectoryPath)/TarotContent/Resources/cards.json"
        
        guard fileManager.fileExists(atPath: cardsJSONPath) else {
            XCTFail("cards.json not found at expected path: \(cardsJSONPath)")
            return
        }
        
        // Read and decode cards.json directly
        let data = try Data(contentsOf: URL(fileURLWithPath: cardsJSONPath))
        let decoder = JSONDecoder()
        
        // Define a simple DTO to parse the cards
        struct CardCatalog: Codable {
            let cards: [CardData]
        }
        
        struct CardData: Codable {
            let id: Int
            let name: String
            let imageName: String
            let upright: MeaningData
            let reversed: MeaningData
        }
        
        struct MeaningData: Codable {
            let summary: String
            let keywords: [String]
        }
        
        let catalog = try decoder.decode(CardCatalog.self, from: data)
        let allCards = catalog.cards
        
        XCTAssertEqual(allCards.count, 78, "Should have exactly 78 cards")
        
        property("all cards have complete data") <- forAll(Gen<Int>.choose((0, 77))) { cardId in
            guard let card = allCards.first(where: { $0.id == cardId }) else {
                return false
            }
            
            // Name not empty
            guard !card.name.isEmpty else { return false }
            
            // Image name not empty
            guard !card.imageName.isEmpty else { return false }
            
            // Upright summary 100-400 words
            let uprightWords = card.upright.summary.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard uprightWords.count >= 100 && uprightWords.count <= 400 else { return false }
            
            // Reversed summary 100-400 words
            let reversedWords = card.reversed.summary.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard reversedWords.count >= 100 && reversedWords.count <= 400 else { return false }
            
            // At least 3 keywords for each orientation
            guard card.upright.keywords.count >= 3 else { return false }
            guard card.reversed.keywords.count >= 3 else { return false }
            
            return true
        }
    }

    // MARK: - Property 5: Corrección de búsqueda de cartas

    /// **Validates: Requirement 2.3**
    func testProperty5_cardSearchFindsExactNameNumberAndSuit() throws {
        // Feature: tarot-iphone-app, Property 5: Corrección de búsqueda de cartas
        let repository = try BundleCardRepository(bundle: .tarotContent)
        let cards = repository.allCards()
 
        property("search returns every card for its supported exact queries") <-
            forAll(Gen<Int>.choose((0, 77))) { cardID in
                guard let card = cards.first(where: { $0.id == cardID }) else {
                    return false
                }
 
                guard repository.search(query: card.name).contains(card) else {
                    return false
                }
 
                if let number = card.number,
                   !repository.search(query: number).contains(card) {
                    return false
                }
 
                if let suit = card.suit,
                   !repository.search(query: suit.rawValue).contains(card) {
                    return false
                }
 
                return true
            }
    }

    func testProperty6_cardContextualAndAspectsResolveCorrectly() throws {
        let repository = try BundleCardRepository(bundle: .tarotContent)
        let cards = repository.allCards()
        guard let fool = cards.first(where: { $0.id == 0 }) else {
            XCTFail("No se encontró la carta El Loco")
            return
        }

        XCTAssertFalse(fool.uprightMeaning.contextual.isEmpty, "La carta debe incluir interpretaciones contextuales")
        XCTAssertNotNil(fool.uprightMeaning.contextual[.past], "La carta debe tener un significado para la posición Pasado")
        XCTAssertFalse(fool.uprightMeaning.aspects.isEmpty, "La carta debe incluir aspectos estructurados")
        XCTAssertNotNil(fool.uprightMeaning.aspects["Amor"], "Los aspectos deben incluir Amor")
        XCTAssertNotNil(fool.uprightMeaning.aspects["Economía"], "Los aspectos deben incluir Economía")
        XCTAssertNotNil(fool.uprightMeaning.aspects["Salud"], "Los aspectos deben incluir Salud")
        XCTAssertNotNil(fool.uprightMeaning.aspects["Carrera"], "Los aspectos deben incluir Carrera")

        let pastInterpretation = repository.interpretation(for: fool, position: SpreadPosition(name: "Past"), orientation: .upright)
        XCTAssertEqual(pastInterpretation.summary, fool.uprightMeaning.contextual[.past])
    }
}
