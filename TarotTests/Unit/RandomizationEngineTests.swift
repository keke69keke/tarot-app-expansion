// Feature: tarot-iphone-app
// Tests: Properties 1, 2, 10 (RandomizationEngine)
// Implemented in Task 2.

import XCTest
import SwiftCheck
import TarotCore
import TarotData
import CoreGraphics

final class RandomizationEngineTests: XCTestCase {

    // MARK: - Property 1: Selección sin repetición
    
    /// **Validates: Requirements 1.2**
    ///
    /// For any draw size N in 1…78:
    /// 1. Result count == N
    /// 2. All card IDs are unique (no duplicates)
    /// 3. All card IDs are in range 0…77
    func testProperty1_noRepetition() {
        // Feature: tarot-iphone-app, Property 1: Selección sin repetición
        property("no repeated cards in draw") <- forAll(Gen<Int>.choose((1, 78))) { count in
            let engine = SystemRandomizationEngine.withPlaceholderDeck()
            let positions = (0..<count).map { i in
                SpreadPosition(id: .daily, displayName: "Pos \(i)", layoutCoordinate: .zero)
            }
            let drawn = engine.drawCards(count: count, allowReversed: false, positions: positions)
            let ids = drawn.map { $0.card.id }
            return drawn.count == count
                && Set(ids).count == count
                && ids.allSatisfy { (0...77).contains($0) }
        }
    }

    // MARK: - Property 2: Distribución estadística de cartas invertidas

    /// Validates: Requirements 1.3
    ///
    /// Run 1000 single-card extractions with `allowReversed: true` and verify the
    /// proportion of reversed cards falls in [0.20, 0.40] — a wide tolerance
    /// chosen to keep the statistical assertion free from flakiness.
    func testProperty2_reversedDistribution() {
        // Feature: tarot-iphone-app, Property 2: Distribución estadística de cartas invertidas
        let engine = SystemRandomizationEngine.withPlaceholderDeck()
        let position = SpreadPosition(id: .daily, displayName: "Daily", layoutCoordinate: .zero)
        let trials = 1000
        var reversedCount = 0
        for _ in 0..<trials {
            let drawn = engine.drawCards(count: 1, allowReversed: true, positions: [position])
            if drawn.first?.isReversed == true { reversedCount += 1 }
        }
        let proportion = Double(reversedCount) / Double(trials)
        XCTAssertGreaterThanOrEqual(proportion, 0.20, "Reversed proportion \(proportion) below expected minimum 0.20")
        XCTAssertLessThanOrEqual(proportion, 0.40, "Reversed proportion \(proportion) above expected maximum 0.40")
    }

    // MARK: - Property 10: Configuración de cartas invertidas afecta la selección

    /// **Validates: Requirements 1.3, 6.3**
    ///
    /// For any draw size N in 1…78, when `allowReversed: false`, every card in
    /// the result has `isReversed == false`.
    func testProperty10_noReversedWhenDisabled() {
        // Feature: tarot-iphone-app, Property 10: Configuración de cartas invertidas afecta la selección
        property("allowReversed false means no reversed cards") <- forAll(Gen<Int>.choose((1, 78))) { count in
            let engine = SystemRandomizationEngine.withPlaceholderDeck()
            let positions = (0..<count).map { i in
                SpreadPosition(id: .daily, displayName: "Pos \(i)", layoutCoordinate: .zero)
            }
            let drawn = engine.drawCards(count: count, allowReversed: false, positions: positions)
            return drawn.allSatisfy { !$0.isReversed }
        }
    }
}
