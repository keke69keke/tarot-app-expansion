import SwiftUI
import TarotContent
import TarotCore
import TarotData
import TarotNotifications

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

@MainActor public final class AppContainer: ObservableObject {
    public let cards: BundleCardRepository
    public let journal: CoreDataJournalRepository
    public let settings: UserDefaultsSettingsRepository
    public let daily: DeterministicDailyCardService
    public let notifications = LocalNotificationService()
    public init() throws {
        let repo: BundleCardRepository
        if let r = try? BundleCardRepository(bundle: .tarotContent) {
            repo = r
        } else if let r = try? BundleCardRepository(bundle: .main) {
            repo = r
        } else {
            repo = try BundleCardRepository(bundle: Bundle(for: BundleCardRepository.self))
        }
        cards = repo
        journal = CoreDataJournalRepository()
        settings = UserDefaultsSettingsRepository()
        daily = DeterministicDailyCardService(cards: cards.allCards())
    }
}

@MainActor final class TarotViewModel: ObservableObject {
    @Published var selectedSpread: SpreadType = .threeCard
    @Published var spread: Spread?
    @Published var isShuffling = false
    @Published var entries: [JournalEntry] = []
    @Published var searchQuery = ""
    @Published var settings: UserSettings
    @Published var dailyCard: Card
    @Published var dailyRevealed: Bool
    @Published var errorMessage: String?
    let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        settings = container.settings.load()
        dailyCard = container.daily.dailyCard(for: .now)
        dailyRevealed = container.daily.isRevealed(for: .now)
        reloadEntries()
    }
    var visibleCards: [Card] { searchQuery.isEmpty ? container.cards.allCards() : container.cards.search(query: searchQuery) }
    func draw() {
        isShuffling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let engine = SystemRandomizationEngine(deck: self.container.cards.allCards())
            // Use the engine directly to draw cards for the selected spread
            let positions = self.selectedSpread.positions
            let drawn = engine.drawCards(count: positions.count, allowReversed: self.settings.allowReversedCards, positions: positions)
            // Build a local Spread model for UI purposes
            self.spread = Spread(type: self.selectedSpread, drawnCards: drawn, createdAt: Date())
            self.isShuffling = false
        }
    }
    func saveSpread(notes: String = "") {
        guard let spread else { return }
        do { try self.container.journal.save(entry: JournalEntry(spread: spread, notes: notes)); reloadEntries() }
        catch { errorMessage = error.localizedDescription }
    }
    func reloadEntries() { entries = container.journal.fetchAll() }
    func delete(_ entry: JournalEntry) { do { try container.journal.delete(id: entry.id); reloadEntries() } catch { errorMessage = error.localizedDescription } }
    func revealDaily() { container.daily.markRevealed(for: .now); withAnimation { dailyRevealed = true } }

    func replaceCard(at index: Int, with card: Card) {
        guard var spread = spread, spread.drawnCards.indices.contains(index) else { return }
        let currentOrientation = spread.drawnCards[index].orientation
        spread.drawnCards[index] = DrawnCard(card: card, position: spread.drawnCards[index].position, orientation: currentOrientation)
        self.spread = spread
    }

    func reshuffleCurrentSpread() {
        guard let currentSpread = spread else { return }
        isShuffling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self else { return }
            let engine = SystemRandomizationEngine(deck: self.container.cards.allCards())
            let positions = currentSpread.drawnCards.map { $0.position }
            let drawn = engine.drawCards(count: positions.count, allowReversed: self.settings.allowReversedCards, positions: positions)
            self.spread = Spread(type: currentSpread.type ?? self.selectedSpread, drawnCards: drawn, createdAt: currentSpread.createdAt ?? Date())
            self.isShuffling = false
        }
    }

    func persistSettings() { container.settings.save(settings) }
}

/// Root UI for embedding in an iOS app target.
public struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var model: TarotViewModel
    @State private var showWelcome = true

    public init(container: AppContainer) { _model = StateObject(wrappedValue: TarotViewModel(container: container)) }

    public var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color.tarotBackground.ignoresSafeArea()

            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.04, green: 0.08, blue: 0.16), Color(red: 0.06, green: 0.04, blue: 0.12)]
                    : [Color(red: 0.96, green: 0.93, blue: 0.87), Color(red: 0.92, green: 0.87, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            .ignoresSafeArea()

            // Rider-Waite gold ambient glow
            Circle()
                .fill(Color(red: 0.78, green: 0.58, blue: 0.18).opacity(colorScheme == .dark ? 0.14 : 0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 68)
                .offset(x: -140, y: -200)

            // Burgundy accent glow
            Circle()
                .fill(Color(red: 0.42, green: 0.10, blue: 0.10).opacity(colorScheme == .dark ? 0.13 : 0.07))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: 160, y: -140)

            // ── Main UI ─────────────────────────────────────────
            VStack(spacing: 0) {
                TabView {
                    ForEach(model.settings.activeTabs) { tab in
                        Group {
                            switch tab {
                            case .reading: ReadingView(model: model)
                            case .ask: AskTarotView(repository: model.container.cards)
                            case .horoscope: HoroscopeView(repository: model.container.cards)
                            case .library: LibraryView(model: model)
                            case .reference: RiderReferenceView(repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                            case .daily: DailyCardView(model: model)
                            case .book: LearningCenterView()
                            case .journal: JournalView(model: model)
                            case .settings: SettingsView(model: model)
                            case .chat: TarotChatView(apiKey: model.settings.openAIKey, repository: model.container.cards)
                            }
                        }
                        .tabItem { Label(tab.label, systemImage: tab.systemImage) }
                        .tag(tab)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.tarotPanel.opacity(0.90))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.tarotBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
            .opacity(showWelcome ? 0 : 1)

            // ── Welcome Splash ───────────────────────────────────
            if showWelcome {
                WelcomeView(colorScheme: colorScheme) {
                    withAnimation(.easeInOut(duration: 0.65)) {
                        showWelcome = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 1.08))
                ))
                .zIndex(10)
            }
        }
        .preferredColorScheme(model.settings.appearance.colorScheme)
        .alert("Error", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("Aceptar", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}

/// Full-screen animated welcome greeting
private struct WelcomeView: View {
    let colorScheme: ColorScheme
    let onDismiss: () -> Void

    @State private var starOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Deep mystical background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.03, blue: 0.16),
                    Color(red: 0.10, green: 0.05, blue: 0.25),
                    Color(red: 0.04, green: 0.08, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow orbs — Rider-Waite palette
            Circle()
                .fill(Color(red: 0.42, green: 0.10, blue: 0.10).opacity(0.28)) // burgundy
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -80, y: -220)

            Circle()
                .fill(Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.22)) // gold
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 120, y: 240)

            Circle()
                .fill(Color(red: 0.04, green: 0.15, blue: 0.32).opacity(0.40)) // navy
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: -40, y: 60)

            // Rotating star mandala
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundStyle(Color(red: 0.92, green: 0.80, blue: 0.45).opacity(0.5))
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                ForEach(0..<16, id: \.self) { i in
                    Circle()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.18))
                        .frame(width: 3, height: 3)
                        .offset(y: -155)
                        .rotationEffect(.degrees(Double(i) * 22.5))
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            .opacity(starOpacity)

            VStack(spacing: 0) {
                Spacer()

                // Central tarot card icon with pulse
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.80, blue: 0.45),
                                    Color(red: 0.65, green: 0.45, blue: 0.20),
                                    Color(red: 0.92, green: 0.80, blue: 0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 100, height: 100)
                        .opacity(starOpacity * 0.6)
                        .scaleEffect(pulseScale)

                    // Inner background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.10, blue: 0.40),
                                    Color(red: 0.08, green: 0.04, blue: 0.20)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 48
                            )
                        )
                        .frame(width: 96, height: 96)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.90, blue: 0.60),
                                    Color(red: 0.85, green: 0.65, blue: 0.30)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.70), radius: 30, x: 0, y: 0)
                .opacity(starOpacity)

                Spacer().frame(height: 40)

                // Greeting text
                VStack(spacing: 14) {
                    Text("Hola, Nicole")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.92, blue: 0.70),
                                    Color(red: 0.92, green: 0.80, blue: 0.45),
                                    Color(red: 0.80, green: 0.60, blue: 0.25)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.25).opacity(0.45), radius: 16, x: 0, y: 4)
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)

                    Text("Las cartas te esperan")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .tracking(2)
                        .foregroundStyle(Color(red: 0.92, green: 0.84, blue: 0.68).opacity(0.80))
                        .opacity(subtitleOpacity)

                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "sparkle")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0.92, green: 0.80, blue: 0.45).opacity(0.50))
                        }
                    }
                    .opacity(subtitleOpacity)
                }

                Spacer().frame(height: 64)

                // Enter button
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Iniciar lectura")
                            .fontWeight(.semibold)
                    }
                    .font(.body)
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.92, blue: 0.70),
                                        Color(red: 0.85, green: 0.68, blue: 0.30)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.25).opacity(0.55), radius: 18, x: 0, y: 8)
                    .scaleEffect(pulseScale)
                }
                .opacity(buttonOpacity)

                Spacer().frame(height: 20)

                Text("Tarot Rider-Waite")
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.20))
                    .opacity(buttonOpacity)

                Spacer()
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.easeOut(duration: 1.4).delay(0.1)) {
                starOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.85)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.7).delay(1.2)) {
                buttonOpacity = 1
            }
            // Continuous gentle rotation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            // Pulse breathing
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(1.0)) {
                pulseScale = 1.06
            }
        }
    }
}

