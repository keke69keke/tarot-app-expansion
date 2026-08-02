# TarotData

This module contains:

- `BundleCardRepository` — loads `cards.json` from `TarotContent` bundle into memory.
- `CoreDataJournalRepository` — persists journal entries via CoreData + `NSPersistentCloudKitContainer`.
- `UserDefaultsSettingsRepository` — persists `UserSettings` via `UserDefaults`.
- `TarotJournal.xcdatamodeld` — CoreData model with `JournalEntryCD` and `DrawnCardCD` entities.

> Implemented in Task 3, 5, and 7 of the implementation plan.
