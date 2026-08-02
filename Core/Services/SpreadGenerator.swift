import Foundation
import SwiftUI // For potential UI-related helpers or just good practice

/// Represents a single position within a tarot/oracle card spread.
public struct SpreadPosition: Identifiable, CustomStringConvertible { // <-- CONFORMING TO CUSTOMSTRINGCONVERTIBLE HERE!
    public let name: String
    
    // Conforming to Identifiable allows it to be used easily in SwiftUI Lists, ForEach, etc.
    public var id: Self.ID {
        return name // Using the name as a unique identifier for simplicity
    }

    // MARK: - CustomStringConvertible Implementation
    /// This tells Swift that when you ask for a String representation of SpreadPosition, 
    /// it should use this implementation (which defaults to using the 'name' property).
    public var description: String {
        return name
    }
}

/// A utility class responsible for generating predefined and custom spread configurations.
// ... rest of the file remains unchanged ...
