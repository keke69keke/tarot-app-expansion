import Foundation
import SwiftUI // For ObservableObject and @Published properties
import Combine // Standard for modern SwiftUI state management

// NOTE: We assume this custom error enum exists in TarotApp.Core.Models or Services
public enum TarotError: LocalizedError {
    case deckEmpty(message: String)
    case unknownFailure(underlyingError: Error)
    case synthesisFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .deckEmpty(let message):
            return "Deck Empty: \(message). Please ensure your card repository is populated."
        case .unknownFailure(let underlyingError):
            return "An unexpected reading failure occurred. Details: \(underlyingError.localizedDescription)"
        case .synthesisFailed(let reason):
            return "Interpretation Failed: The synthesizer could not create a narrative because of this issue: \(reason)."
        }
    }
}

// MARK: - TarotReadingViewModel
/// Manages the state and logic for a single tarot card reading session.
public class TarotReadingViewModel: ObservableObject {
    
    // Published properties automatically notify SwiftUI views when they change.
    @Published public var spreadName: String = "Ready to Draw" // Tracks the name of the active Spread
    @Published public var synthesisSummary: String = "Tap 'Draw Cards' to begin your journey into the wisdom of the Tarot." // Quick Summary (e.g., "The core message is...")
    @Published public var narrativeSummary: String? = nil // The detailed story/breakdown summary
    @Published public var drawnCards: [DrawnCard] = []
    @Published public var isLoading: Bool = false
    // Exposing the raw error object for more granular UI handling
    @Published public var lastError: Error? 

    // --- NEW PERSISTENCE STATE ---
    // This property will hold the entire reading result when saved.
    @AppStorage("lastReadingResult") private var savedReadingData: Data? = nil
    // -----------------------------

    // Dependency Injection for the core logic executor.
    private let drawCardsUseCase: DrawCardsUseCaseProtocol
    
    // MARK: Initialization
    public init(drawCardsUseCase: DrawCardsUseCaseProtocol) {
        self.drawCardsUseCase = drawCardsUseCase
        // Load data immediately when the ViewModel is initialized!
        loadLastReading() 
    }

    // MARK: Public Actions & Helpers
    
    /// Triggers the card drawing and interpretation process for a given spread.
    public func drawAndSynthesize(for spread: Spread) async {
        // Reset state before starting a new reading
        self.isLoading = true
        self.lastError = nil // RESET ERROR on new draw
        self.narrativeSummary = nil // RESET NARRATIVE on new draw
        self.drawnCards = []
        
        // Set the spread name immediately from the input object
        self.spreadName = spread.name 
        
        do {
            // Execute the UseCase logic (Draw -> Enrich -> Synthesize)
            let result = try await drawCardsUseCase.execute(for: spread)
            
            // Update published properties on the main thread (essential for SwiftUI)
            await MainActor.run {
                self.drawnCards = result.drawnCards
                self.synthesisSummary = result.synthesisSummary // Quick summary is already here!
                self.narrativeSummary = self.getNarrativeSummary() 
                print("✅ Reading successfully synthesized!")
            }

            // Save the result immediately after a successful draw.
            saveCurrentReading(result: result)

        } catch {
            // --- Error Handling (TarotError check) ---
            if let tarotError = error as? TarotError {
                await MainActor.run {
                    self.lastError = tarotError // Store the specific TarotError object
                    print("❌ Reading failed with specific Tarot Error.")
                }
            } else {
                // Handle any other unexpected errors (e.g., Swift's built-in NSError)
                await MainActor.run {
                    self.lastError = TarotError.unknownFailure(underlyingError: error) // Wrap it!
                    print("❌ Reading failed with generic Error.")
                }
            }
        }
        
        // Mark loading as complete
        await MainActor.run {
            self.isLoading = false
        }
    }

    /// Helper function to retrieve the deep, narrative interpretation from the latest reading result.
    public func getNarrativeSummary() -> String? {
        guard !drawnCards.isEmpty else { return nil }
        
        // We need the Spread object that corresponds to these drawn cards. 
        let spread = getSpread(from: drawnCards)
        
        // Use the synthesizer implementation directly on the current state
        return SpreadSynthesizerImpl().synthesizeNarrative(for: spread, drawnCards: self.drawnCards)
    }

    /// Helper function to reconstruct the Spread object from the currently drawn cards.
    private func getSpread(from cards: [DrawnCard]) -> Spread {
        // Find all unique positions present in the drawn cards
        let uniquePositions = Set(cards.map { $0.position })
        
        // Use the name passed into the function if available, otherwise guess based on count
        let spreadName: String
        if uniquePositions.count == 3 && !self.spreadName.isEmpty {
            spreadName = self.spreadName // Trust the ViewModel's current state name!
        } else if cards.count == 10 {
            spreadName = "Celtic Cross"
        } else {
            // Fallback for custom spreads where the name wasn't explicitly passed to drawAndSynthesize
            spreadName = "\(cards.count) Card Custom Spread"
        }

        return Spread(name: spreadName, positions: Array(uniquePositions))
    }
    
    // MARK: - Persistence Methods (NEW!)
    
    /// Saves the current state of the reading to UserDefaults via @AppStorage.
    private func saveCurrentReading(result: ReadingResult?) {
        guard let result = result else { return }
        do {
            let encoder = JSONEncoder()
            // Encode the entire ReadingResult object into Data
            let data = try encoder.encode(result)
            self.savedReadingData = data
            print("💾 Successfully saved reading to UserDefaults.")
        } catch {
            print("🚨 Failed to encode and save reading result: \(error)")
        }
    }

    /// Loads the last known reading from UserDefaults when the ViewModel initializes.
    private func loadLastReading() {
        guard let data = savedReadingData else {
            print("🔍 No previous reading found in storage.")
            return
        }
        do {
            let decoder = JSONDecoder()
            // Decode the Data back into a ReadingResult object
            let result = try decoder.decode(ReadingResult.self, from: data)
            
            // Update all published properties with the loaded data!
            await MainActor.run {
                self.drawnCards = result.drawnCards
                self.synthesisSummary = result.synthesisSummary
                self.narrativeSummary = result.narrativeSummary
                self.spreadName = result.spread.name
                print("✅ Successfully loaded previous reading from storage.")
            }
        } catch {
            // If decoding fails (e.g., corrupted data), we just log it and keep the default state.
            await MainActor.run {
                self.lastError = TarotError.unknownFailure(underlyingError: error) // Set an error to notify UI
                print("⚠️ Failed to decode saved reading result.")
            }
        }
    }
}
