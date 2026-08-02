import Foundation

/// A saved Tarot reading in the user's personal journal (Requirement 3).
public struct JournalEntry: Identifiable {

    public let id: UUID
    public let spread: TarotCore.Spread
    public let savedAt: Date

    /// Personal reflections. Maximum 2 000 characters (Requirement 3.2).
    public var notes: String

    /// Whether this entry has been synced to the user's iCloud account (Requirement 3.7).
    public var isSyncedToCloud: Bool

    public init(
        id: UUID = UUID(),
        spread: TarotCore.Spread,
        savedAt: Date = Date(),
        notes: String = "",
        isSyncedToCloud: Bool = false
    ) {
        // Enforce the 2 000-character limit defensively.
        self.id = id
        self.spread = spread
        self.savedAt = savedAt
        self.notes = String(notes.prefix(2000))
        self.isSyncedToCloud = isSyncedToCloud
    }
}
