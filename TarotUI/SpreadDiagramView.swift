import SwiftUI
import TarotCore
import TarotContent

// MARK: - SpreadDiagramView
/// Renders a real, visual diagram representation of a tarot spread with exact spatial card placement,
/// gold connecting guides, glowing halos, and interactive 3D reveal states.

public struct SpreadDiagramView: View {
    let spread: Spread
    let repository: any CardRepository
    let revealedIndices: Set<Int>
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    let onSelectCard: (DrawnCard) -> Void
    let onReplaceCard: ((Int, SpreadPosition) -> Void)?
 
    public init(
        spread: Spread,
        repository: any CardRepository,
        revealedIndices: Set<Int>,
        activeDeck: DeckType = .riderWaite,
        cardBackDesign: CardBackDesign = .classic,
        onSelectCard: @escaping (DrawnCard) -> Void,
        onReplaceCard: ((Int, SpreadPosition) -> Void)? = nil
    ) {
        self.spread = spread
        self.repository = repository
        self.revealedIndices = revealedIndices
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
        self.onSelectCard = onSelectCard
        self.onReplaceCard = onReplaceCard
    }

    public var body: some View {
        VStack(spacing: 20) {
            switch spread.type {
            case .celticCross:
                celticCrossLayout
            case .threeCard:
                threeCardLayout
            case .fiveCard:
                fiveCardLayout
            case .horseshoe:
                horseshoeLayout
            case .relationship:
                relationshipLayout
            case .twelveMonth:
                twelveMonthLayout
            case .decision:
                decisionLayout
            default:
                standardGridLayout
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - 1. Celtic Cross (10 Cards Real Diagram)
    private var celticCrossLayout: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "rhombus.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.tarotGold)
                Text("Cruz Celta · Diagrama Sagrado")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotGold)
                Image(systemName: "rhombus.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.tarotGold)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 36) {

                    // ── LEFT: CENTRAL CROSS ───────────────────────
                    ZStack {
                        // Background gold cross guide lines
                        Rectangle()
                            .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.0), Color.tarotGold.opacity(0.25), Color.tarotGold.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 2, height: 380)

                        Rectangle()
                            .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.0), Color.tarotGold.opacity(0.25), Color.tarotGold.opacity(0.0)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 300, height: 2)

