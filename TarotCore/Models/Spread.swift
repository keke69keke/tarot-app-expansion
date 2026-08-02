import Foundation
import CoreGraphics

/// Defines a specific location within a spread (e.g., "The Past", "The Goal").
public struct SpreadPosition: Identifiable, Hashable {
    public let id = UUID()
    public let type: SpreadPositionType?
    public var name: String
    public var displayName: String
    public var description: String?
    public var layoutCoordinate: CGPoint?

    // Custom initializer for easy creation
    public init(name: String, displayName: String? = nil, description: String? = nil, layoutCoordinate: CGPoint? = nil) {
        self.type = SpreadPositionType(rawValue: name)
        self.name = name
        self.displayName = displayName ?? name
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }

    // Compatibility initializer for older tests and modules.
    public init(id: SpreadPositionType, displayName: String, layoutCoordinate: CGPoint = .zero, description: String? = nil) {
        self.type = id
        self.name = id.rawValue
        self.displayName = displayName
        self.description = description
        self.layoutCoordinate = layoutCoordinate
    }
}

/// A lightweight set of common spread presets used across the app.
public enum SpreadType: String, CaseIterable, Codable {
    case dailyCard
    case threeCard
    case celticCross
    case fiveCard
    case horseshoe
    case relationship
    case twelveMonth
    case decision
    case pathOfLife

    /// Returns the canonical positions for this spread type.
    public var positions: [SpreadPosition] {
        switch self {
        case .dailyCard:
            return [SpreadPosition(name: "Diario")]
        case .threeCard:
            return [SpreadPosition(name: "Pasado"), SpreadPosition(name: "Presente"), SpreadPosition(name: "Futuro")]
        case .celticCross:
            return [SpreadPosition(name: "Presente"), SpreadPosition(name: "Desafío"), SpreadPosition(name: "Pasado"), SpreadPosition(name: "Futuro"), SpreadPosition(name: "Encima"), SpreadPosition(name: "Debajo"), SpreadPosition(name: "Consejo"), SpreadPosition(name: "Entorno"), SpreadPosition(name: "Esperanzas"), SpreadPosition(name: "Resultado")]
        case .fiveCard:
            return [SpreadPosition(name: "Situación"), SpreadPosition(name: "Obstáculo"), SpreadPosition(name: "Acción"), SpreadPosition(name: "Resultado"), SpreadPosition(name: "Consejo")]
        case .horseshoe:
            return [SpreadPosition(name: "Pasado"), SpreadPosition(name: "Presente"), SpreadPosition(name: "Oculto"), SpreadPosition(name: "Consejo"), SpreadPosition(name: "Futuro Cercano"), SpreadPosition(name: "Futuro Lejano"), SpreadPosition(name: "Resultado")]
        case .relationship:
            return [SpreadPosition(name: "Tú"), SpreadPosition(name: "Pareja"), SpreadPosition(name: "Fortalezas"), SpreadPosition(name: "Desafíos"), SpreadPosition(name: "Camino Mutuo"), SpreadPosition(name: "Consejo"), SpreadPosition(name: "Resultado")]
        case .twelveMonth:
            return (1...12).map { i in SpreadPosition(name: "Mes \(i)") }
        case .decision:
            return [SpreadPosition(name: "Situación"), SpreadPosition(name: "Elección"), SpreadPosition(name: "Consecuencia"), SpreadPosition(name: "Consejo")]
        case .pathOfLife:
            return [SpreadPosition(name: "Pasado"), SpreadPosition(name: "Presente"), SpreadPosition(name: "Futuro"), SpreadPosition(name: "Desafío"), SpreadPosition(name: "Fortaleza"), SpreadPosition(name: "Consejo"), SpreadPosition(name: "Resultado"), SpreadPosition(name: "Oculto"), SpreadPosition(name: "Guía")]
        }
    }

    public var label: String {
        switch self {
        case .dailyCard: return "Carta del día"
        case .threeCard: return "Tres cartas"
        case .celticCross: return "Cruz celta"
        case .fiveCard: return "Cinco cartas"
        case .horseshoe: return "Herradura (7)"
        case .relationship: return "Relaciones"
        case .twelveMonth: return "12 meses"
        case .decision: return "Decisión"
        case .pathOfLife: return "Camino de vida"
        }
    }
}

public extension SpreadPositionType {
    static func from(_ rawValue: String) -> SpreadPositionType? {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "daily", "diario": return .daily
        case "past", "pasado": return .past
        case "present", "presente": return .present
        case "future", "futuro": return .future
        case "advice", "consejo": return .advice
        case "outcome", "resultado": return .outcome
        case "challenge", "desafío", "desafio": return .challenge
        case "strength", "fortaleza": return .strength
        case "shadow", "sombra": return .shadow
        case "environment", "entorno": return .environment
        case "unknown", "desconocido": return .unknown
        default: return nil
        }
    }

    var displayName: String {
        switch self {
        case .daily: return "Diario"
        case .past: return "Pasado"
        case .present: return "Presente"
        case .future: return "Futuro"
        case .advice: return "Consejo"
        case .outcome: return "Resultado"
        case .challenge: return "Desafío"
        case .strength: return "Fortaleza"
        case .shadow: return "Sombra"
        case .environment: return "Entorno"
        case .unknown: return "Desconocido"
        }
    }
}

/// Represents a collection of positions that define the structure of a reading.
public struct Spread {
    /// Optional spread metadata kept for compatibility with older code: a spread may have a type and creation date.
    public var type: SpreadType?
    public var createdAt: Date?

    /// The standard, predefined positions (e.g., Past, Present, Future).
    public var standardPositions: [SpreadPosition]
    
    /// Optional list of custom/advanced positions defined by the user for this specific spread.
    /// If present, these take precedence or are added to the standard set.
    public var customPositions: [SpreadPosition]?

    /// Compatibility: some older code expects a list of drawn cards attached to the spread.
    public var drawnCards: [DrawnCard] = []

    // MARK: Initializers
    
    /// Initializes a Spread with only standard positions (e.g., 3-Card Spread).
    public init(standardPositions: [SpreadPosition]) {
        self.standardPositions = standardPositions
        self.customPositions = nil
        self.type = nil
        self.createdAt = nil
    }
    
    /// Initializes a Spread with custom positions, overriding or augmenting the standard set.
    public init(customPositions: [SpreadPosition], standardPositions: [SpreadPosition] = []) {
        self.customPositions = customPositions
        // If no standard positions are provided, use an empty array; otherwise, merge them.
        self.standardPositions = standardPositions.isEmpty ? [] : standardPositions
        self.type = nil
        self.createdAt = nil
    }

    /// Compatibility initializer: build a Spread from a SpreadType, drawn cards and createdAt.
    public init(type: SpreadType, drawnCards: [DrawnCard], createdAt: Date = Date()) {
        self.type = type
        self.createdAt = createdAt
        self.standardPositions = type.positions
        self.customPositions = nil
        self.drawnCards = drawnCards
    }

    /// Helper to get all unique positions in the spread, sorted by display name.
    public var allPositions: [SpreadPosition] {
        var positions = self.standardPositions
        if let custom = self.customPositions {
            // Add custom ones, ensuring no duplicates if a standard position was also customized
            for customPos in custom where !positions.contains(where: { $0.id == customPos.id }) {
                positions.append(customPos)
            }
        }
        return positions.sorted { $0.displayName < $1.displayName }
    }
}
