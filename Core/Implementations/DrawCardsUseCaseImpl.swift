import TarotCore

public class DrawCardsUseCaseImpl: DrawCardsUseCaseProtocol { // <-- Renamed from 'DrawCardsUseCase' to avoid redeclaration!
    
    private let cardRepository: CardRepository 
    private let synthesizer: SpreadSynthesizerProtocol 

    public init(cardRepository: CardRepository, synthesizer: SpreadSynthesizerProtocol) {
        self.cardRepository = cardRepository
        self.synthesizer = synthesizer
    }
    
    // MARK: DrawCardsUseCaseProtocol Conformance
    
    public func execute(for spread: Spread) async throws -> ReadingResult {
        let drawnCards = try await drawRandomCards(for: spread)
        
        // *** FIX for Error #4 (Extra argument): Ensure the call matches the signature! ***
        // We are calling synthesize(for:spread, drawnCards:) which expects both arguments.
        let summary = synthesizer.synthesize(for: spread, drawnCards: drawnCards) 
        
        return ReadingResult(spread: spread, drawnCards: drawnCards, synthesisSummary: summary)
    }

    /// Helper function to simulate drawing cards (now explicitly using Rider Deck logic).
    private func drawRandomCards(for spread: Spread) async throws -> [DrawnCard] {
        // --- SIMULATION LOGIC START ---
        print("⚙️ UseCase: Drawing cards specifically from the RIDER DECK...")
        
        var drawnCards: [DrawnCard] = []
        let riderDeck = cardRepository.allCards() 

        for position in spread.positions {
            guard let randomCard = riderDeck.randomElement() else {
                throw TarotError.deckEmpty(message: "The repository returned an empty deck.")
            }
            
            // Simulate a random orientation (50/50 chance)
            let orientation: CardOrientation = Bool.random() ? .upright : .reversed
            
            var drawnCard = DrawnCard(card: randomCard, position: position, orientation: orientation)
            
            // Enrich the card immediately by getting its positional interpretation from the repository
            let interpretation = cardRepository.interpretation(for: randomCard, position: position, orientation: orientation)
            drawnCard.positionalInterpretation = interpretation.summary
            
            drawnCards.append(drawnCard)
        }
        // --- SIMULATION LOGIC END ---
        return drawnCards
    }
}