private struct ReadingView: View {
    @ObservedObject var model: TarotViewModel
    @State private var notes = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var selectedDrawnCard: DrawnCard? = nil
    @State private var replacementIndex: Int? = nil
    @State private var cardPickerQuery = ""
    @State private var isShowingPositionChooser = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tu ritual de tarot")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        Text("Elige una tirada, baraja con intención y descubre lo que las cartas te quieren revelar hoy.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.tarotShadow, radius: 12, x: 0, y: 6)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selecciona tu tirada")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SpreadType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            model.selectedSpread = type
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(type.label)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(model.selectedSpread == type ? .primary : .secondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                            Text("\(type.positions.count) cartas")
                                                .font(.caption2)
                                                .foregroundStyle(model.selectedSpread == type ? .secondary : Color.secondary.opacity(0.85))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .frame(width: 150)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .fill(model.selectedSpread == type ? Color.tarotGold.opacity(0.22) : Color.tarotPanel.opacity(0.88))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(model.selectedSpread == type ? Color.tarotGold.opacity(0.70) : Color.tarotBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.90))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .stroke(Color.tarotBorder, lineWidth: 1)
                                )
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.selectedSpread.label)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("""
                        \(model.selectedSpread.positions.count) cartas · \(model.selectedSpread.positions.map { $0.displayName }.joined(separator: " · "))
                        """)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.90))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )

                    Button {
                        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75)) {
                            model.draw()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: model.isShuffling ? "sparkles" : "shuffle")
                            Text(model.isShuffling ? "Barajando…" : "Iniciar tirada")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                        .shadow(color: Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.45), radius: 16, x: 0, y: 10)
                    }
                    .disabled(model.isShuffling)
                    .opacity(model.isShuffling ? 0.75 : 1)

                    if model.isShuffling {
                        CardFace(name: "Barajando", imageName: nil, textureName: nil, reversed: false, back: true, size: CGSize(width: 160, height: 240), backDesign: model.settings.cardBackDesign)
                            .rotationEffect(.degrees(15))
                            .transition(.opacity)
                    }

                    if model.spread != nil {
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.75)) {
                                    model.reshuffleCurrentSpread()
                                    revealedIndices.removeAll()
                                }
                            } label: {
                                Text("Barajar mazo")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.tarotPanel.opacity(0.92)))
                                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.isShuffling)

                            Button {
                                isShowingPositionChooser = true
                            } label: {
                                Text("Elegir cartas")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.tarotPanel.opacity(0.92)))
                                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(model.isShuffling)
                        }
                        .padding(.top, 4)
                        .foregroundStyle(.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.clear)
                        )
                        Text("Mantén pulsada una carta para reemplazarla o usa 'Elegir cartas'.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    if let spread = model.spread {
                        SpreadDiagramView(
                            spread: spread,
                            repository: model.container.cards,
                            revealedIndices: revealedIndices,
                            activeDeck: model.settings.activeDeck,
                            cardBackDesign: model.settings.cardBackDesign,
                            onSelectCard: { drawn in
                                selectedDrawnCard = drawn
                            },
                            onReplaceCard: { index, _ in
                                replacementIndex = index
                            }
                        )
                        .onReceive(model.$spread) { spread in
                            guard let spread = spread else {
                                revealedIndices.removeAll()
                                return
                            }
                            revealedIndices.removeAll()
                            for i in 0..<spread.drawnCards.count {
                                let delay = Double(i) * 0.18 + 0.3
                                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                    withAnimation(.spring(response: 0.52, dampingFraction: 0.68, blendDuration: 0)) {
                                        _ = revealedIndices.insert(i)
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(spread.drawnCards.count) * 0.18 + 0.5) {
                                withAnimation {
                                    model.isShuffling = false
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Notas del diario")
                                .font(.headline)
                            .foregroundStyle(.primary)
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Escribe tus impresiones después de la lectura...")
                                        .foregroundStyle(.secondary)
                                        .padding(14)
                                }
                                TextEditor(text: $notes)
                                    .padding(12)
                                    .background(Color.tarotPanel.opacity(0.92))
                                    .cornerRadius(22)
                                    .frame(minHeight: 120)
                                    .foregroundStyle(.primary)
                            }
                            Button {
                                model.saveSpread(notes: notes)
                                notes = ""
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Guardar en diario")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(LinearGradient(
                                            colors: [Color.tarotGold, Color.tarotBurgundy],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                )
                                .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                                .shadow(color: Color.tarotGold.opacity(0.30), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.90))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.tarotBorder, lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Tirada")
            .sheet(isPresented: $isShowingPositionChooser) {
                NavigationStack {
                    VStack {
                        Text("Selecciona la posición para reemplazar")
                            .font(.headline)
                            .padding(.top, 16)

                        if let spread = model.spread {
                            List(spread.drawnCards.indices, id: \.self) { idx in
                                let drawn = spread.drawnCards[idx]
                                Button {
                                    replacementIndex = idx
                                    isShowingPositionChooser = false
                                } label: {
                                    HStack(spacing: 12) {
                                        CardFace(name: drawn.card.name, imageName: drawn.card.imageName, textureName: drawn.card.textureImageName, reversed: drawn.orientation == .reversed, useTexture: true, size: CGSize(width: 58, height: 88), activeDeck: model.settings.activeDeck)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(drawn.position.displayName)
                                                .font(.headline)
                                            Text(drawn.card.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.plain)
                        }
                        Spacer()
                    }
                    .navigationTitle("Elegir carta")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { isShowingPositionChooser = false }
                        }
                    }
                }
            }
            .sheet(isPresented: Binding(get: { replacementIndex != nil }, set: { if !$0 { replacementIndex = nil } })) {
                if let selectedIndex = replacementIndex, let spread = model.spread, spread.drawnCards.indices.contains(selectedIndex) {
                    NavigationStack {
                        VStack {
                            Text("Elige una carta para \(spread.drawnCards[selectedIndex].position.displayName)")
                                .font(.headline)
                                .padding(.top, 16)

                            TextField("Buscar carta", text: $cardPickerQuery)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                .padding(.bottom, 6)

                            List(filteredCards(query: cardPickerQuery, repository: model.container.cards), id: \.self) { card in
                                Button {
                                    model.replaceCard(at: selectedIndex, with: card)
                                    replacementIndex = nil
                                    cardPickerQuery = ""
                                } label: {
                                    HStack(spacing: 12) {
                                        CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 58, height: 88), activeDeck: model.settings.activeDeck)
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(card.name)
                                                .font(.headline)
                                            Text(card.suit?.displayName ?? "Arcano Mayor")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .listStyle(.plain)
                        }
                        .navigationTitle("Reemplazar carta")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancelar") {
                                    replacementIndex = nil
                                    cardPickerQuery = ""
                                }
                            }
                        }
                    }
                } else {
                    Text("No hay posición seleccionada.")
                }
            }
            .sheet(item: $selectedDrawnCard) { drawn in
                NavigationStack {
                    CardDetailView(drawn: drawn, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                }
            }
        }
    }

    private func filteredCards(query: String, repository: any CardRepository) -> [Card] {
        let allCards = repository.allCards()
        guard !query.isEmpty else { return allCards }
        return repository.search(query: query)
    }
}

