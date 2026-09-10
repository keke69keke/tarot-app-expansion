import SwiftUI

public struct MysticMusicPlayerBar: View {
    @StateObject private var audioService = MysticAudioService.shared
    @State private var showingTrackSelector = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // Track Info / Selector button
            Menu {
                ForEach(AmbientTrack.availableTracks) { track in
                    Button {
                        audioService.selectTrack(track)
                    } label: {
                        Label(track.name, systemImage: track.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: audioService.currentTrack.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.tarotGold)
                    
                    Text(audioService.currentTrack.name)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Play / Pause Button
            Button {
                TarotAudioService.shared.playCardSelect()
                audioService.togglePlay()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.tarotGold)
                    
                    if audioService.isPlaying {
                        WaveformAnimationView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.tarotGold.opacity(0.18)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.92))
                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.3), lineWidth: 0.8)
        )
        .padding(.horizontal)
    }
}

private struct WaveformAnimationView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.tarotGold)
                    .frame(width: 2, height: animating ? CGFloat(6 + (i * 4)) : 4)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}
