// SwiftCheck Arbitrary conformances for test generation
// This file provides property-based test support for domain enums.

import SwiftCheck
@testable import TarotCore

// MARK: - Language + Arbitrary

extension Language: Arbitrary {
    public static var arbitrary: Gen<Language> {
        return Gen<Language>.fromElements(of: Language.allCases)
    }
}

// MARK: - CardBackDesign + Arbitrary

extension CardBackDesign: Arbitrary {
    public static var arbitrary: Gen<CardBackDesign> {
        return Gen<CardBackDesign>.fromElements(of: CardBackDesign.allCases)
    }
}

// MARK: - DeckType + Arbitrary

extension DeckType: Arbitrary {
    public static var arbitrary: Gen<DeckType> {
        return Gen<DeckType>.fromElements(of: DeckType.allCases)
    }
}
