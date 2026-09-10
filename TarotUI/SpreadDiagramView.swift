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
            case .astrological:
                astrologicalLayout
            case .chakraSpread:
                chakraSpreadLayout
            case .hexagram:
                hexagramLayout
            // Phase 4 Esoteric Spreads
            case .temperance:
                temperanceLayout
            case .treeOfLife:
                treeOfLifeLayout
            case .starDavid:
                starDavidLayout
            case .soulMirror:
                soulMirrorLayout
            case .alchemyPath:
                alchemyPathLayout
            case .moonCycle:
                moonCycleLayout
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

    // MARK: - Phase 3 Layouts
    
    private var chakraSpreadLayout: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Chakras in ascending order: Root at bottom, Crown at top
                // Wait, visually root is 0, crown is 6. To have crown on top we must reverse them.
                ForEach((0..<min(7, spread.drawnCards.count)).reversed(), id: \.self) { idx in
                    cardCell(index: idx, size: CGSize(width: 145, height: 215))
                }
            }
            .padding(.vertical, 30)
        }
    }
    
    private var astrologicalLayout: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 40) {
                // Simplified 12-house layout for Astrological Spread
                // Grouping them into columns or a grid for better display on phones
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 16)], spacing: 20) {
                    ForEach(0..<min(12, spread.drawnCards.count), id: \.self) { idx in
                        cardCell(index: idx, size: CGSize(width: 145, height: 215))
                    }
                }
            }
            .padding(.vertical, 30)
        }
    }
    
    private var hexagramLayout: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 30) {
                // Top point
                if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 145, height: 215)) }
                
                // Middle row
                HStack(spacing: 40) {
                    if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 145, height: 215)) }
                    if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 145, height: 215)) }
                }
                
                // Center
                if spread.drawnCards.count > 6 { cardCell(index: 6, size: CGSize(width: 145, height: 215)) }
                
                // Bottom row
                HStack(spacing: 40) {
                    if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 145, height: 215)) }
                    if spread.drawnCards.count > 4 { cardCell(index: 4, size: CGSize(width: 145, height: 215)) }
                }
                
                // Bottom point
                if spread.drawnCards.count > 5 { cardCell(index: 5, size: CGSize(width: 145, height: 215)) }
            }
            .padding(.vertical, 30)
        }
    }

    // MARK: - Phase 4: La Templanza (6 Cards — Alchemical Balance)
    private var temperanceLayout: some View {
        VStack(spacing: 20) {
            spreadHeader(title: "✦ La Templanza — Equilibrio Alquímico", subtitle: "Arcano XIV · Unión de Opuestos")

            // Top: synthesis card
            if spread.drawnCards.count > 5 {
                cardCell(index: 5, size: CGSize(width: 105, height: 158))
                    .overlay(alignment: .top) {
                        Text("SÍNTESIS").font(.system(size: 9, weight: .black, design: .serif))
                            .foregroundStyle(Color.tarotGold).offset(y: -18)
                    }
            }

            // Two columns: Water (left) vs Fire (right)
            HStack(alignment: .top, spacing: 30) {
                VStack(spacing: 12) {
                    columnHeader("💧 AGUA", color: Color(red: 0.3, green: 0.6, blue: 1.0))
                    if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 96, height: 144)) }
                    if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 96, height: 144)) }
                }
                // Center vertical divider
                Rectangle()
                    .fill(LinearGradient(colors: [Color.tarotGold.opacity(0), Color.tarotGold.opacity(0.5), Color.tarotGold.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 1.5, height: 320)

                VStack(spacing: 12) {
                    columnHeader("🔥 FUEGO", color: Color(red: 1.0, green: 0.4, blue: 0.2))
                    if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 96, height: 144)) }
                    if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 96, height: 144)) }
                }
            }

            // Bottom: imbalance card
            if spread.drawnCards.count > 4 {
                cardCell(index: 4, size: CGSize(width: 105, height: 158))
                    .overlay(alignment: .bottom) {
                        Text("DESEQUILIBRIO").font(.system(size: 9, weight: .black, design: .serif))
                            .foregroundStyle(Color.tarotBurgundy).offset(y: 18)
                    }
            }
        }
    }

    // MARK: - Phase 4: Árbol de la Vida (10 Cards — Sephiroth)
    private var treeOfLifeLayout: some View {
        VStack(spacing: 16) {
            spreadHeader(title: "✦ Árbol de la Vida", subtitle: "Las 10 Sefirot de la Cábala Hermética")
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    // Kether (0) — top center
                    sephiraRow([0])
                    // Chokmah (1) + Binah (2)
                    sephiraRow([1, 2])
                    // Chesed (3) + Geburah (4)
                    sephiraRow([3, 4])
                    // Tiphareth (5) — center
                    sephiraRow([5])
                    // Netzach (6) + Hod (7)
                    sephiraRow([6, 7])
                    // Yesod (8) — center
                    sephiraRow([8])
                    // Malkuth (9) — bottom center
                    sephiraRow([9])
                }
                .padding(.vertical, 20)
            }
        }
    }

    private func sephiraRow(_ indices: [Int]) -> some View {
        HStack(spacing: indices.count == 1 ? 0 : 44) {
            ForEach(indices, id: \.self) { idx in
                if spread.drawnCards.count > idx {
                    cardCell(index: idx, size: CGSize(width: 86, height: 128))
                }
            }
        }
    }

    // MARK: - Phase 4: Estrella de David (7 Cards — Star of David)
    private var starDavidLayout: some View {
        VStack(spacing: 16) {
            spreadHeader(title: "✦ Estrella de David", subtitle: "Hexagrama Sagrado · 6 Elementos + Centro")
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top point (North — Fire)
                    HStack { Spacer(); if spread.drawnCards.count > 0 { cardCell(index: 0, size: CGSize(width: 90, height: 134)) }; Spacer() }
                        .padding(.bottom, 6)
                    // Top row (NE + NW)
                    HStack(spacing: 80) {
                        if spread.drawnCards.count > 4 { cardCell(index: 4, size: CGSize(width: 88, height: 130)) }
                        if spread.drawnCards.count > 1 { cardCell(index: 1, size: CGSize(width: 88, height: 130)) }
                    }
                    // Center — Integration
                    ZStack {
                        Circle().fill(Color.tarotGold.opacity(0.10)).frame(width: 110, height: 110)
                        Circle().stroke(Color.tarotGold.opacity(0.35), lineWidth: 1).frame(width: 110, height: 110)
                        if spread.drawnCards.count > 6 { cardCell(index: 6, size: CGSize(width: 90, height: 134)) }
                    }
                    // Bottom row (SE + SW)
                    HStack(spacing: 80) {
                        if spread.drawnCards.count > 2 { cardCell(index: 2, size: CGSize(width: 88, height: 130)) }
                        if spread.drawnCards.count > 5 { cardCell(index: 5, size: CGSize(width: 88, height: 130)) }
                    }
                    // Bottom point (South — Air)
                    HStack { Spacer(); if spread.drawnCards.count > 3 { cardCell(index: 3, size: CGSize(width: 90, height: 134)) }; Spacer() }
                        .padding(.top, 6)
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Phase 4: Espejo del Alma (9 Cards — Soul Mirror)
    private var soulMirrorLayout: some View {
        VStack(spacing: 16) {
            spreadHeader(title: "✦ Espejo del Alma", subtitle: "Integración de la Sombra · Jung & Tarot")
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<min(9, spread.drawnCards.count), id: \.self) { idx in
                        cardCell(index: idx, size: CGSize(width: 100, height: 150))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Phase 4: Gran Obra Alquímica (4 Cards — Alchemy)
    private var alchemyPathLayout: some View {
        VStack(spacing: 20) {
            spreadHeader(title: "✦ La Gran Obra Alquímica", subtitle: "Las 4 Fases de la Transmutación del Alma")

            // 4 cards in horizontal progression with phase labels + color aura
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    alchemyPhase(index: 0, name: "NIGREDO", color: Color.black, emoji: "🌑")
                    alchemyArrow()
                    alchemyPhase(index: 1, name: "ALBEDO", color: Color.white.opacity(0.8), emoji: "🌕")
                    alchemyArrow()
                    alchemyPhase(index: 2, name: "CITRINITAS", color: Color(red: 1, green: 0.85, blue: 0.2), emoji: "☀️")
                    alchemyArrow()
                    alchemyPhase(index: 3, name: "RUBEDO", color: Color(red: 0.85, green: 0.1, blue: 0.15), emoji: "🜂")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }

    private func alchemyPhase(index: Int, name: String, color: Color, emoji: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji).font(.title2)
            if spread.drawnCards.count > index {
                cardCell(index: index, size: CGSize(width: 102, height: 152))
                    .shadow(color: color.opacity(0.5), radius: 12, x: 0, y: 4)
            }
            Text(name)
                .font(.system(size: 10, weight: .black, design: .serif))
                .foregroundStyle(color == .white.opacity(0.8) ? Color.white : color)
                .tracking(1.5)
        }
    }

    private func alchemyArrow() -> some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.tarotGold.opacity(0.6))
            .padding(.top, 60)
    }

    // MARK: - Phase 4: Ciclo Lunar (4 Cards — Moon Phases)
    private var moonCycleLayout: some View {
        VStack(spacing: 20) {
            spreadHeader(title: "✦ Ciclo Lunar", subtitle: "Las 4 Fases de la Luna como Guía Espiritual")

            // Arc layout: cards in a semicircle with moon phases
            ZStack(alignment: .top) {
                // Moon arc background
                Canvas { context, size in
                    var arc = Path()
                    arc.addArc(center: CGPoint(x: size.width / 2, y: size.height + 60),
                               radius: size.height + 40,
                               startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
                    context.stroke(arc, with: .color(Color.tarotGold.opacity(0.2)), lineWidth: 1.5)
                }
                .frame(height: 320)

                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 18) {
                        moonPhaseCard(index: 0, phase: "🌑 Luna Nueva", yOffset: 30)
                        moonPhaseCard(index: 1, phase: "🌓 Creciente", yOffset: 0)
                        moonPhaseCard(index: 2, phase: "🌕 Llena", yOffset: -20)
                        moonPhaseCard(index: 3, phase: "🌗 Menguante", yOffset: 0)
                    }
                }
            }
        }
    }

    private func moonPhaseCard(index: Int, phase: String, yOffset: CGFloat) -> some View {
        VStack(spacing: 8) {
            if spread.drawnCards.count > index {
                cardCell(index: index, size: CGSize(width: 82, height: 122))
            }
            Text(phase)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.tarotGold.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .offset(y: yOffset)
    }

    // MARK: - Shared Header Helper
    private func spreadHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "rhombus.fill").font(.caption2).foregroundStyle(Color.tarotGold)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.tarotGold)
                Image(systemName: "rhombus.fill").font(.caption2).foregroundStyle(Color.tarotGold)
            }
            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(Color.tarotGold.opacity(0.65))
                .italic()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }

    private func columnHeader(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .serif))
            .foregroundStyle(color)
            .tracking(1.5)
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
            TarotAudioService.shared.playCardFlip()
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
