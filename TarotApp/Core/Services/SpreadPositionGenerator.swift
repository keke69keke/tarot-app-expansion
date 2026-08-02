import Foundation
import TarotCore

/// A service responsible for generating `SpreadPosition` definitions from raw data.
public struct SpreadPositionGenerator {

    /// Generates an array of `SpreadPosition` structs from a list of strings.
    /// - Parameter positionNames: An array of strings, where each string is the name of a spread position (e.g., "The Querent", "Past Influence").
    /// - Returns: A fully initialized array of `SpreadPosition`.
    public static func generate(from positionNames: [String]) -> [SpreadPosition] {
        // Map over the input names and create a SpreadPosition for each one.
        return positionNames.map { name in
            // For now, we'll use the name as both the primary identifier and description.
            // In future iterations (Phase 2), this could be enhanced to pull richer metadata from a database/config.
            SpreadPosition(name: name, description: nil) // Description can be populated later if needed
        }
    }

    /// Generates a complete `Spread` object from raw configuration data.
    /// - Parameters:
    ///   - spreadName: The display name of the spread (e.g., "Celtic Cross").
    ///   - spreadDescription: An optional detailed explanation of the spread's meaning.
    ///   - positionNames: An array of strings defining each position.
    /// - Returns: A fully initialized `Spread` instance.
    public static func generate(name: String, description: String? = nil, from positionNames: [String]) -> Spread {
        let positions = generate(from: positionNames)
        return Spread(name: name, description: description, positions: positions)
    }
}