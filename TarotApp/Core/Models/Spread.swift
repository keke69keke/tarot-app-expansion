import Foundation
import TarotCore

/// Represents a specific position within a Tarot spread (e.g., "The Querent", "Past Influence").
// Note: This structure likely mirrors or extends the existing SpreadPosition model,
// but defining it here ensures self-containment for the Spread model itself.
public struct SpreadPosition: Codable, Identifiable {
    public let id = UUID() // Unique ID for SwiftUI/data management
    public var name: String // e.g., "The Querent"
    public var description: String? // A longer explanation of what this position represents
}

/// Defines a complete Tarot Spread configuration.
/// This model supports both pre-defined spreads (like Celtic Cross) and custom, user-created spreads.
public struct Spread: Codable, Identifiable {
    // MARK: - Properties

    /// A unique identifier for the spread (e.g., "celtic_cross", "love_spread").
    public var id: String {
        return name.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    /// The human-readable name displayed to the user (e.g., "Celtic Cross Spread").
    public var name: String

    /// An optional, detailed description of the spread's meaning or purpose.
    public var description: String?

    /// The sequence and definition of each position in the spread.
    public var positions: [SpreadPosition]

    // MARK: - Initialization

    /// Initializes a Spread with all necessary components.
    /// - Parameters:
    ///   - name: The display name of the spread.
    ///   - description: An optional detailed explanation.
    ///   - positions: An array of `SpreadPosition` structs defining the layout.
    public init(name: String, description: String? = nil, positions: [SpreadPosition]) {
        self.name = name
        self.description = description
        self.positions = positions
    }

    // MARK: - Convenience Initializers (For easier creation)

    /// Creates a Spread from an existing configuration object.
    public init(from existingSpread: Spread) {
        self.name = existingSpread.name
        self.description = existingSpread.description
        self.positions = existingSpread.positions
    }
}

// MARK: - Custom Coding Keys (If needed for complex serialization, though default is usually fine)
extension Spread {
    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case positions
    }
}