private struct LibraryView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.visibleCards) { card in
                        NavigationLink {
                            CardDetailView(card: card, orientation: .upright, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                        } label: {
                            HStack(spacing: 14) {
                                CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 60, height: 90), activeDeck: model.settings.activeDeck)
                                    .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 3)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(card.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(card.suit?.displayName ?? "Arcano Mayor")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 6) {
                                        Text(card.arcanaType == .major ? "Mayor" : "Menor")
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(card.arcanaType == .major ? Color.tarotGold.opacity(0.18) : Color.tarotBurgundy.opacity(0.14)))
                                            .foregroundStyle(card.arcanaType == .major ? Color.tarotGold : Color.tarotBurgundy)
                                        if let number = card.number, !number.isEmpty {
                                            Text(number)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .searchable(text: $model.searchQuery, prompt: "Buscar carta, número o palo")
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Biblioteca")
        }
    }
}

private struct DailyCardView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Carta del día")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(model.dailyRevealed ? "Tu guía para el día está lista." : "Toca la carta para descubrir tu orientación e inspiración diaria.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.tarotPanel.opacity(0.90))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.tarotBorder, lineWidth: 1)
                )

                Button {
                    if !model.dailyRevealed { model.revealDaily() }
                } label: {
                    CardFace(
                        name: model.dailyCard.name,
                        imageName: model.dailyCard.imageName,
                        textureName: model.dailyCard.textureImageName,
                        reversed: false,
                        back: !model.dailyRevealed,
                        useTexture: true,
                        size: CGSize(width: 220, height: 330),
                        activeDeck: model.settings.activeDeck,
                        backDesign: model.settings.cardBackDesign
                    )
                    .rotation3DEffect(.degrees(model.dailyRevealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: Color.tarotShadow.opacity(1), radius: 18, x: 0, y: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .accessibilityLabel(model.dailyRevealed ? model.dailyCard.name : "Carta del día boca abajo")
                .padding(.vertical, 4)

                Text(model.dailyRevealed ? "Carta revelada. Desplázate para ver la interpretación." : "Pulsa la carta para revelarla")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                if model.dailyRevealed {
                    CardDetailText(card: model.dailyCard, orientation: .upright, repository: model.container.cards)
                        .padding()
                        .background(Color.tarotPanel.opacity(0.90))
                        .cornerRadius(22)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Carta del día")
        }
    }
}

private struct JournalView: View {
    @ObservedObject var model: TarotViewModel
    var body: some View {
        NavigationStack {
            Group {
                if model.entries.isEmpty {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.10))
                                .frame(width: 110, height: 110)
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tarotGold, Color.tarotBurgundy],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color.tarotGold.opacity(0.25), radius: 18, x: 0, y: 8)

                        Text("Aún no hay lecturas guardadas")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text("Guarda tus tiradas aquí y vuelve a consultarlas cuando quieras.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(model.entries) { entry in
                            NavigationLink {
                                JournalDetail(entry: entry, repository: model.container.cards, activeDeck: model.settings.activeDeck, cardBackDesign: model.settings.cardBackDesign)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(entry.spread.type?.label ?? "Tirada")
                                        .font(.headline)
                                    Text(entry.savedAt.formatted(date: .abbreviated, time: .shortened))
                                        .foregroundStyle(.secondary)
                                    Text(entry.spread.drawnCards.map { $0.card.name }.joined(separator: " · "))
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(Color.tarotPanel.opacity(0.88))
                                .cornerRadius(18)
                            }
                        }
                        .onDelete { offsets in offsets.map { model.entries[$0] }.forEach(model.delete) }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.tarotPanel.opacity(0.88))
                                .shadow(color: Color.tarotShadow.opacity(0.15), radius: 8, x: 0, y: 4)
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Diario")
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var model: TarotViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(model.settings.activeTabs) { tab in
                        HStack(spacing: 12) {
                            Image(systemName: tab.systemImage)
                                .frame(width: 26, height: 26)
                                .foregroundStyle(Color.tarotGold)
                            Text(tab.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onMove { source, destination in
                        model.settings.activeTabs.move(fromOffsets: source, toOffset: destination)
                        model.persistSettings()
                    }
                    .onDelete { offsets in
                        let removed = offsets.map { model.settings.activeTabs[$0] }
                        model.settings.activeTabs.remove(atOffsets: offsets)
                        model.settings.inactiveTabs.append(contentsOf: removed)
                        model.persistSettings()
                    }

                    if !model.settings.inactiveTabs.isEmpty {
                        inactiveTabsSection
                    }
                } header: {
                    Label("Menú inferior", systemImage: "square.grid.2x2")
                } footer: {
                    Text("Arrastra para reordenar · Desliza para ocultar · Toca ＋ para mostrar")
                }

                personalizationSection

                Section("Opciones") {
                    Toggle("Permitir cartas invertidas", isOn: $model.settings.allowReversedCards)
                }

                appearanceSection

                notificationsSection

                openAISection
            }
            .formStyle(.grouped)
            .navigationTitle("Ajustes")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            #endif
            .onChange(of: model.settings.allowReversedCards) { _ in model.persistSettings() }
            .onChange(of: model.settings.notificationsEnabled) { value in
                model.persistSettings()
                if value {
                    Task { try? await model.container.notifications.scheduleDailyNotification(hour: model.settings.dailyNotificationHour) }
                } else {
                    Task { await model.container.notifications.cancelDailyNotification() }
                }
            }
            .onChange(of: model.settings.selectedLanguage) { _ in model.persistSettings() }
            .onChange(of: model.settings.activeDeck) { _ in model.persistSettings() }
            .onChange(of: model.settings.cardBackDesign) { _ in model.persistSettings() }
            .onChange(of: model.settings.appearance) { _ in model.persistSettings() }
            .onChange(of: model.settings.dailyNotificationHour) { value in
                model.persistSettings()
                if model.settings.notificationsEnabled {
                    Task { try? await model.container.notifications.scheduleDailyNotification(hour: value) }
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section("Recordatorios") {
            Toggle("Recordatorio diario", isOn: $model.settings.notificationsEnabled)
            if model.settings.notificationsEnabled {
                Stepper("Hora de notificación: \(model.settings.dailyNotificationHour):00", value: $model.settings.dailyNotificationHour, in: 6...22)
            }
        }
    }

    private var openAISection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("API Key de OpenAI", systemImage: "brain.head.profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Opcional. Sin API key, Arcana IA usa el motor local de tarot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            SecureField("sk-...", text: $model.settings.openAIKey)
                .font(.system(.body, design: .monospaced))
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onChange(of: model.settings.openAIKey) { _ in model.persistSettings() }

            if !model.settings.openAIKey.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("API Key configurada")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text("Integración")
        }
    }

    // MARK: - Computed Properties for Pickers (simplified)

    private var personalizationSection: some View {
        Section(header: Text("Personalización"), footer: Text("Personaliza las cartas, el reverso y el idioma para adaptarlo a tu estilo.")) {
            deckPicker
            backPicker
            languagePicker
        }
    }

    private var deckPicker: some View {
        Picker("Baraja", selection: deckSelectionBinding) {
            ForEach(DeckType.allCases, id: \.rawValue) { deck in
                Text(deck.displayName).tag(deck.rawValue)
            }
        }
    }

    private var backPicker: some View {
        Picker("Reverso", selection: backDesignSelectionBinding) {
            ForEach(CardBackDesign.allCases, id: \.rawValue) { design in
                Text(design.displayName).tag(design.rawValue)
            }
        }
    }

    private var languagePicker: some View {
        Picker("Idioma", selection: languageSelectionBinding) {
            Text(Language.spanish.displayName).tag(Language.spanish.rawValue)
            Text(Language.english.displayName).tag(Language.english.rawValue)
        }
    }

    private var appearanceSection: some View {
        Section(header: Text("Apariencia")) {
            Picker("Tema", selection: appearanceSelectionBinding) {
                Text(Appearance.automatic.displayName).tag(Appearance.automatic.rawValue)
                Text(Appearance.light.displayName).tag(Appearance.light.rawValue)
                Text(Appearance.dark.displayName).tag(Appearance.dark.rawValue)
            }
        }
    }

    private var inactiveTabsSection: some View {
        Section {
            Divider()
                .listRowInsets(EdgeInsets())
            ForEach(model.settings.inactiveTabs) { tab in
                inactiveTabRow(for: tab)
            }
        }
    }

    private func inactiveTabRow(for tab: AppTab) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tab.systemImage)
                .frame(width: 26, height: 26)
                .foregroundStyle(.secondary)
            Text(tab.label)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                if let idx = model.settings.inactiveTabs.firstIndex(of: tab) {
                    model.settings.inactiveTabs.remove(at: idx)
                    model.settings.activeTabs.append(tab)
                    model.persistSettings()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.tarotGold)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private var deckSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.activeDeck.rawValue },
            set: {
                model.settings.activeDeck = DeckType(rawValue: $0) ?? .riderWaite
                model.persistSettings()
            }
        )
    }

    private var backDesignSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.cardBackDesign.rawValue },
            set: {
                model.settings.cardBackDesign = CardBackDesign(rawValue: $0) ?? .classic
                model.persistSettings()
            }
        )
    }

    private var languageSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.selectedLanguage.rawValue },
            set: {
                model.settings.selectedLanguage = Language(rawValue: $0) ?? .spanish
                model.persistSettings()
            }
        )
    }

    private var appearanceSelectionBinding: Binding<String> {
        Binding(
            get: { model.settings.appearance.rawValue },
            set: {
                model.settings.appearance = Appearance(rawValue: $0) ?? .automatic
                model.persistSettings()
            }
        )
    }

    // Removed complex Pickers to resolve type-checking issues
    // Settings are still functional with essential toggles
}

