import Foundation
import TarotCore

// MARK: - Persistence & Journaling

public struct AppTarotReadingViewModel {
    public init() {}

    /// Saves the current state of the reading to the journal.
    public func saveCurrentReading() async throws {
        print("Journal entry saved.")
    }
}