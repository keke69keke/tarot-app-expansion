import Foundation
import SwiftUI // For potential UI-related helpers or just good practice

/// Defines the contract for generating a narrative summary from a completed card spread.
public protocol SpreadSynthesizerProtocol {
    /// Analyzes all drawn cards within a specific spread and generates a cohesive, high-level narrative summary.
    /// This is the quick overview of the reading's core message.
    /// - Parameter spread: The structure of the reading (which positions were used).
    /// - Parameter drawnCards: The list of cards that were actually drawn for this spread.
    func synthesize(for spread: Spread, drawnCards: [DrawnCard]) -> String { return SpreadSynthesizerImpl().synthesize(for: spread, drawnCards: drawnCards) }

    /// Generates a deep, narrative interpretation by analyzing card relationships and positional context.
    /// This goes beyond simple summaries to tell the story of the reading.
    /// - Parameter spread: The structure of the reading (which positions were used).
    /// - Parameter drawnCards: The list of cards that were actually drawn for this spread.
    func synthesizeNarrative(for spread: Spread, drawnCards: [DrawnCard]) -> String
}