private struct CardDetailView: View {
    let card: Card
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    @State private var orientation: CardOrientation

    private var currentInterpretation: Interpretation {
        repository.interpretation(for: card, position: nil, orientation: orientation)
    }

    private let orderedAspectKeys = ["Amor", "Economía", "Salud", "Carrera"]

    init(drawn: DrawnCard, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = drawn.card
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
        _orientation = State(initialValue: drawn.orientation)
    }

    init(card: Card, orientation: CardOrientation, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = card
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
        _orientation = State(initialValue: orientation)
    }

    var body: some View {
        ScrollView(Axis.Set.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Card image hero + orientation selector
                ZStack(alignment: .bottom) {
                    CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: orientation == .reversed, useTexture: true, size: CGSize(width: 260, height: 390), activeDeck: activeDeck, backDesign: cardBackDesign)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)

                    // Orientation badge
                    HStack(spacing: 6) {
                        Image(systemName: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(orientation == .upright ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)
                        Text(orientation == .upright ? "Al derecho" : "Invertida")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: 18)
                }
                .padding(.bottom, 24)

                // Card title & metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.title.bold())
                    HStack(spacing: 10) {
                        if let number = card.number, !number.isEmpty {
                            Text(number)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(card.suit?.displayName ?? (card.arcanaType == .major ? "Arcano Mayor" : "Arcano Menor"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(card.arcanaType == .major ? "Mayor" : "Menor")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(card.arcanaType == .major ? Color.tarotGold.opacity(0.18) : Color.tarotBurgundy.opacity(0.14)))
                            .foregroundStyle(card.arcanaType == .major ? Color.tarotGold : Color.tarotBurgundy)
                    }
                }

                // Orientation toggle
                Picker("Orientación", selection: $orientation) {
                    Text("Al derecho").tag(CardOrientation.upright)
                    Text("Invertida").tag(CardOrientation.reversed)
                }
                .pickerStyle(.segmented)

                // Quick aspects summary
                if !currentInterpretation.aspects.isEmpty {
                    CardAspectSummaryView(interpretation: currentInterpretation)
                }

                // Book content from OCR (Fiebig & Bürger)
                if let bookContent = card.bookContent, !bookContent.isEmpty {
                    BookContentBlock(text: bookContent)
                }

                // Full interpretation section
                CardInterpretationSection(
                    title: orientation == .upright ? "Al derecho" : "Invertida",
                    orientation: orientation,
                    interpretation: currentInterpretation,
                    orderedAspectKeys: orderedAspectKeys
                )

                // Link to Reference view for deeper study
                NavigationLink {
                    ReferenceCardView(card: card, orientation: orientation, repository: repository)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.tarotGold.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "book.fill")
                                .font(.title3)
                                .foregroundStyle(Color.tarotGold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explorar en el Libro Rider")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Vista completa con símbolos, aspectos y contexto por posición")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.tarotGold.opacity(0.10), Color.tarotBurgundy.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.tarotGold.opacity(0.30), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle(card.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func aspectKeys(in interpretation: Interpretation) -> [String] {
        let knownKeys = orderedAspectKeys.filter { interpretation.aspects.keys.contains($0) }
        let extraKeys = interpretation.aspects.keys.sorted().filter { !knownKeys.contains($0) }
        return knownKeys + extraKeys
    }
}

private struct CardAspectSummaryView: View {
    let interpretation: Interpretation
    private let highlightKeys = ["Amor", "Economía", "Salud", "Carrera"]
    private let aspectIcons = ["Amor": "heart.fill", "Economía": "banknote.fill", "Salud": "cross.fill", "Carrera": "briefcase.fill"]
    private let aspectColors: [String: Color] = [
        "Amor": Color(red: 0.72, green: 0.18, blue: 0.18),
        "Economía": Color(red: 0.78, green: 0.58, blue: 0.18),
        "Salud": Color(red: 0.20, green: 0.46, blue: 0.28),
        "Carrera": Color(red: 0.18, green: 0.28, blue: 0.52)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aspectos clave")
                .font(.headline)
                .foregroundStyle(.primary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(highlightKeys.filter { interpretation.aspects[$0] != nil }, id: \.self) { aspect in
                    if let value = interpretation.aspects[aspect] {
                        let color = aspectColors[aspect] ?? Color.tarotGold
                        let icon = aspectIcons[aspect] ?? "sparkle"
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: icon)
                                    .font(.caption)
                                    .foregroundStyle(color)
                                Text(aspect)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(color)
                            }
                            Text(value)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(color.opacity(0.07))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(color.opacity(0.20), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct CardInterpretationSection: View {
    let title: String
    let orientation: CardOrientation
    let interpretation: Interpretation
    let orderedAspectKeys: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.headline)
                .foregroundStyle(orientation == .upright ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)

            Text(interpretation.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if !interpretation.keywords.isEmpty {
                Text(interpretation.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !interpretation.aspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aspectos").font(.subheadline).bold()
                    ForEach(aspectKeys(in: interpretation), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(aspect).bold()
                                Text(value).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !interpretation.contextual.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contexto por posición").font(.subheadline).bold()
                    ForEach(interpretation.contextual.keys.sorted(by: { $0.displayName < $1.displayName }), id: \.self) { key in
                        if let value = interpretation.contextual[key] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(key.displayName).bold()
                                Text(value).font(.body).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.tarotBorder, lineWidth: 1)
        )
    }

    private func aspectKeys(in interpretation: Interpretation) -> [String] {
        let knownKeys = orderedAspectKeys.filter { interpretation.aspects.keys.contains($0) }
        let extraKeys = interpretation.aspects.keys.sorted().filter { !knownKeys.contains($0) }
        return knownKeys + extraKeys
    }
}

private struct JournalDetail: View {
    let entry: JournalEntry
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Header info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.tarotGold)
                        Text(entry.savedAt.formatted(date: .long, time: .shortened))
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.spread.type?.label ?? "Tirada")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                    Text("\(entry.spread.drawnCards.count) cartas")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tarotGold)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.tarotPanel.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LinearGradient(colors: [Color.tarotGold.opacity(0.4), Color.tarotBurgundy.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )

                // Cards in the spread
                VStack(alignment: .leading, spacing: 12) {
                    Label("Cartas de la tirada", systemImage: "rectangle.stack.fill")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(Color.tarotGold)

                    ForEach(entry.spread.drawnCards, id: \.card.id) { drawn in
                        NavigationLink {
                            CardDetailView(drawn: drawn, repository: repository)
                        } label: {
                            HStack(spacing: 14) {
                                CardFace(
                                    name: drawn.card.name,
                                    imageName: drawn.card.imageName,
                                    textureName: drawn.card.textureImageName,
                                    reversed: drawn.orientation == .reversed,
                                    useTexture: true,
                                    size: CGSize(width: 52, height: 78),
                                    activeDeck: activeDeck,
                                    backDesign: cardBackDesign
                                )
                                .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(drawn.position.displayName)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.tarotGold)
                                    Text(drawn.card.name)
                                        .font(.system(size: 15, weight: .semibold, design: .serif))
                                        .foregroundStyle(.primary)
                                    if drawn.orientation == .reversed {
                                        Label("Invertida", systemImage: "arrow.down.circle")
                                            .font(.caption2)
                                            .foregroundStyle(Color.tarotBurgundy)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.tarotPanel.opacity(0.88))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.tarotBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Notes (if any)
                if !entry.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Notas del diario", systemImage: "pencil.line")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)

                        Text(entry.notes)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.primary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.88))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.tarotBorder, lineWidth: 1)
                    )
                }

                Spacer(minLength: 24)
            }
            .padding(20)
        }
        .navigationTitle(entry.spread.type?.label ?? "Tirada")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
private struct CardDetailText: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository

    var body: some View {
        let interpretation = repository.interpretation(for: card, position: nil, orientation: orientation)
        VStack(alignment: .leading, spacing: 12) {
            Label(orientation == .upright ? "Al derecho" : "Invertida", systemImage: orientation == .upright ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(orientation == .upright ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)
                .font(.headline)

            Text(interpretation.summary)

            if !interpretation.keywords.isEmpty {
                Text(interpretation.keywords.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !interpretation.aspects.isEmpty {
                Divider()
                Text("Consulta rápida").font(.subheadline).bold()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(interpretation.aspects.keys).sorted(), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            HStack(alignment: .top, spacing: 0) {
                                Text(aspect + ": ")
                                    .foregroundColor(.primary)
                                Text(value)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .font(.subheadline)
            }

            if orientation == .reversed {
                Text("Interpretación invertida mostrada arriba.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct CardFace: View {
    let name: String
    let imageName: String?
    let textureName: String?
    let reversed: Bool
    var back = false
    var useTexture = true
    var size: CGSize? = nil
    var activeDeck: DeckType = .riderWaite
    var backDesign: CardBackDesign = .classic

    private var cardSize: CGSize { size ?? CGSize(width: 150, height: 220) }

    var body: some View {
        ZStack {
            // Card base background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.tarotCardBase)

            if back {
                // Ornate Tarot Card Back
                CardBackView(cardSize: cardSize, design: backDesign)
            } else if let imageName, let platformImage = platformImage(named: imageName) {
                // Card Front Image: Edge-to-edge display matching reference card designs
                let cornerRadius: CGFloat = max(10, cardSize.width * 0.08)
                #if canImport(UIKit)
                Image(uiImage: platformImage)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.60), lineWidth: max(1.5, cardSize.width * 0.015))
                    )
                #elseif canImport(AppKit)
                Image(nsImage: platformImage)
                    .resizable()
                    .renderingMode(.original)
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.60), lineWidth: max(1.5, cardSize.width * 0.015))
                    )
                #endif
            } else {
                // Fallback card illustration when image is not present
                CardFallbackIllustration(name: name, size: cardSize)
            }

            // Visible Tactile Deck-Specific Texture Overlay
            if useTexture {
                CardTextureOverlayView(
                    cardSize: cardSize,
                    textureStyle: activeDeck.textureStyle
                )
            }

            // Outer Metallic Gold Foil Frame & Bevel Border
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.80, blue: 0.45),
                            Color(red: 0.65, green: 0.48, blue: 0.18),
                            Color(red: 0.98, green: 0.88, blue: 0.55),
                            Color(red: 0.70, green: 0.52, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, cardSize.width * 0.015)
                )

            // Inner Gold Inset Hairline Frame
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.50), lineWidth: 1)
                .padding(4)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
        .rotationEffect(reversed ? .degrees(180) : .zero)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(back ? "Carta boca abajo" : name)
    }

    private func platformImage(named name: String) -> PlatformImage? {
        let cleanName = (name as NSString).deletingPathExtension
        let candidates = ["\(activeDeck.rawValue)_\(cleanName)", cleanName]

        for candidate in candidates {
            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: "png") {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            if let resourceURL = Bundle.tarotContent.url(forResource: candidate, withExtension: nil) {
                #if canImport(UIKit)
                if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
                #elseif canImport(AppKit)
                if let img = NSImage(contentsOf: resourceURL) { return img }
                #endif
            }

            #if canImport(UIKit)
            if let img = UIImage(named: candidate, in: .tarotContent, compatibleWith: nil) { return img }
            #elseif canImport(AppKit)
            if let img = Bundle.tarotContent.image(forResource: candidate) { return img }
            #endif
        }

        return nil
    }
}

/// Procedural per-deck texture overlay — generates unique visual skin for each deck style.
private struct CardTextureOverlayView: View {
    let cardSize: CGSize
    let textureStyle: DeckTextureStyle

