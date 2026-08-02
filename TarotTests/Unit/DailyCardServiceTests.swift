// Feature: tarot-iphone-app
// Tests: Property 8 (DailyCardService determinism)
// Implemented in Task 6.2.

import XCTest
@testable import TarotCore
@testable import TarotData

final class DailyCardServiceTests: XCTestCase {
    func testProperty8_sameCalendarDayAlwaysReturnsSameCard() {
        let defaults = UserDefaults(suiteName: "DailyCardServiceTests")!
        defaults.removePersistentDomain(forName: "DailyCardServiceTests")
        let service = DeterministicDailyCardService(cards: SystemRandomizationEngine.withPlaceholderDeck().drawCards(count: 78, allowReversed: false, positions: Array(repeating: SpreadType.dailyCard.positions[0], count: 78)).map(\.card), userDefaults: defaults)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(service.dailyCard(for: date).id, service.dailyCard(for: date.addingTimeInterval(3_600)).id)
        XCTAssertFalse(service.isRevealed(for: date))
        service.markRevealed(for: date)
        XCTAssertTrue(service.isRevealed(for: date))
    }
}
