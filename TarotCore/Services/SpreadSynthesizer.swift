import Foundation

/// A service responsible for taking a complete Spread and its drawn cards to synthesize a cohesive narrative.
public final class SpreadSynthesizer {
    private let cardRepository: CardRepository
    
    public init(cardRepository: CardRepository) {
        self.cardRepository = cardRepository
    }
    
    /// Generates a comprehensive narrative summary from a spread and its drawn cards.
    /// - Parameters:
    ///   - spread: The spread configuration (positions, name).
    ///   - drawnCards: The cards drawn for this spread in their positions.
    /// - Returns: A detailed string summarizing the reading's meaning, structured by position where possible.
    public func synthesize(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        guard !drawnCards.isEmpty else {
            return "This spread currently contains no drawn cards to interpret."
        }
        
        var contextualInterpretations: [SpreadPosition: String] = [:]
        for card in drawnCards {
            if let interpretationText = card.positionalInterpretation {
                contextualInterpretations[card.position] = interpretationText
            } else {
                let fallback = cardRepository.interpretation(
                    for: card.card,
                    position: card.position,
                    orientation: card.orientation
                )
                contextualInterpretations[card.position] = fallback.summary
            }
        }
        
        let defaultSummary: String = {
            let parts = drawnCards.map { dc in
                let orient = (dc.orientation == .reversed) ? "reversed" : "upright"
                return "\(dc.card.name) (\(orient))"
            }
            return "This reading centers around: " + parts.joined(separator: ", ") + "."
        }()
        
        var narrativeParts: [String] = []
        narrativeParts.append("--- Positional Breakdown ---")
        
        let orderedPositions: [SpreadPosition] = spread.allPositions
        for position in orderedPositions {
            if let text = contextualInterpretations[position] {
                narrativeParts.append("✨ **\(position.displayName)**: \(text)")
            } else {
                narrativeParts.append("❓ **\(position.displayName)**: (Interpretation pending or missing data.)")
            }
        }
        
        narrativeParts.append("\n--- Overall Reading Summary ---")
        narrativeParts.append("🔮 **The Core Message**: \(defaultSummary)")
        
        return narrativeParts.joined(separator: "\n\n")
    }
}