    var body: some View {
        ZStack {
            switch textureStyle {
            case .agedParchment:   agedParchmentLayer
            case .sacredGeometry:  sacredGeometryLayer
            case .softPastel:      softPastelLayer
            case .medievalEmbroidery: medievalEmbroideryLayer
            case .watercolor:      watercolorLayer
            case .grunge:          grungeLayer
            case .starfield:       starfieldLayer
            case .leafVeins:       leafVeinsLayer
            }
            // Universal edge vignette (use overlay to remain visible over card art)
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.12)],
                center: .center,
                startRadius: cardSize.width * 0.40,
                endRadius: cardSize.width * 0.80
            )
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Rider-Waite: Aged Parchment
    private var agedParchmentLayer: some View {
        ZStack {
            Canvas { context, size in
                let step: CGFloat = 3.5
                var path = Path()
                for x in stride(from: 0, to: size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.4, y: size.height))
                }
                context.stroke(path, with: .color(Color(red: 0.55, green: 0.38, blue: 0.15).opacity(0.055)), lineWidth: 0.5)
            }
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.92, blue: 0.80).opacity(0.13),
                         Color(red: 0.88, green: 0.76, blue: 0.55).opacity(0.20)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            // Gold vein lines
            Canvas { context, size in
                var vein = Path()
                vein.move(to: CGPoint(x: size.width * 0.2, y: 0))
                vein.addCurve(to: CGPoint(x: size.width * 0.8, y: size.height),
                              control1: CGPoint(x: size.width * 0.6, y: size.height * 0.3),
                              control2: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
                context.stroke(vein, with: .color(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.10)), lineWidth: 0.8)
            }
        }
    }

    // MARK: - Thoth: Sacred Geometry
    private var sacredGeometryLayer: some View {
        ZStack {
            Canvas { context, size in
                let cx = size.width / 2, cy = size.height / 2
                let radii: [CGFloat] = [size.width * 0.18, size.width * 0.35, size.width * 0.50]
                for r in radii {
                    let circ = Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2))
                    context.stroke(circ, with: .color(Color(red: 0.60, green: 0.45, blue: 0.92).opacity(0.14)), lineWidth: 0.75)
                }
                // Hexagram lines
                let pts6: [CGPoint] = (0..<6).map { i in
                    let a = Double(i) * .pi / 3 - .pi / 2
                    return CGPoint(x: cx + cos(a) * size.width * 0.44, y: cy + sin(a) * size.width * 0.44)
                }
                var star = Path()
                for i in 0..<6 {
                    star.move(to: pts6[i])
                    star.addLine(to: pts6[(i+3) % 6])
                }
                context.stroke(star, with: .color(Color(red: 0.72, green: 0.58, blue: 0.95).opacity(0.12)), lineWidth: 0.75)
            }
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.05, blue: 0.35).opacity(0.10),
                         Color(red: 0.45, green: 0.15, blue: 0.80).opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
    }

    // MARK: - Hello Kitty: Soft Pastel
    private var softPastelLayer: some View {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.88, blue: 0.95).opacity(0.18),
                     Color(red: 0.88, green: 0.92, blue: 1.0).opacity(0.15)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .blendMode(.screen)
    }

    // MARK: - Marseille: Medieval Embroidery
    private var medievalEmbroideryLayer: some View {
        ZStack {
            Canvas { context, size in
                let step: CGFloat = 14
                var grid = Path()
                for x in stride(from: 0, to: size.width, by: step) {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: 0, to: size.height, by: step) {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(Color(red: 0.65, green: 0.15, blue: 0.15).opacity(0.07)), lineWidth: 0.5)
                // Diagonal overlay
                var diag = Path()
                for x in stride(from: -size.height, to: size.width + size.height, by: step * 2) {
                    diag.move(to: CGPoint(x: x, y: 0))
                    diag.addLine(to: CGPoint(x: x + size.height, y: size.height))
                }
                context.stroke(diag, with: .color(Color(red: 0.15, green: 0.25, blue: 0.65).opacity(0.06)), lineWidth: 0.5)
            }
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.88, blue: 0.72).opacity(0.10),
                         Color(red: 0.82, green: 0.68, blue: 0.42).opacity(0.14)],
                startPoint: .top, endPoint: .bottom
            )
            .blendMode(.overlay)
        }
    }

    // MARK: - Osho: Watercolor
    private var watercolorLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.08),
                         Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.08),
                         Color(red: 0.8, green: 0.2, blue: 0.9).opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Soft circular blobs
                let blobs: [(x: CGFloat, y: CGFloat, r: CGFloat, op: CGFloat)] = [
                    (0.2, 0.25, 0.25, 0.07), (0.7, 0.4, 0.30, 0.06), (0.45, 0.70, 0.28, 0.08)
                ]
                for b in blobs {
                    let blob = Path(ellipseIn: CGRect(x: (b.x - b.r/2) * size.width,
                                                     y: (b.y - b.r/2) * size.height,
                                                     width: b.r * size.width,
                                                     height: b.r * size.height))
                    context.fill(blob, with: .color(Color(red: 0.5, green: 0.8, blue: 1.0).opacity(b.op)))
                }
            }
        }
    }

    // MARK: - Dark Side: Grunge
    private var grungeLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.18), Color(red: 0.1, green: 0.0, blue: 0.05).opacity(0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.multiply)
            Canvas { context, size in
                // Rough scratches
                var scratches = Path()
                let scratchCoords: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (0.1, 0.05, 0.35, 0.28), (0.6, 0.1, 0.80, 0.40),
                    (0.2, 0.6, 0.55, 0.90), (0.7, 0.5, 0.95, 0.75),
                    (0.05, 0.45, 0.30, 0.55), (0.65, 0.7, 0.85, 0.85)
                ]
                for s in scratchCoords {
                    scratches.move(to: CGPoint(x: s.0 * size.width, y: s.1 * size.height))
                    scratches.addLine(to: CGPoint(x: s.2 * size.width, y: s.3 * size.height))
                }
                context.stroke(scratches, with: .color(Color.white.opacity(0.07)), lineWidth: 0.8)
            }
        }
    }

    // MARK: - Celestial: Starfield
    private var starfieldLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.18).opacity(0.20),
                         Color(red: 0.10, green: 0.18, blue: 0.40).opacity(0.15)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Star dots
                let stars: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.05, 0.10, 1.2), (0.20, 0.30, 1.0), (0.35, 0.08, 0.9), (0.50, 0.22, 1.3),
                    (0.65, 0.12, 1.0), (0.80, 0.35, 1.2), (0.90, 0.05, 0.8),
                    (0.15, 0.55, 1.1), (0.40, 0.65, 0.9), (0.60, 0.75, 1.0),
                    (0.78, 0.60, 1.2), (0.25, 0.85, 0.8), (0.55, 0.90, 1.1), (0.88, 0.82, 1.0),
                    (0.72, 0.92, 0.9), (0.10, 0.78, 1.0), (0.45, 0.45, 0.8), (0.92, 0.48, 1.1)
                ]
                for s in stars {
                    let dot = Path(ellipseIn: CGRect(x: s.0 * size.width - s.2/2,
                                                    y: s.1 * size.height - s.2/2,
                                                    width: s.2, height: s.2))
                    context.fill(dot, with: .color(Color.white.opacity(0.55)))
                }
            }
        }
    }

    // MARK: - Botanical: Leaf Veins
    private var leafVeinsLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.40, blue: 0.20).opacity(0.10),
                         Color(red: 0.25, green: 0.55, blue: 0.25).opacity(0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .blendMode(.screen)
            Canvas { context, size in
                // Central midrib
                var vein = Path()
                vein.move(to: CGPoint(x: size.width * 0.5, y: 0))
                vein.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                context.stroke(vein, with: .color(Color(red: 0.2, green: 0.55, blue: 0.2).opacity(0.12)), lineWidth: 0.8)
                // Side veins
                let veinCount = 7
                for i in 0...veinCount {
                    let y = size.height * CGFloat(i) / CGFloat(veinCount)
                    var sv = Path()
                    sv.move(to: CGPoint(x: size.width * 0.5, y: y))
                    sv.addLine(to: CGPoint(x: size.width * 0.12, y: y - size.height * 0.06))
                    sv.move(to: CGPoint(x: size.width * 0.5, y: y))
                    sv.addLine(to: CGPoint(x: size.width * 0.88, y: y - size.height * 0.06))
                    context.stroke(sv, with: .color(Color(red: 0.2, green: 0.55, blue: 0.2).opacity(0.09)), lineWidth: 0.6)
                }
            }
        }
    }
}

