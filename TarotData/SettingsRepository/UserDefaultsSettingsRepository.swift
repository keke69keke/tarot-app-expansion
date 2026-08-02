import Foundation
import TarotCore

/// UserDefaults-based implementation of SettingsRepository.
/// Persists UserSettings properties using UserDefaults as the storage mechanism.
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5.
public class UserDefaultsSettingsRepository: SettingsRepository {
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let allowReversedCards = "allowReversedCards"
        static let selectedLanguage = "selectedLanguage"
        static let cardBackDesign = "cardBackDesign"
        static let activeDeck = "activeDeck"
        static let appearance = "appearance"
        static let dailyNotificationHour = "dailyNotificationHour"
        static let notificationsEnabled = "notificationsEnabled"
        static let activeTabs = "activeTabs"
        static let inactiveTabs = "inactiveTabs"
        static let openAIKey = "openAIKey"
    }
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    /// Initializes the repository with the specified UserDefaults instance.
    /// - Parameter userDefaults: The UserDefaults instance to use for persistence. Defaults to .standard.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - SettingsRepository Protocol
    
    /// Returns the current stored settings, or the default `UserSettings` if none are saved yet.
    public func load() -> UserSettings {
        let allowReversedCards = userDefaults.object(forKey: Keys.allowReversedCards) as? Bool ?? UserSettings().allowReversedCards
        
        let languageRawValue = userDefaults.string(forKey: Keys.selectedLanguage) ?? UserSettings().selectedLanguage.rawValue
        let selectedLanguage = Language(rawValue: languageRawValue) ?? UserSettings().selectedLanguage
        
        let cardBackRawValue = userDefaults.string(forKey: Keys.cardBackDesign) ?? UserSettings().cardBackDesign.rawValue
        let cardBackDesign = CardBackDesign(rawValue: cardBackRawValue) ?? UserSettings().cardBackDesign
        
        let activeDeckRawValue = userDefaults.string(forKey: Keys.activeDeck) ?? UserSettings().activeDeck.rawValue
        let activeDeck = DeckType(rawValue: activeDeckRawValue) ?? UserSettings().activeDeck

        let appearanceRawValue = userDefaults.string(forKey: Keys.appearance) ?? UserSettings().appearance.rawValue
        let appearance = Appearance(rawValue: appearanceRawValue) ?? UserSettings().appearance

        let dailyNotificationHour = userDefaults.object(forKey: Keys.dailyNotificationHour) as? Int ?? UserSettings().dailyNotificationHour
        
        let notificationsEnabled = userDefaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? UserSettings().notificationsEnabled
        
        let activeTabsRaw = userDefaults.stringArray(forKey: Keys.activeTabs) ?? UserSettings().activeTabs.map { $0.rawValue }
        let activeTabs = activeTabsRaw.compactMap { AppTab(rawValue: $0) }
        
        let inactiveTabsRaw = userDefaults.stringArray(forKey: Keys.inactiveTabs) ?? UserSettings().inactiveTabs.map { $0.rawValue }
        let inactiveTabs = inactiveTabsRaw.compactMap { AppTab(rawValue: $0) }
        
        let openAIKey = userDefaults.string(forKey: Keys.openAIKey) ?? ""
        
        return UserSettings(
            allowReversedCards: allowReversedCards,
            selectedLanguage: selectedLanguage,
            cardBackDesign: cardBackDesign,
            activeDeck: activeDeck,
            appearance: appearance,
            dailyNotificationHour: dailyNotificationHour,
            notificationsEnabled: notificationsEnabled,
            openAIKey: openAIKey,
            activeTabs: activeTabs.isEmpty ? UserSettings().activeTabs : activeTabs,
            inactiveTabs: inactiveTabs
        )
    }
    
    /// Persists the given settings immediately.
    public func save(_ settings: UserSettings) {
        userDefaults.set(settings.allowReversedCards, forKey: Keys.allowReversedCards)
        userDefaults.set(settings.selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
        userDefaults.set(settings.cardBackDesign.rawValue, forKey: Keys.cardBackDesign)
        userDefaults.set(settings.activeDeck.rawValue, forKey: Keys.activeDeck)
        userDefaults.set(settings.appearance.rawValue, forKey: Keys.appearance)
        userDefaults.set(settings.dailyNotificationHour, forKey: Keys.dailyNotificationHour)
        userDefaults.set(settings.notificationsEnabled, forKey: Keys.notificationsEnabled)
        userDefaults.set(settings.activeTabs.map { $0.rawValue }, forKey: Keys.activeTabs)
        userDefaults.set(settings.inactiveTabs.map { $0.rawValue }, forKey: Keys.inactiveTabs)
        userDefaults.set(settings.openAIKey, forKey: Keys.openAIKey)
        
        // Force synchronization to disk
        userDefaults.synchronize()
    }
}