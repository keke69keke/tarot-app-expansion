import Foundation

// Removed duplicate DrawCardsUseCase definition; use the one in DrawCardsUseCase.swift instead.

public struct SaveToJournalUseCase {
    private let repository: any JournalRepository // Assuming this protocol exists
    public init(repository: any JournalRepository) { self.repository = repository }
    public func execute(entry: JournalEntry) throws { try repository.save(entry: entry) }
}

public struct DeleteJournalEntryUseCase {
    private let repository: any JournalRepository // Assuming this protocol exists
    public init(repository: any JournalRepository) { self.repository = repository }
    public func execute(id: UUID) throws { try repository.delete(id: id) }
}

public struct SearchCardsUseCase {
    private let repository: any CardRepository // Assuming this protocol exists
    public init(repository: any CardRepository) { self.repository = repository }
    public func execute(query: String) -> [Card] { repository.search(query: query) }
}

public struct GetDailyCardUseCase {
    private let service: any DailyCardService // Assuming this protocol exists
    public init(service: any DailyCardService) { self.service = service }
    public func execute(for date: Date = .now) -> Card { service.dailyCard(for: date) }
}

public struct RevealDailyCardUseCase {
    private let service: any DailyCardService // Assuming this protocol exists
    public init(service: any DailyCardService) { self.service = service }
    public func execute(for date: Date = .now) { service.markRevealed(for: date) }
}

// --- Supporting Types (Ensure these are defined in TarotApp.Core.Models or Services!) ---
// NOTE: We assume SpreadType is now renamed to 'Spread' and that the engine has a method called 'drawRandomCards'.