/// Ornate Card Back View
private struct CardBackView: View {
    let cardSize: CGSize
    let design: CardBackDesign

    var body: some View {
        ZStack {
            switch design {
            case .classic:
                classicBackDesign
            case .mystical:
                mysticalBackDesign
            case .celestial:
                celestialBackDesign
            case .floral:
                floralBackDesign
            case .alchemical:
                alchemicalBackDesign
            case .darkMoon:
                darkMoonBackDesign
            }
        }
    }

    // MARK: - Classic (Deep Indigo + Gold)
    private var classicBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.20), Color(red: 0.14, green: 0.10, blue: 0.30), Color(red: 0.05, green: 0.04, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.85, green: 0.72, blue: 0.38), step: 20)
            backCenterEmblem(icon: "sparkles", text: "ARCANA", accentR: 0.92, accentG: 0.80, accentB: 0.45)
        }
    }

    // MARK: - Mystical (Deep Purple + Violet)
    private var mysticalBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.03, blue: 0.18), Color(red: 0.18, green: 0.08, blue: 0.34), Color(red: 0.06, green: 0.04, blue: 0.14)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.72, green: 0.58, blue: 0.92), step: 18)
            backCenterEmblem(icon: "moon.stars.fill", text: "MYSTERIUM", accentR: 0.85, accentG: 0.70, accentB: 1.0)
        }
    }

    // MARK: - Celestial (Deep Space Blue)
    private var celestialBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.38), Color(red: 0.01, green: 0.02, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Starfield
            Canvas { context, size in
                let stars: [(CGFloat, CGFloat, CGFloat)] = [
                    (0.12, 0.08, 1.8), (0.35, 0.15, 1.2), (0.65, 0.05, 1.5), (0.88, 0.18, 1.0),
                    (0.22, 0.45, 1.3), (0.50, 0.30, 2.0), (0.78, 0.42, 1.1), (0.08, 0.70, 1.4),
                    (0.40, 0.65, 1.6), (0.72, 0.58, 1.2), (0.55, 0.80, 1.8), (0.18, 0.88, 1.0),
                    (0.85, 0.75, 1.5), (0.95, 0.90, 1.0), (0.30, 0.92, 1.3), (0.62, 0.95, 1.1)
                ]
                for s in stars {
                    let dot = Path(ellipseIn: CGRect(x: s.0 * size.width - s.2/2, y: s.1 * size.height - s.2/2, width: s.2, height: s.2))
                    context.fill(dot, with: .color(Color.white.opacity(0.75)))
                }
            }
            backCenterEmblem(icon: "star.fill", text: "COSMOS", accentR: 0.40, accentG: 0.72, accentB: 1.0)
        }
    }

    // MARK: - Floral Art Nouveau (Emerald + Gold)
    private var floralBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.18, blue: 0.10), Color(red: 0.08, green: 0.28, blue: 0.14), Color(red: 0.02, green: 0.10, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.45, green: 0.78, blue: 0.42), step: 16)
            backCenterEmblem(icon: "leaf.fill", text: "NATURA", accentR: 0.55, accentG: 0.88, accentB: 0.45)
        }
    }

    // MARK: - Alchemical (Amber + Dark Brown)
    private var alchemicalBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.08, blue: 0.02), Color(red: 0.28, green: 0.14, blue: 0.04), Color(red: 0.10, green: 0.05, blue: 0.01)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Alchemical symbol grid
            Canvas { context, size in
                let step: CGFloat = 22
                var tria = Path()
                for x in stride(from: step, to: size.width - step, by: step * 2.5) {
                    for y in stride(from: step, to: size.height - step, by: step * 2.5) {
                        // Triangle up
                        tria.move(to: CGPoint(x: x, y: y + step * 0.6))
                        tria.addLine(to: CGPoint(x: x - step * 0.5, y: y - step * 0.3))
                        tria.addLine(to: CGPoint(x: x + step * 0.5, y: y - step * 0.3))
                        tria.closeSubpath()
                    }
                }
                context.stroke(tria, with: .color(Color(red: 0.95, green: 0.72, blue: 0.28).opacity(0.14)), lineWidth: 0.8)
            }
            backCenterEmblem(icon: "flame.fill", text: "PRIMA MATERIA", accentR: 0.95, accentG: 0.72, accentB: 0.28)
        }
    }

    // MARK: - Dark Moon (Charcoal + Silver)
    private var darkMoonBackDesign: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.08), Color(red: 0.12, green: 0.10, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            backLatticePattern(color: Color(red: 0.60, green: 0.60, blue: 0.70), step: 24)
            backCenterEmblem(icon: "moon.fill", text: "LUNA NIGRA", accentR: 0.65, accentG: 0.65, accentB: 0.80)
        }
    }

    // MARK: - Shared Helpers
    private func backLatticePattern(color: Color, step: CGFloat) -> some View {
        Canvas { context, size in
            var lattice = Path()
            for x in stride(from: -size.height, to: size.width + size.height, by: step) {
                lattice.move(to: CGPoint(x: x, y: 0))
                lattice.addLine(to: CGPoint(x: x + size.height, y: size.height))
                lattice.move(to: CGPoint(x: x, y: size.height))
                lattice.addLine(to: CGPoint(x: x + size.height, y: 0))
            }
            context.stroke(lattice, with: .color(color.opacity(0.13)), lineWidth: 0.75)
        }
    }

    private func backCenterEmblem(icon: String, text: String, accentR: Double, accentG: Double, accentB: Double) -> some View {
        let accent = Color(red: accentR, green: accentG, blue: accentB)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(LinearGradient(colors: [accent, accent.opacity(0.4)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                    .frame(width: max(32, cardSize.width * 0.38), height: max(32, cardSize.width * 0.38))
                Image(systemName: icon)
                    .font(.system(size: max(18, cardSize.width * 0.20), weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [accent, accent.opacity(0.65)], startPoint: .top, endPoint: .bottom))
            }
            Text(text)
                .font(.system(size: max(7, cardSize.width * 0.07), weight: .bold, design: .serif))
                .tracking(1.8)
                .foregroundStyle(accent.opacity(0.85))
        }
    }

    private func platformImage(named name: String) -> PlatformImage? {
        let cleanName = (name as NSString).deletingPathExtension
        if let resourceURL = Bundle.tarotContent.url(forResource: cleanName, withExtension: "png") {
            #if canImport(UIKit)
            if let img = UIImage(contentsOfFile: resourceURL.path) { return img }
            #elseif canImport(AppKit)
            if let img = NSImage(contentsOf: resourceURL) { return img }
            #endif
        }
        return nil
    }
}

