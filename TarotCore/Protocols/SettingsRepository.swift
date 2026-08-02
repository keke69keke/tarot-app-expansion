import Foundation

/// Persists and retrieves user preferences (Requirements 6.1 – 6.5).
public protocol SettingsRepository {

    /// Returns the current stored settings, or the default `UserSettings` if none are saved yet.
    func load() -> UserSettings

    /// Persists the given settings immediately.
    func save(_ settings: UserSettings)
}
