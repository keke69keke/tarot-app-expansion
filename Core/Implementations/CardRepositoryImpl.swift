import TarotCore

public class CardRepositoryImpl: CardRepository {
    // ... (deck generation code remains the same) ...
    private var fullDeck: [Card] = [] // Assuming this is populated in init()

    public init() {
        self.fullDeck = generateRiderDeck()
    }
    
    // ... (allCards() method remains the same) ...
    
    public func interpretation(for card: Card, position: SpreadPosition, orientation: CardOrientation) -> Interpretation {
        var summary = ""
        let baseMeaning = card.generalInterpretation
        
        if orientation == .reversed {
            summary += " (Reversed): "
        } else {
            summary += " (Upright): "
        }

        // Contextual Override Logic: Check if the position has a specific interpretation for this card
        if let contextualMeaning = card.contextualInterpretations[position.id] {
             summary += contextualMeaning
        } else {
             summary += baseMeaning
        }
        
        return Interpretation(summary: summary)
    }
}
