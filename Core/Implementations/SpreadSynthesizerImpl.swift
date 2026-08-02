import Foundation
// Assuming models are in the main app target's Core module
import TarotCore

/// Concrete implementation of the SpreadSynthesizerProtocol, providing rich narrative interpretation.
public struct SpreadSynthesizerImpl: SpreadSynthesizerProtocol {
    
    // MARK: - Synthesis Logic Helpers
    
    /// Helper to get a descriptive string for a card's meaning based on its position context.
    private func describeCardInContext(card: DrawnCard, position: SpreadPosition) -> String {
        let baseMeaning = card.card.generalInterpretation // Accessing via .card property now
        var description = "\(card.card.name) (\(card.orientation == .reversed ? "Reversed" : "Upright")): \(baseMeaning)"
        
        // Add positional context based on the position type (assuming SpreadPosition has a 'type' enum, which it should!)
        switch position.type { // <-- ASSUMPTION: SpreadPosition now has a 'type' property!
        case .past:
            description += " - Reflecting on the past."
        case .present:
            description += " - Defining the current energy/situation."
        case .future:
            description += " - Indicating potential future outcomes."
        case .heart: // Example of a specific spread type context
            description += " - As a core emotional driver."
        default:
            // For generic positions, we can just state the position name if available
            if let posName = position.name {
                description += " (Position: \(posName))."
            } else {
                description += "."
            }
        }
        return description
    }

    /// Attempts to find related cards in the spread for deeper context.
    private func getContextualCards(for position: SpreadPosition, drawnCards: [DrawnCard], spread: Spread) -> [DrawnCard] {
        // For simplicity, we'll check immediate neighbors (if they exist)
        guard let index = spread.positions.firstIndex(where: { $0 == position }) else { return [] }
        var contextCards: [DrawnCard] = []

        // Check previous card
        if index > 0 {
            contextCards.append(drawnCards[index - 1])
        }
        // Check next card
        if index < drawnCards.count - 1 {
            contextCards.append(drawnCards[index + 1])
        }
        return contextCards
    }

    // MARK: - Protocol Conformance
    
    public func synthesize(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        var summaryParts: [String] = []
        
        // Iterate through the positions in order to build a linear narrative flow
        for position in spread.positions {
            guard let card = drawnCards.first(where: { $0.position == position }) else { continue }
            summaryParts.append(describeCardInContext(card: card, position: position))
        }
        
        // Join them into a concise summary string
        return "The core message of this reading is: \(summaryParts.joined(separator: " | "))"
    }

    public func synthesizeNarrative(for spread: Spread, drawnCards: [DrawnCard]) -> String {
        var narrativeBuilder = ["🔮 **Your Reading Narrative**\n"]
        
        // 1. Introduction & Core Message (using the quick synthesis)
        narrativeBuilder.append("✨ *Summary:* \(synthesize(for: spread, drawnCards: drawnCards))")
        narrativeBuilder.append("\n--- \n")

        // 2. Positional Deep Dive (The Storytelling Part)
        narrativeBuilder.append("📖 **Positional Breakdown:**\n")
        
        // Iterate through positions to build the story chronologically/structurally
        for position in spread.positions {
            guard let card = drawnCards.first(where: { $0.position == position }) else { continue }
            let contextCards = getContextualCards(for: position, drawnCards: drawnCards, spread: spread)
            
            var paragraph = "➡️ **\(position.name ?? "A Position")** (\(card.card.name)): \(describeCardInContext(card: card, position: position))\n"
            
            // Add context from neighbors if they exist
            if !contextCards.isEmpty {
                paragraph += "   * *Influenced by:* "
                let contextNames = contextCards.map { $0.card.name }.joined(separator: ", ")
                paragraph += "\(contextNames)."
            } else {
                 paragraph += "   *(This card stands alone in its meaning for this spread.)"
            }
            narrativeBuilder.append(paragraph)
        }
        
        // 3. Synthesis Conclusion (The Big Picture Takeaway)
        var conclusion = "\n🌟 **Overall Insight:**\n"
        conclusion += "This reading suggests a powerful interplay between the past and present energy. The card in the Present position acts as the anchor, pulling forward the lessons from the Past while pointing toward the potential of the Future. Pay close attention to how \(drawnCards.first(where: { $0.position == .present })?.card.name ?? "the central card") is interacting with its neighbors."
        narrativeBuilder.append(conclusion)

        return narrativeBuilder.joined(separator: "\n")
    }
}
