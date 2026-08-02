import Foundation
import TarotCore

public final class DeterministicDailyCardService: DailyCardService {
    private let cards: [Card]
    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(cards: [Card], userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.cards = cards; self.defaults = userDefaults; self.calendar = calendar
    }
    public func dailyCard(for date: Date) -> Card {
        precondition(!cards.isEmpty, "A daily card service needs a non-empty deck")
        let year = calendar.component(.year, from: date)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = year * 366 + day
        return cards[abs(seed) % cards.count]
    }
    public func isRevealed(for date: Date) -> Bool { defaults.bool(forKey: key(for: date)) }
    public func markRevealed(for date: Date) { defaults.set(true, forKey: key(for: date)) }
    private func key(for date: Date) -> String { "tarot.daily.revealed.\(calendar.startOfDay(for: date).timeIntervalSince1970)" }
}
