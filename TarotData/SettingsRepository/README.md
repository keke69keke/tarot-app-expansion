# SettingsRepository

This module implements persistent storage for user preferences using iOS's UserDefaults system.

## UserDefaultsSettingsRepository

A concrete implementation of the `SettingsRepository` protocol that persists `UserSettings` to UserDefaults.

### Features

- **Complete persistence**: Stores all UserSettings properties (language, card back design, active deck, notification hour, allowReversedCards, notificationsEnabled)
- **Robust default handling**: Returns sensible defaults when no settings have been saved yet
- **Type safety**: Validates enum values and falls back to defaults for corrupted data
- **Immediate synchronization**: Calls `synchronize()` to ensure data is written to disk
- **Testable**: Accepts custom UserDefaults instance for testing isolation

### Usage

```swift
let repository = UserDefaultsSettingsRepository()

// Load current settings (returns defaults if none saved)
let settings = repository.load()

// Save modified settings
var newSettings = settings
newSettings.allowReversedCards = false
newSettings.selectedLanguage = .english
repository.save(newSettings)
```

### Requirements Validation

This implementation validates the following requirements:

- **6.1**: Card back design persistence
- **6.2**: Active deck selection persistence  
- **6.3**: Allow reversed cards setting persistence
- **6.4**: Language preference persistence
- **6.5**: Immediate application of settings changes

### Testing

The implementation includes comprehensive tests:

- Unit tests for basic load/save operations
- Property-based tests verifying round-trip persistence
- Edge case handling for corrupted UserDefaults data
- Boundary testing for notification hour ranges

See `TarotTests/Integration/SettingsRepositoryTests.swift` for the complete test suite.