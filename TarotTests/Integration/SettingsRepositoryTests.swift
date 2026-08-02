import XCTest
import SwiftCheck
@testable import TarotCore
@testable import TarotData

// MARK: - Arbitrary Conformances for Property-Based Testing

extension Language: Arbitrary {
    public static var arbitrary: Gen<Language> {
        return Gen<Language>.fromElements(of: Language.allCases)
    }
}

extension CardBackDesign: Arbitrary {
    public static var arbitrary: Gen<CardBackDesign> {
        return Gen<CardBackDesign>.fromElements(of: CardBackDesign.allCases)
    }
}

extension DeckType: Arbitrary {
    public static var arbitrary: Gen<DeckType> {
        return Gen<DeckType>.fromElements(of: DeckType.allCases)
    }
}

// MARK: - Tests

class UserDefaultsSettingsRepositoryTests: XCTestCase {
    
    var repository: UserDefaultsSettingsRepository!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Use a test suite name to avoid conflicts with app's UserDefaults
        testUserDefaults = UserDefaults(suiteName: "UserDefaultsSettingsRepositoryTests")!
        testUserDefaults.removePersistentDomain(forName: "UserDefaultsSettingsRepositoryTests")
        repository = UserDefaultsSettingsRepository(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: "UserDefaultsSettingsRepositoryTests")
        repository = nil
        testUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Unit Tests
    
    func testLoadDefaultSettings() {
        // When loading settings for the first time
        let settings = repository.load()
        
        // Should return default UserSettings values
        let defaultSettings = UserSettings()
        XCTAssertEqual(settings.allowReversedCards, defaultSettings.allowReversedCards)
        XCTAssertEqual(settings.selectedLanguage, defaultSettings.selectedLanguage)
        XCTAssertEqual(settings.cardBackDesign, defaultSettings.cardBackDesign)
        XCTAssertEqual(settings.activeDeck, defaultSettings.activeDeck)
        XCTAssertEqual(settings.dailyNotificationHour, defaultSettings.dailyNotificationHour)
        XCTAssertEqual(settings.notificationsEnabled, defaultSettings.notificationsEnabled)
    }
    
    func testSaveAndLoadSettings() {
        // Given custom settings
        let customSettings = UserSettings(
            allowReversedCards: false,
            selectedLanguage: .english,
            cardBackDesign: .mystical,
            activeDeck: .thoth,
            dailyNotificationHour: 22,
            notificationsEnabled: true
        )
        
        // When saving and then loading
        repository.save(customSettings)
        let loadedSettings = repository.load()
        
        // Should retrieve the same values
        XCTAssertEqual(loadedSettings.allowReversedCards, customSettings.allowReversedCards)
        XCTAssertEqual(loadedSettings.selectedLanguage, customSettings.selectedLanguage)
        XCTAssertEqual(loadedSettings.cardBackDesign, customSettings.cardBackDesign)
        XCTAssertEqual(loadedSettings.activeDeck, customSettings.activeDeck)
        XCTAssertEqual(loadedSettings.dailyNotificationHour, customSettings.dailyNotificationHour)
        XCTAssertEqual(loadedSettings.notificationsEnabled, customSettings.notificationsEnabled)
    }
    
    func testPartialSettingsUpdate() {
        // Given initial settings
        var settings = UserSettings()
        repository.save(settings)
        
        // When updating only one property
        settings.allowReversedCards = false
        settings.selectedLanguage = .english
        repository.save(settings)
        
        // Should preserve all other settings
        let loadedSettings = repository.load()
        XCTAssertEqual(loadedSettings.allowReversedCards, false)
        XCTAssertEqual(loadedSettings.selectedLanguage, .english)
        XCTAssertEqual(loadedSettings.cardBackDesign, UserSettings().cardBackDesign)
        XCTAssertEqual(loadedSettings.activeDeck, UserSettings().activeDeck)
        XCTAssertEqual(loadedSettings.dailyNotificationHour, UserSettings().dailyNotificationHour)
        XCTAssertEqual(loadedSettings.notificationsEnabled, UserSettings().notificationsEnabled)
    }
    
    // MARK: - Property-Based Test
    
    /// **Property 11: Persistencia de preferencias de usuario (round-trip)**
    /// **Validates: Requirements 6.4**
    func testPersistenceRoundTrip() {
        property("Settings round-trip preserves all values") <- forAll { (allowReversed: Bool) in
            forAll { (language: Language) in
                forAll { (cardBack: CardBackDesign) in
                    forAll { (deck: DeckType) in
                        forAll { (notifications: Bool) in
                            // Generate hour in valid range [6, 22]
                            let hour = Int.random(in: 6...22)
                            
                            // Given arbitrary user settings
                            let originalSettings = UserSettings(
                                allowReversedCards: allowReversed,
                                selectedLanguage: language,
                                cardBackDesign: cardBack,
                                activeDeck: deck,
                                dailyNotificationHour: hour,
                                notificationsEnabled: notifications
                            )
                            
                            // When saving and loading
                            self.repository.save(originalSettings)
                            let loadedSettings = self.repository.load()
                            
                            // Should be identical
                            return loadedSettings.allowReversedCards == originalSettings.allowReversedCards &&
                                   loadedSettings.selectedLanguage == originalSettings.selectedLanguage &&
                                   loadedSettings.cardBackDesign == originalSettings.cardBackDesign &&
                                   loadedSettings.activeDeck == originalSettings.activeDeck &&
                                   loadedSettings.dailyNotificationHour == originalSettings.dailyNotificationHour &&
                                   loadedSettings.notificationsEnabled == originalSettings.notificationsEnabled
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testInvalidEnumHandling() {
        // Given corrupted UserDefaults with invalid enum values
        testUserDefaults.set("invalidLanguage", forKey: "selectedLanguage")
        testUserDefaults.set("invalidCardBack", forKey: "cardBackDesign")
        testUserDefaults.set("invalidDeck", forKey: "activeDeck")
        
        // When loading settings
        let settings = repository.load()
        
        // Should fall back to default values
        XCTAssertEqual(settings.selectedLanguage, UserSettings().selectedLanguage)
        XCTAssertEqual(settings.cardBackDesign, UserSettings().cardBackDesign)
        XCTAssertEqual(settings.activeDeck, UserSettings().activeDeck)
    }
    
    func testNotificationHourBoundaries() {
        // Test valid boundary values
        let minHourSettings = UserSettings(dailyNotificationHour: 6)
        let maxHourSettings = UserSettings(dailyNotificationHour: 22)
        
        repository.save(minHourSettings)
        XCTAssertEqual(repository.load().dailyNotificationHour, 6)
        
        repository.save(maxHourSettings)
        XCTAssertEqual(repository.load().dailyNotificationHour, 22)
    }
}