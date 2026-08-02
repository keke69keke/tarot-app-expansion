import Foundation

/// Persistent storage for the user's journal of saved Tarot readings (Requirement 3).
public protocol JournalRepository {

    /// Persists a journal entry.
    ///
    /// - Throws: `TarotError.persistenceFailed` on CoreData / CloudKit failure.
    func save(entry: JournalEntry) throws

    /// Returns all saved entries sorted descending by `savedAt` (most recent first).
    ///
    /// Satisfies Requirement 3.4.
    func fetchAll() -> [JournalEntry]

    /// Returns the entry with the given identifier, or `nil` if it does not exist.
    func fetch(id: UUID) -> JournalEntry?

    /// Permanently removes the entry with the given identifier.
    ///
    /// - Throws: `TarotError.persistenceFailed` on failure.
    func delete(id: UUID) throws
}
