import SwiftUI
import AudioToolbox

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Service managing tactile haptic responses and subtle sound effects during card readings.
@MainActor
public final class TarotAudioService: ObservableObject {
    public static let shared = TarotAudioService()
    
    private init() {}
    
    // MARK: - Haptic Feedback Styles
    public enum HapticStyle {
        case light
        case medium
        case heavy
        case selection
        case success
    }
    
    /// Triggers subtle haptic vibration (iOS only).
    public func triggerHaptic(_ style: HapticStyle = .medium) {
        #if os(iOS)
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
        #endif
    }
    
    // MARK: - Native Sound Effects
    
    /// Plays subtle card flip sound.
    public func playCardFlip() {
        triggerHaptic(.medium)
        #if os(iOS)
        AudioServicesPlaySystemSound(1104) // Tink / Card pop
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Plays card selection sound.
    public func playCardSelect() {
        triggerHaptic(.selection)
        #if os(iOS)
        AudioServicesPlaySystemSound(1105) // Tock
        #endif
    }
    
    /// Plays golden chime sound for card reveal / completion.
    public func playGoldenChime() {
        triggerHaptic(.success)
        #if os(iOS)
        AudioServicesPlaySystemSound(1306) // Celestial Chime
        #endif
    }
}
