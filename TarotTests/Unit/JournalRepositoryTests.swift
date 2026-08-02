// Feature: tarot-iphone-app
// Tests: Properties 6, 7 (JournalRepository persistence and ordering)
// Implemented in Tasks 5.3 and 5.4.

import XCTest
@testable import TarotCore
@testable import TarotData

final class JournalRepositoryTests: XCTestCase {
    func testRoundTripAndDescendingOrder() throws {
        let repository = CoreDataJournalRepository(inMemory: true)
        let first = JournalEntry(id: UUID(), spread: sampleSpread(), savedAt: Date(timeIntervalSince1970: 1), notes: "Primera nota")
        let second = JournalEntry(id: UUID(), spread: sampleSpread(), savedAt: Date(timeIntervalSince1970: 2), notes: "Segunda nota")
        try repository.save(entry: first)
        try repository.save(entry: second)

        XCTAssertEqual(repository.fetch(id: first.id)?.notes, "Primera nota")
        XCTAssertEqual(repository.fetchAll().map(\.id), [second.id, first.id])
        try repository.delete(id: first.id)
        XCTAssertNil(repository.fetch(id: first.id))
    }

    private func sampleSpread() -> Spread {
        let meaning = Interpretation(summary: "Una interpretación de prueba suficientemente detallada para conservar el diario local de forma segura y verificar su persistencia.", keywords: ["prueba", "diario", "tarot"])
        let card = Card(id: 0, name: "El Loco", number: "0", suit: nil, arcanaType: .major, imageName: "card_00_the_fool", uprightMeaning: meaning, reversedMeaning: meaning)
        let position = SpreadPosition(id: .daily, displayName: "Carta del Día", layoutCoordinate: .zero)
        return Spread(type: .dailyCard, drawnCards: [DrawnCard(card: card, isReversed: false, position: position)])
    }
}

// Tests will be added in Tasks 5.3 and 5.4.
