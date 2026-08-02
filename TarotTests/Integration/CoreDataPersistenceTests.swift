// Feature: tarot-iphone-app
// Tests: CoreData end-to-end persistence (Requirement 3.3, 3.5)

import XCTest
@testable import TarotCore
@testable import TarotData

final class CoreDataPersistenceTests: XCTestCase {
    var repository: CoreDataJournalRepository!

    override func setUp() {
        super.setUp()
        repository = CoreDataJournalRepository(inMemory: true)
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testSaveAndFetchSingleJournalEntry() throws {
        let entryId = UUID()
        let entry = makeSampleEntry(id: entryId, savedAt: Date(), notes: "Lectura matutina")
        
        try repository.save(entry: entry)
        
        let fetched = repository.fetch(id: entryId)
        XCTAssertNotNil(fetched, "La entrada guardada debe poder recuperarse por ID")
        XCTAssertEqual(fetched?.id, entryId)
        XCTAssertEqual(fetched?.notes, "Lectura matutina")
        XCTAssertEqual(fetched?.spread.drawnCards.count, 1)
        XCTAssertEqual(fetched?.spread.drawnCards.first?.card.name, "El Mago")
    }

    func testFetchAllReturnsEntriesInDescendingDateOrder() throws {
        let now = Date()
        let entryOlder = makeSampleEntry(id: UUID(), savedAt: now.addingTimeInterval(-3600), notes: "Antigua")
        let entryNewer = makeSampleEntry(id: UUID(), savedAt: now, notes: "Reciente")

        try repository.save(entry: entryOlder)
        try repository.save(entry: entryNewer)

        let allEntries = repository.fetchAll()
        XCTAssertEqual(allEntries.count, 2)
        XCTAssertEqual(allEntries.first?.id, entryNewer.id, "Las entradas deben devolverse en orden cronológico descendente")
        XCTAssertEqual(allEntries.last?.id, entryOlder.id)
    }

    func testDeleteEntryRemovesItFromStore() throws {
        let entryId = UUID()
        let entry = makeSampleEntry(id: entryId, savedAt: Date(), notes: "Para eliminar")

        try repository.save(entry: entry)
        XCTAssertNotNil(repository.fetch(id: entryId))

        try repository.delete(id: entryId)
        XCTAssertNil(repository.fetch(id: entryId), "La entrada eliminada no debe encontrarse en la base de datos")
        XCTAssertTrue(repository.fetchAll().isEmpty)
    }

    func testUpdateExistingEntryOverwritesPayload() throws {
        let entryId = UUID()
        let originalEntry = makeSampleEntry(id: entryId, savedAt: Date(), notes: "Nota original")
        try repository.save(entry: originalEntry)

        let updatedEntry = makeSampleEntry(id: entryId, savedAt: Date(), notes: "Nota modificada")
        try repository.save(entry: updatedEntry)

        let fetched = repository.fetch(id: entryId)
        XCTAssertEqual(fetched?.notes, "Nota modificada")
        XCTAssertEqual(repository.fetchAll().count, 1, "Guardar con el mismo ID debe actualizar y no duplicar")
    }

    // MARK: - Helpers

    private func makeSampleEntry(id: UUID, savedAt: Date, notes: String) -> JournalEntry {
        let meaning = Interpretation(
            summary: "Interpretación completa para test de integración con CoreData.",
            keywords: ["magia", "voluntad", "acción"]
        )
        let card = Card(
            id: 1,
            name: "El Mago",
            number: "I",
            suit: nil,
            arcanaType: .major,
            imageName: "card_01_the_magician",
            uprightMeaning: meaning,
            reversedMeaning: meaning
        )
        let position = SpreadPosition(id: .present, displayName: "Presente", layoutCoordinate: .zero)
        let drawnCard = DrawnCard(card: card, isReversed: false, position: position)
        let spread = Spread(type: .dailyCard, drawnCards: [drawnCard], createdAt: savedAt)
        return JournalEntry(id: id, spread: spread, savedAt: savedAt, notes: notes)
    }
}
