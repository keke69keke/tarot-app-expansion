import TarotCore

/// Represents a specific spread configuration used for a reading session.
/// It defines the structure of the reading (e.g., 3-Card, Celtic Cross).
public struct Spread: Identifiable, Hashable {
    // Use UUID to ensure uniqueness even if two spreads have identical names/positions.
    public let id = UUID()
    
    /// The user-friendly name of this spread configuration.
    public var name: String 
    
    /// The ordered array of positions that define the reading structure.
    public var positions: [SpreadPosition]

    // MARK: Initializers
    
    /// Initializes a Spread with a given name and its corresponding list of positions.
    public init(name: String, positions: [SpreadPosition]) {
        self.name = name
        self.positions = positions
    }

    // MARK: Hashable conformance (required for use in Sets/Dictionaries)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Spread, rhs: Spread) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name // Comparing name as a secondary check is often useful
    }
}
