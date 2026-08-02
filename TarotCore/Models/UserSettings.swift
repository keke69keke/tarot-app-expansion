import Foundation

// MARK: - UserSettings

/// Persistent user preferences (Requirements 6.1 – 6.5).
public struct UserSettings {

    /// Whether reversed cards can appear during a spread (Requirement 6.3).
    public var allowReversedCards: Bool = true

    /// Display language for card interpretations (Requirement 6.4).
    public var selectedLanguage: Language = .spanish

    /// Visual design of the card back used in animations (Requirement 6.1).
    public var cardBackDesign: CardBackDesign = .classic

    /// Active card deck / artwork set (Requirement 6.2).
    public var activeDeck: DeckType = .riderWaite

    /// Preferred application appearance setting.
    /// The app supports automatic, light and dark appearances.
    public var appearance: Appearance = .automatic

    /// Hour (24-hour clock) at which the daily notification fires.
    /// Valid range: 6 … 22 (Requirement 4.6).
    public var dailyNotificationHour: Int = 8

    /// Whether daily push notifications are enabled (Requirement 4.6).
    public var notificationsEnabled: Bool = false

    /// OpenAI API Key for AI chat feature (optional).
    public var openAIKey: String = ""

    /// Active tabs in the bottom navigation menu
    public var activeTabs: [AppTab] = [.reading, .daily, .reference, .book, .journal, .settings]
    
    /// Inactive tabs hidden from the bottom navigation menu
    public var inactiveTabs: [AppTab] = [.ask, .horoscope, .library, .chat]

    public init(
        allowReversedCards: Bool = true,
        selectedLanguage: Language = .spanish,
        cardBackDesign: CardBackDesign = .classic,
        activeDeck: DeckType = .riderWaite,
        appearance: Appearance = .automatic,
        dailyNotificationHour: Int = 8,
        notificationsEnabled: Bool = false,
        openAIKey: String = "",
        activeTabs: [AppTab] = [.reading, .daily, .reference, .book, .journal, .settings],
        inactiveTabs: [AppTab] = [.ask, .horoscope, .library, .chat]
    ) {
        self.allowReversedCards = allowReversedCards
        self.selectedLanguage = selectedLanguage
        self.cardBackDesign = cardBackDesign
        self.activeDeck = activeDeck
        self.appearance = appearance
        self.dailyNotificationHour = dailyNotificationHour
        self.notificationsEnabled = notificationsEnabled
        self.openAIKey = openAIKey
        self.activeTabs = activeTabs
        self.inactiveTabs = inactiveTabs
    }
}

// MARK: - Appearance

/// Preferred theme for the application.
public enum Appearance: String, CaseIterable, Codable {
    case automatic
    case light
    case dark

    public var displayName: String {
        switch self {
        case .automatic: return "Automático"
        case .light: return "Claro"
        case .dark: return "Obscuro"
        }
    }
}

// MARK: - Language

/// Supported interpretation languages (Requirement 6.4).
public enum Language: String, CaseIterable, Codable {
    case spanish = "es"
    case english = "en"
 
    public var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }
}

// MARK: - CardBackDesign

/// Available card-back artwork options (Requirement 6.1).
public enum CardBackDesign: String, CaseIterable, Codable {
    case classic   = "classic"
    case mystical  = "mystical"

    public var displayName: String {
        switch self {
        case .classic: return "Clásico"
        case .mystical: return "Místico"
        }
    }
}

// MARK: - DeckType

/// Available card-front artwork decks (Requirement 6.2).
public enum DeckType: String, CaseIterable, Codable {
    case riderWaite = "riderWaite"
    case thoth      = "thoth"
    case helloKitty = "helloKitty"

    public var displayName: String {
        switch self {
        case .riderWaite: return "Rider-Waite"
        case .thoth: return "Thoth"
        case .helloKitty: return "Hello Kitty (Kawaii)"
        }
    }
}

// MARK: - AppTab

/// Available navigation tabs in the app.
public enum AppTab: String, CaseIterable, Codable, Identifiable {
    case reading = "reading"
    case ask = "ask"
    case horoscope = "horoscope"
    case library = "library"
    case reference = "reference"
    case daily = "daily"
    case book = "book"
    case journal = "journal"
    case settings = "settings"
    case chat = "chat"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .reading: return "Tirada"
        case .ask: return "Preguntar"
        case .horoscope: return "Horóscopo"
        case .library: return "Biblioteca"
        case .reference: return "Referencia"
        case .daily: return "Hoy"
        case .book: return "Aprender"
        case .journal: return "Diario"
        case .settings: return "Ajustes"
        case .chat: return "Arcana IA"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .reading: return "sparkles"
        case .ask: return "bubble.left.and.bubble.right"
        case .horoscope: return "moon.stars"
        case .library: return "books.vertical"
        case .reference: return "magnifyingglass"
        case .daily: return "sun.max"
        case .book: return "book.pages"
        case .journal: return "book.closed"
        case .settings: return "gearshape"
        case .chat: return "brain.head.profile"
        }
    }
}