/// Fallback Illustration when Card Image is not available
private struct CardFallbackIllustration: View {
    let name: String
    let size: CGSize

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.28), Color(red: 0.08, green: 0.06, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 12) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: max(24, size.width * 0.22)))
                    .foregroundStyle(Color(red: 0.92, green: 0.80, blue: 0.45))

                Text(name)
                    .font(.system(size: max(11, size.width * 0.09), weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
            }
        }
    }
}

extension Color {
    // Rider-Waite deep navy base
    static var tarotBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(red: 0.04, green: 0.08, blue: 0.16)
        #endif
    }

    // Aged parchment/cream panel
    static var tarotPanel: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.96, green: 0.92, blue: 0.84).opacity(0.10)
        #endif
    }

    // Card base background for image containers
    static var tarotCardBase: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(red: 0.96, green: 0.94, blue: 0.89)
        #endif
    }

    // Antique gold border
    static var tarotBorder: Color {
        Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.20)
    }

    // Deep amber shadow
    static var tarotShadow: Color {
        Color(red: 0.40, green: 0.22, blue: 0.04).opacity(0.22)
    }

    // Antique gold accent
    static var tarotGold: Color {
        Color(red: 0.78, green: 0.58, blue: 0.18)
    }

    // Rider-Waite burgundy
    static var tarotBurgundy: Color {
        Color(red: 0.42, green: 0.10, blue: 0.10)
    }
}

private extension Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// SpreadType.label is defined in Spread.swift (all 18 cases, including Phase 4)

extension CardSuit {
    var displayName: String {
        switch self {
        case .wands: return "Bastos"
        case .cups: return "Copas"
        case .swords: return "Espadas"
        case .pentacles: return "Oros"
        }
    }
}
