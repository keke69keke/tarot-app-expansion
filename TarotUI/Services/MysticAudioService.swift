import Foundation
import AVFoundation
import Combine

public struct AmbientTrack: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let frequency: Double
    public let icon: String
    
    public static let availableTracks: [AmbientTrack] = [
        AmbientTrack(id: "528hz", name: "Frecuencia 528Hz (Transformación)", frequency: 528.0, icon: "sparkles"),
        AmbientTrack(id: "432hz", name: "Frecuencia 432Hz (Armonía)", frequency: 432.0, icon: "waveform"),
        AmbientTrack(id: "tibetan", name: "Cuencos Tibetanos", frequency: 216.0, icon: "bell.fill"),
        AmbientTrack(id: "rain", name: "Lluvia Mística", frequency: 108.0, icon: "cloud.rain.fill")
    ]
}

@MainActor
public final class MysticAudioService: ObservableObject {
    public static let shared = MysticAudioService()
    
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentTrack: AmbientTrack = AmbientTrack.availableTracks[0]
    @Published public var volume: Float = 0.5 {
        didSet {
            audioEngine.mainMixerNode.outputVolume = volume
        }
    }
    
    private let audioEngine = AVAudioEngine()
    private var toneNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let phase = MysticAudioService.sharedPhase
        let phaseIncrement = MysticAudioService.sharedPhaseIncrement
        
        for frame in 0..<Int(frameCount) {
            let sampleVal = Float(sin(phase) * 0.15) // Soft soothing sine tone
            MysticAudioService.sharedPhase += phaseIncrement
            if MysticAudioService.sharedPhase >= 2.0 * .pi {
                MysticAudioService.sharedPhase -= 2.0 * .pi
            }
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sampleVal
            }
        }
        return noErr
    }
    
    fileprivate static var sharedPhase: Double = 0.0
    fileprivate static var sharedPhaseIncrement: Double = 0.0
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        let mainMixer = audioEngine.mainMixerNode
        let outputNode = audioEngine.outputNode
        let format = outputNode.inputFormat(forBus: 0)
        
        audioEngine.attach(toneNode)
        audioEngine.connect(toneNode, to: mainMixer, format: format)
        mainMixer.outputVolume = volume
        
        updateFrequency(currentTrack.frequency)
    }
    
    private func updateFrequency(_ freq: Double) {
        let sampleRate = audioEngine.outputNode.inputFormat(forBus: 0).sampleRate
        MysticAudioService.sharedPhaseIncrement = (2.0 * .pi * freq) / (sampleRate > 0 ? sampleRate : 44100.0)
    }
    
    public func selectTrack(_ track: AmbientTrack) {
        self.currentTrack = track
        updateFrequency(track.frequency)
    }
    
    public func togglePlay() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }
    
    public func start() {
        guard !isPlaying else { return }
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            try audioEngine.start()
            isPlaying = true
        } catch {
            print("Error starting MysticAudioService engine: \(error)")
        }
    }
    
    public func stop() {
        audioEngine.stop()
        isPlaying = false
    }
}
