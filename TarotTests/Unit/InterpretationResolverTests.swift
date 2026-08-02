// Feature: tarot-iphone-app
// Tests: Property 3 (Interpretation fallback)
// Implemented in Task 3.5.

import XCTest
import SwiftCheck
@testable import TarotCore
@testable import TarotData
@testable import TarotContent

final class InterpretationResolverTests: XCTestCase {

    /// **Validates: Requirements 1.4, 7.5**
    func testProperty3_interpretationIsAlwaysAvailable() throws {
        // Feature: tarot-iphone-app, Property 3: Interpretación siempre disponible (fallback)
        let repository = try BundleCardRepository(bundle: .tarotContent)
        let cards = repository.allCards()
        let positions = SpreadType.allCases.flatMap(\.positions)

        property("every card and position resolves to a non-empty interpretation") <-
            forAll(
                Gen<Int>.choose((0, 77)),
                Gen<Int>.choose((0, positions.count))
            ) { cardID, positionIndex in
                guard let card = cards.first(where: { $0.id == cardID }) else {
                    return false
                }

                let position = positionIndex == positions.count
                    ? nil
                    : positions[positionIndex]

                return [CardOrientation.upright, .reversed].allSatisfy {
                    !repository.interpretation(for: card, position: position, orientation: $0)
                        .summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            }
    }
}
