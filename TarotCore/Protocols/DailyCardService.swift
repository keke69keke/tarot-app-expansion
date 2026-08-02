import Foundation

/// Deterministic daily-card logic and revelation-state tracking (Requirement 4).
public protocol DailyCardService {

    /// Returns the daily card for `date`.
    ///
    /// The same `date` always produces the same card (deterministic by calendar day).
    /// Satisfies Requirements 4.1 and 4.5.
    func dailyCard(for date: Date) -> Card

    /// Whether the user has already revealed the card for `date`.
    func isRevealed(for date: Date) -> Bool

    /// Records that the user has revealed the card for `date`.
    func markRevealed(for date: Date)
}
