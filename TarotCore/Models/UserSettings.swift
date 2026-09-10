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
    case classic      = "classic"
    case mystical     = "mystical"
    case celestial    = "celestial"
    case floral       = "floral"
    case alchemical   = "alchemical"
    case darkMoon     = "darkMoon"

    public var displayName: String {
        switch self {
        case .classic:    return "Clásico"
        case .mystical:   return "Místico"
        case .celestial:  return "Celestial"
        case .floral:     return "Floral Art Nouveau"
        case .alchemical: return "Alquímico"
        case .darkMoon:   return "Luna Oscura"
        }
    }

    /// Accent color used for UI indicators and glows.
    public var accentColor: (r: Double, g: Double, b: Double) {
        switch self {
        case .classic:    return (0.85, 0.72, 0.38)   // warm gold
        case .mystical:   return (0.72, 0.58, 0.92)   // purple
        case .celestial:  return (0.40, 0.72, 1.00)   // electric blue
        case .floral:     return (0.72, 0.90, 0.58)   // sage green
        case .alchemical: return (0.95, 0.75, 0.30)   // amber
        case .darkMoon:   return (0.65, 0.65, 0.75)   // silver
        }
    }
}

// MARK: - DeckType

/// Available card-front artwork decks (Requirement 6.2).
public enum DeckType: String, CaseIterable, Codable {
    // Original decks
    case riderWaite = "riderWaite"
    case thoth      = "thoth"
    case helloKitty = "helloKitty"
    // New decks
    case marseille  = "marseille"
    case osho       = "osho"
    case darkSide   = "darkSide"
    case celestial  = "celestial"
    case botanical  = "botanical"

    public var displayName: String {
        switch self {
        case .riderWaite: return "Rider-Waite Clásico"
        case .thoth:      return "Thoth Crowley"
        case .helloKitty: return "Hello Kitty Kawaii"
        case .marseille:  return "Tarot de Marsella"
        case .osho:       return "Osho Zen"
        case .darkSide:   return "Dark Side (Oscuro)"
        case .celestial:  return "Tarot Celestial"
        case .botanical:  return "Tarot Botánico"
        }
    }

    public var description: String {
        switch self {
        case .riderWaite: return "El mazo más popular del siglo XX, con ilustraciones simbólicas de Pamela Colman Smith."
        case .thoth:      return "Diseñado por Aleister Crowley y Lady Frieda Harris. Geometría proyectiva sagrada."
        case .helloKitty: return "Una versión kawaii y adorable del Tarot para lecturas ligeras y divertidas."
        case .marseille:  return "El mazo europeo más antiguo (s. XVII), origen del Tarot moderno. Arte medieval."
        case .osho:       return "Basado en las enseñanzas de Osho. Acuarelas vibrantes y espiritualidad Zen."
        case .darkSide:   return "Estética oscura y subversiva. Para quienes trabajan con la sombra y el inconsciente."
        case .celestial:  return "Inspirado en constelaciones y cosmología. Cartas que reflejan el cosmos interior."
        case .botanical:  return "Ilustraciones botánicas de plantas sagradas y la sabiduría de la naturaleza."
        }
    }

    /// Texture style identifier used by CardTextureOverlayView
    public var textureStyle: DeckTextureStyle {
        switch self {
        case .riderWaite: return .agedParchment
        case .thoth:      return .sacredGeometry
        case .helloKitty: return .softPastel
        case .marseille:  return .medievalEmbroidery
        case .osho:       return .watercolor
        case .darkSide:   return .grunge
        case .celestial:  return .starfield
        case .botanical:  return .leafVeins
        }
    }
}

/// Visual texture style for card overlays.
public enum DeckTextureStyle {
    case agedParchment
    case sacredGeometry
    case softPastel
    case medievalEmbroidery
    case watercolor
    case grunge
    case starfield
    case leafVeins
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
