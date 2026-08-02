// Feature: tarot-iphone-app
// Smoke tests: card catalogue completeness and spread position counts.
// Implemented in Task 12.2.

import XCTest
@testable import TarotCore
@testable import TarotData
@testable import TarotContent

final class CardCatalogSmokeTests: XCTestCase {

    func testCardCatalogContainsAll78CardsWithValidFields() throws {
        let repo = try BundleCardRepository(bundle: .tarotContent)
        let cards = repo.allCards()

        XCTAssertEqual(cards.count, 78, "El catálogo completo debe contener exactamente 78 cartas del Tarot Rider-Waite")

        // 22 Major Arcana + 56 Minor Arcana (14 per suit)
        let majorArcana = cards.filter { $0.arcanaType == .major }
        let minorArcana = cards.filter { $0.arcanaType == .minor }

        XCTAssertEqual(majorArcana.count, 22, "Deben existir 22 cartas de Arcanos Mayores")
        XCTAssertEqual(minorArcana.count, 56, "Deben existir 56 cartas de Arcanos Menores")

        // Check for unique IDs from 0 to 77
        let ids = Set(cards.map(\.id))
        XCTAssertEqual(ids.count, 78, "Todas las cartas deben tener un ID único")

        for card in cards {
            XCTAssertFalse(card.name.isEmpty, "El nombre de la carta \(card.id) no debe estar vacío")
            XCTAssertFalse(card.imageName.isEmpty, "El imageName de la carta \(card.id) no debe estar vacío")
            XCTAssertFalse(card.uprightMeaning.summary.isEmpty, "El resumen derecho de \(card.name) no debe estar vacío")
            XCTAssertFalse(card.reversedMeaning.summary.isEmpty, "El resumen invertido de \(card.name) no debe estar vacío")
            XCTAssertGreaterThanOrEqual(card.uprightMeaning.keywords.count, 3, "La carta \(card.name) debe tener al menos 3 palabras clave")
        }
    }

    func testCardImageResourcesExistInBundle() throws {
        let repo = try BundleCardRepository(bundle: .tarotContent)
        let cards = repo.allCards()
        for card in cards {
            let cleanName = card.imageName.replacingOccurrences(of: ".png", with: "")
            let url = Bundle.tarotContent.url(forResource: cleanName, withExtension: "png")
            XCTAssertNotNil(url, "La imagen \(cleanName).png debe existir en el bundle TarotContent")
        }
    }

    func testPredefinedSpreadsHaveCorrectPositionCounts() {
        XCTAssertEqual(SpreadType.dailyCard.positions.count, 1)
        XCTAssertEqual(SpreadType.threeCard.positions.count, 3)
        XCTAssertEqual(SpreadType.fiveCard.positions.count, 5)
        XCTAssertEqual(SpreadType.horseshoe.positions.count, 7)
        XCTAssertEqual(SpreadType.relationship.positions.count, 7)
        XCTAssertEqual(SpreadType.celticCross.positions.count, 10)
        XCTAssertEqual(SpreadType.twelveMonth.positions.count, 12)
        XCTAssertEqual(SpreadType.decision.positions.count, 4)
        XCTAssertEqual(SpreadType.pathOfLife.positions.count, 9)

        for spreadType in SpreadType.allCases {
            XCTAssertFalse(spreadType.positions.isEmpty, "Las posiciones de \(spreadType) no deben estar vacías")
            for position in spreadType.positions {
                XCTAssertFalse(position.displayName.isEmpty, "El nombre a mostrar de la posición no debe estar vacío")
            }
        }
    }
}