                        // Outline container
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.tarotGold.opacity(0.03))
                            .frame(width: 320, height: 420)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(
                                        LinearGradient(colors: [Color.tarotGold.opacity(0.35), Color.tarotBurgundy.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                            )

                        // Position 4: Encima (Top)
                        if spread.drawnCards.count > 4 {
                            cardCell(index: 4, size: CGSize(width: 82, height: 118))
                                .offset(y: -140)
                        }

                        // Position 5: Debajo (Bottom)
                        if spread.drawnCards.count > 5 {
                            cardCell(index: 5, size: CGSize(width: 82, height: 118))
                                .offset(y: 140)
                        }

                        // Position 2: Pasado (Left)
                        if spread.drawnCards.count > 2 {
                            cardCell(index: 2, size: CGSize(width: 82, height: 118))
                                .offset(x: -110)
                        }

                        // Position 3: Futuro (Right)
                        if spread.drawnCards.count > 3 {
                            cardCell(index: 3, size: CGSize(width: 82, height: 118))
                                .offset(x: 110)
                        }

                        // Position 0: Presente (Center Base)
                        if spread.drawnCards.count > 0 {
                            cardCell(index: 0, size: CGSize(width: 86, height: 126))
                        }

                        // Position 1: Desafío (Crossed 90° over Center)
                        if spread.drawnCards.count > 1 {
                            cardCell(index: 1, size: CGSize(width: 82, height: 118))
                                .rotationEffect(.degrees(90))
                                .shadow(color: Color.black.opacity(0.5), radius: 10)
                        }
                    }

                    // ── RIGHT: VERTICAL STAFF (Cards 6..9) ───────
                    VStack(spacing: 12) {
                        Text("Báculo del Destino")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)

                        if spread.drawnCards.count > 9 { cardCell(index: 9, size: CGSize(width: 85, height: 120)) }
                        if spread.drawnCards.count > 8 { cardCell(index: 8, size: CGSize(width: 85, height: 120)) }
                        if spread.drawnCards.count > 7 { cardCell(index: 7, size: CGSize(width: 85, height: 120)) }
                        if spread.drawnCards.count > 6 { cardCell(index: 6, size: CGSize(width: 85, height: 120)) }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.tarotGold.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.tarotGold.opacity(0.35), Color.tarotBurgundy.opacity(0.15)], startPoint: .top, endPoint: .bottom),
                                lineWidth: 1
                            )
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 2. Three Card Layout
    private var threeCardLayout: some View {
        VStack(spacing: 18) {
            Text("Pasado · Presente · Futuro")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            HStack(spacing: 16) {
                ForEach(0..<min(3, spread.drawnCards.count), id: \.self) { idx in
                    cardCell(index: idx, size: CGSize(width: 102, height: 158))
                    if idx < min(2, spread.drawnCards.count - 1) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.tarotGold.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - 3. Five Card Layout (Cross Shape)
    private var fiveCardLayout: some View {
        VStack(spacing: 18) {
            Text("Disposición en Cruz de 5 Cartas")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            VStack(spacing: 14) {
                if spread.drawnCards.count > 4 { cardCell(index: 4, size: CGSize(width: 92, height: 138)) }

                HStack(spacing: 18) {
                    if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 92, height: 138)) }
                    if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 98, height: 148)) }
                    if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 92, height: 138)) }
                }

                if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 92, height: 138)) }
            }
        }
    }

    // MARK: - 4. Horseshoe Layout (U-Shape Arch)
    private var horseshoeLayout: some View {
        VStack(spacing: 18) {
            Text("Herradura de 7 Cartas")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 82, height: 124)).offset(y: 42) }
                    if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 82, height: 124)).offset(y: 16) }
                    if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 82, height: 124)).offset(y: -8) }
                    if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 88, height: 132)).offset(y: -28) }
                    if spread.drawnCards.count > 4 { cardCell(index: 4, size: CGSize(width: 82, height: 124)).offset(y: -8) }
                    if spread.drawnCards.count > 5 { cardCell(index: 5, size: CGSize(width: 82, height: 124)).offset(y: 16) }
                    if spread.drawnCards.count > 6 { cardCell(index: 6, size: CGSize(width: 82, height: 124)).offset(y: 42) }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
    }

    // MARK: - 5. Relationship Layout
    private var relationshipLayout: some View {
        VStack(spacing: 18) {
            Text("Lectura de Relaciones y Pareja")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            HStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Tú").font(.caption.weight(.bold)).foregroundStyle(Color.tarotGold)
                    if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 86, height: 128)) }
                    if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 86, height: 128)) }
                }

                VStack(spacing: 12) {
                    Text("Conexión").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    if spread.drawnCards.count > 4 { cardCell(index: 4, size: CGSize(width: 86, height: 128)) }
                    if spread.drawnCards.count > 5 { cardCell(index: 5, size: CGSize(width: 86, height: 128)) }
                    if spread.drawnCards.count > 6 { cardCell(index: 6, size: CGSize(width: 86, height: 128)) }
                }

                VStack(spacing: 12) {
                    Text("Pareja").font(.caption.weight(.bold)).foregroundStyle(Color.tarotBurgundy)
                    if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 86, height: 128)) }
                    if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 86, height: 128)) }
                }
            }
        }
    }

    // MARK: - 6. Twelve Month Wheel
    private var twelveMonthLayout: some View {
        VStack(spacing: 18) {
            Text("Rueda Astrológica de 12 Meses")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                ForEach(0..<min(12, spread.drawnCards.count), id: \.self) { idx in
                    cardCell(index: idx, size: CGSize(width: 92, height: 132))
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - 7. Decision Spread
    private var decisionLayout: some View {
        VStack(spacing: 18) {
            Text("Tirada de Decisión")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotGold)

            VStack(spacing: 18) {
                if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 98, height: 144)) }

                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Opción A").font(.caption.bold()).foregroundStyle(Color.tarotGold)
                        if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 92, height: 134)) }
                    }

                    VStack(spacing: 8) {
                        Text("Opción B").font(.caption.bold()).foregroundStyle(Color.tarotBurgundy)
                        if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 92, height: 134)) }
                    }
                }

                if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 98, height: 144)) }
            }
        }
    }

    // MARK: - Fallback Adaptive Grid
    private var standardGridLayout: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 16)], spacing: 16) {
            ForEach(spread.drawnCards.indices, id: \.self) { idx in
                cardCell(index: idx, size: CGSize(width: 145, height: 215))
            }
        }
    }

    // MARK: - Individual Card Cell Helper with Gold Glow Aura & Badge
    private func cardCell(index: Int, size: CGSize) -> some View {
        let drawn = spread.drawnCards[index]
        let isRevealed = revealedIndices.contains(index)

        return Button {
            onSelectCard(drawn)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Gold aura only when revealed
                    if isRevealed {
                        Circle()
                            .fill(Color.tarotGold.opacity(0.30))
                            .frame(width: size.width * 0.9, height: size.height * 0.9)
                            .blur(radius: 16)
                    }

                    // Front face (revealed)
                    CardFace(
                        name: drawn.card.name,
                        imageName: drawn.card.imageName,
                        textureName: drawn.card.textureImageName,
                        reversed: drawn.orientation == .reversed,
                        useTexture: true,
                        size: size,
                        activeDeck: activeDeck,
                        backDesign: cardBackDesign
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.tarotGold, Color.tarotBurgundy],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: isRevealed ? 1.5 : 0
                            )
                    )
                    .shadow(color: Color.tarotGold.opacity(isRevealed ? 0.50 : 0), radius: 14, x: 0, y: 6)
                    .opacity(isRevealed ? 1 : 0)
                    .rotation3DEffect(.degrees(isRevealed ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.4)

                    // Back face (not yet revealed)
                    CardFace(
                        name: drawn.card.name,
                        imageName: nil,
                        textureName: nil,
                        reversed: false,
                        back: true,
                        size: size,
                        activeDeck: activeDeck,
                        backDesign: cardBackDesign
                    )
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
                    .opacity(isRevealed ? 0 : 1)
                    .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
                }

                // Position Tag Label with Foil Border
                Text(drawn.position.displayName)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.95))
                    .lineLimit(1)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.tarotPanel.opacity(0.95))
                            .overlay(
                                Capsule().stroke(
                                    LinearGradient(colors: [Color.tarotGold, Color.tarotGold.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                                    lineWidth: 0.8
                                )
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onSelectCard(drawn)
            } label: {
                Label("Ver detalles", systemImage: "eye")
            }
            Button {
                onReplaceCard?(index, drawn.position)
            } label: {
                Label("Cambiar carta", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.70, blendDuration: 0), value: isRevealed)
    }
}
