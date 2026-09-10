import SwiftUI
import TarotCore
import TarotContent

struct RiderReferenceView: View {
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign
    @State private var query = ""
    @State private var orientation: CardOrientation = .upright

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                Picker("Orientación", selection: $orientation) {
                    Text("Al derecho").tag(CardOrientation.upright)
                    Text("Invertida").tag(CardOrientation.reversed)
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                List(filteredCards) { card in
                    NavigationLink {
                        ReferenceCardView(card: card, orientation: orientation, repository: repository, activeDeck: activeDeck, cardBackDesign: cardBackDesign)
                    } label: {
                        referenceRow(for: card)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        TarotAudioService.shared.playCardSelect()
                    })
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .searchable(text: $query, prompt: "Buscar en el libro Rider")
                .listStyle(.plain)
                .listRowSeparator(.hidden)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Libro Rider")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Libro Rider-Waite")
                .font(.title2).bold()
            Text("Explora las 78 cartas con su significado completo, su orientación al derecho e invertida y sus elementos más importantes de amor, economía, salud y carrera.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label("78 cartas", systemImage: "rectangle.stack.fill")
                    .font(.caption)
                    .padding(10)
                    .background(Color.tarotPanel.opacity(0.95))
                    .cornerRadius(12)
                Label("Formato limpio", systemImage: "book.closed.fill")
                    .font(.caption)
                    .padding(10)
                    .background(Color.tarotPanel.opacity(0.95))
                    .cornerRadius(12)
                Label("Orientación y contexto", systemImage: "sparkles")
                    .font(.caption)
                    .padding(10)
                    .background(Color.tarotPanel.opacity(0.95))
                    .cornerRadius(12)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color.tarotPanel.opacity(0.90))
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.top)
    }

    var filteredCards: [Card] {
        if query.isEmpty { return repository.allCards() }
        return repository.search(query: query)
    }

    @ViewBuilder
    private func referenceRow(for card: Card) -> some View {
        HStack(spacing: 14) {
            CardFace(
                name: card.name,
                imageName: card.imageName,
                textureName: card.textureImageName,
                reversed: orientation == .reversed,
                useTexture: true,
                size: CGSize(width: 56, height: 82)
            )
            .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)

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
                    if let bc = card.bookContent, !bc.isEmpty {
                        Image(systemName: "books.vertical.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.tarotGold.opacity(0.80))
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

/// Esoteric / expanded reference panel with 8 collapsible sections
private struct EsotericReferencePanel: View {
    let card: Card
    let interpretation: Interpretation

    @State private var expanded: [Bool] = Array(repeating: false, count: 8)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ficha Esotérica").font(.headline)
            VStack(spacing: 6) {
                disclosure(0, title: "📜 Descripción clásica", content: card.bookContent ?? interpretation.summary)
                disclosure(1, title: "🔤 Letra Hebrea", content: card.kabbalah ?? "—")
                disclosure(2, title: "🌳 Sendero del Árbol de la Vida", content: card.numerology ?? card.kabbalah ?? "No disponible")
                disclosure(3, title: "🪐 Astrología", content: astrologyText())
                disclosure(4, title: "⚗️ Principio Alquímico", content: card.element ?? card.numerology ?? "—")
                disclosure(5, title: "🧘 Chakra Asociado", content: card.chakras ?? "—")
                disclosure(6, title: "🎴 Respuesta Sí / No / Tal vez", content: card.yesNo ?? "—")
                disclosure(7, title: "📿 Meditación + Afirmación", content: meditationText())
            }
            .padding()
            .background(Color.tarotPanel.opacity(0.92))
            .cornerRadius(14)
        }
        .padding(.top)
    }

    private func disclosure(_ idx: Int, title: String, content: String) -> some View {
        DisclosureGroup(isExpanded: Binding(get: { expanded[idx] }, set: { expanded[idx] = $0 })) {
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            HStack {
                Text(title).bold().font(.subheadline)
                Spacer()
            }
        }
        .accentColor(Color.tarotGold)
        .padding(.vertical, 6)
    }

    private func astrologyText() -> String {
        var parts: [String] = []
        if let astro = card.astrology { parts.append("Signo: \(astro)") }
        if let decan = card.zodiacalDecan { parts.append("Decanato: \(decan)") }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    private func meditationText() -> String {
        var s = ""
        if let a = card.affirmation { s += "Afirmación: " + a }
        else if let ls = card.lightShadow { s += ls }
        if s.isEmpty { s = "—" }
        return s
    }
}

struct ReferenceCardView: View {
    let card: Card
    let orientation: CardOrientation
    let repository: any CardRepository
    let activeDeck: DeckType
    let cardBackDesign: CardBackDesign

    init(card: Card, orientation: CardOrientation, repository: any CardRepository, activeDeck: DeckType = .riderWaite, cardBackDesign: CardBackDesign = .classic) {
        self.card = card
        self.orientation = orientation
        self.repository = repository
        self.activeDeck = activeDeck
        self.cardBackDesign = cardBackDesign
    }

    private var currentInterpretation: Interpretation {
        repository.interpretation(for: card, position: nil, orientation: orientation)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    CardFace(
                        name: card.name,
                        imageName: card.imageName,
                        textureName: card.textureImageName,
                        reversed: orientation == .reversed,
                        useTexture: true,
                        size: CGSize(width: 280, height: 420),
                        activeDeck: activeDeck,
                        backDesign: cardBackDesign
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.name).font(.title).bold()
                        HStack(spacing: 10) {
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
                    .padding(.horizontal, 4)
                }
                .padding()
                .background(Color.tarotPanel.opacity(0.96))
                .cornerRadius(24)
                .shadow(color: Color.tarotShadow.opacity(0.35), radius: 15, x: 0, y: 8)

                // Book content from OCR (Fiebig & Bürger)
                if let bookContent = card.bookContent, !bookContent.isEmpty {
                    BookContentBlock(text: bookContent)
                }

                BookInfoGrid(card: card, interpretation: currentInterpretation)
                BookHighlightsView(interpretation: currentInterpretation)

                CardBookSection(title: orientation == .upright ? "Al derecho" : "Invertida", interpretation: currentInterpretation)

                // Esoteric detail panel with 8 collapsible sections
                EsotericReferencePanel(card: card, interpretation: currentInterpretation)

                if !currentInterpretation.keywords.isEmpty {
                    Divider()
                    Text("Palabras clave relevantes").font(.headline)
                    Text(currentInterpretation.keywords.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 28)
            }
            .padding()
        }
        .navigationTitle(card.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct BookInfoGrid: View {
    let card: Card
    let interpretation: Interpretation
    private let highlightedKeys = ["Amor", "Economía", "Salud", "Carrera"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Palo", systemImage: "suit.club.fill")
                Spacer()
                Text(card.suit?.displayName ?? "Arcano Mayor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Número", systemImage: "number")
                Spacer()
                Text(card.number ?? "—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Origen", systemImage: "book.fill")
                Spacer()
                Text("Rider-Waite")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Ilustración", systemImage: "photo.on.rectangle.angled")
                Spacer()
                Text("Original Rider-Waite")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Encyclopedic Data
            if card.astrology != nil || card.kabbalah != nil || card.element != nil || card.yesNo != nil || card.chakras != nil {
                Divider()
                Text("Simbología y Correspondencias").font(.subheadline).bold()

                if let element = card.element {
                    HStack {
                        Text("Elemento:").bold().font(.caption)
                        Spacer()
                        Text(element).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let astrology = card.astrology {
                    HStack {
                        Text("Astrología:").bold().font(.caption)
                        Spacer()
                        Text(astrology).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let numerology = card.numerology {
                    HStack {
                        Text("Numerología:").bold().font(.caption)
                        Spacer()
                        Text(numerology).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let kabbalah = card.kabbalah {
                    HStack(alignment: .top) {
                        Text("Cábala:").bold().font(.caption)
                        Spacer()
                        Text(kabbalah).font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let lightShadow = card.lightShadow {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Luz y Sombra:").bold().font(.caption)
                        Text(lightShadow).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let yesNo = card.yesNo {
                    HStack(alignment: .top) {
                        Text("Respuesta (Sí/No):").bold().font(.caption)
                        Spacer()
                        Text(yesNo).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let chakras = card.chakras {
                    HStack(alignment: .top) {
                        Text("Chakras:").bold().font(.caption)
                        Spacer()
                        Text(chakras).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let crystals = card.crystals {
                    HStack(alignment: .top) {
                        Text("Cristales:").bold().font(.caption)
                        Spacer()
                        Text(crystals).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let mythology = card.mythology {
                    HStack(alignment: .top) {
                        Text("Mitología:").bold().font(.caption)
                        Spacer()
                        Text(mythology).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let decan = card.zodiacalDecan {
                    HStack(alignment: .top) {
                        Text("Decanato:").bold().font(.caption)
                        Spacer()
                        Text(decan).font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let affirmation = card.affirmation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Afirmación:").bold().font(.caption)
                        Text(affirmation).font(.caption).italic().foregroundStyle(.secondary)
                    }
                }
            }

            if !interpretation.aspects.isEmpty {
                Divider()
                Text("Aspectos clave").font(.subheadline).bold()
                ForEach(highlightedKeys.filter { interpretation.aspects[$0] != nil }, id: \.self) { aspect in
                    if let value = interpretation.aspects[aspect] {
                        HStack(alignment: .top, spacing: 4) {
                            Text(aspect + ":").bold().font(.caption)
                            Text(value).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.90))
        .cornerRadius(16)
    }
}

private struct BookHighlightsView: View {
    let interpretation: Interpretation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Consulta rápida").font(.headline)
            Text("Explora los elementos más importantes en Amor, Economía, Salud y Carrera sin perder de vista el mensaje completo del libro Rider.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !interpretation.keywords.isEmpty {
                HStack(alignment: .top) {
                    Text("Palabras clave:").bold().font(.caption)
                    Text(interpretation.keywords.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                }
            }

            if !interpretation.aspects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(interpretation.aspects.keys).sorted(), id: \.self) { aspect in
                        if let value = interpretation.aspects[aspect] {
                            HStack(alignment: .top, spacing: 8) {
                                Text(aspect).bold().font(.caption)
                                Text(value).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.88))
        .cornerRadius(16)
    }
}

private struct CardBookSection: View {
    let title: String
    let interpretation: Interpretation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: title == "Al derecho" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.headline)
                .foregroundStyle(title == "Al derecho" ? Color(red: 0.20, green: 0.46, blue: 0.28) : Color.tarotBurgundy)

            Text(interpretation.summary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)

            if !interpretation.aspects.isEmpty {
                SectionHeader(title: "Aspectos")
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(interpretation.aspects.sorted(by: { $0.key < $1.key }), id: \.key) { aspect, value in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(aspect).bold()
                            Text(value).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.tarotPanel.opacity(0.96))
                        .cornerRadius(14)
                        .shadow(color: Color.tarotShadow.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                }
            }

            if !interpretation.contextual.isEmpty {
                SectionHeader(title: "Detalles por posición")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(interpretation.contextual.sorted(by: { $0.key.displayName < $1.key.displayName }), id: \.key) { position, value in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(position.displayName).bold()
                            Text(value).font(.body).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color.tarotPanel.opacity(0.96))
                        .cornerRadius(14)
                        .shadow(color: Color.tarotShadow.opacity(0.18), radius: 6, x: 0, y: 3)
                    }
                }
            }
        }
        .padding()
        .background(Color.tarotPanel.opacity(0.12))
        .cornerRadius(24)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline).bold()
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

/// Book-page typography block — reads like the real PDF, clean and refined
struct BookContentBlock: View {
    let text: String
    @State private var expanded = false
    @Environment(\.colorScheme) private var colorScheme

    private var sanitizedText: String {
        Self.sanitize(text)
    }

    private let previewLength = 450

    var isLong: Bool { sanitizedText.count > previewLength }
    var displayText: String {
        guard isLong && !expanded else { return sanitizedText }
        let prefix = String(sanitizedText.prefix(previewLength))
        let lastSpace = prefix.lastIndex(of: " ") ?? prefix.endIndex
        return String(prefix[..<lastSpace]) + "…"
    }

    public static func sanitize(_ raw: String) -> String {
        var s = raw

        // ── 1. Common OCR character substitutions ───────────────────────────
        let ocr: [(String, String)] = [
            // Accented vowels misread
            ("Tü", "Tú"), ("tü", "tú"), ("ü", "ú"),
            ("ä", "á"), ("ë", "é"), ("ï", "í"), ("ö", "ó"),
            ("Ä", "Á"), ("Ë", "É"), ("Ï", "Í"), ("Ö", "Ó"), ("Ü", "Ú"),
            // Inverted punctuation
            ("¿ ", "¿"), (" ?", "?"), (" !", "!"),
            // Common word errors
            ("derache", "derecho"), ("clernidad", "eternidad"),
            ("jy vive", "¡y vive"), ("sı́", "sí"), ("asl", "así"),
            ("mâs", "más"), ("mas ", "más "), ("tamblén", "también"),
            ("lntuitivo", "Intuitivo"), ("lnicio", "Inicio"),
            ("revel ación", "revelación"), ("transfor mación", "transformación"),
            ("poten cial", "potencial"), ("espiri tual", "espiritual"),
            // OCR ligatures
            ("ﬁ", "fi"), ("ﬂ", "fl"), ("ﬀ", "ff"), ("ﬃ", "ffi"), ("ﬄ", "ffl"),
            // Hyphen artifacts from line-break hyphenation
            ("- ", ""), (" -\n", ""),
            // Double spaces
        ]
        for (from, to) in ocr {
            s = s.replacingOccurrences(of: from, with: to)
        }

        // Remove double-spaces
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }

        // ── 2. Strip TOC residues ────────────────────────────────────────────
        if s.contains("Arcanos Menores:") || s.contains("Reina de bastos") || s.contains("........") {
            let markers = ["•", "Significado", "La carta", "Esta carta", "Simboliza", "Descripción"]
            var earliest: String.Index? = nil
            for m in markers {
                if let r = s.range(of: m) {
                    if earliest == nil || r.lowerBound < earliest! { earliest = r.lowerBound }
                }
            }
            if let start = earliest { s = String(s[start...]) }
        }

        // ── 3. Remove dot-leaders (table of contents style) ─────────────────
        // e.g. "Capítulo 1 .......... 12"
        let dotPattern = try? NSRegularExpression(pattern: "\\.{3,}\\s*\\d*", options: [])
        if let pattern = dotPattern {
            s = pattern.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
        }

        // ── 4. Join mid-sentence line breaks ────────────────────────────────
        let lines = s.components(separatedBy: .newlines)
        var cleanLines: [String] = []
        for line in lines {
            let l = line.trimmingCharacters(in: .whitespaces)
            if l.isEmpty {
                // Preserve paragraph breaks (empty lines)
                if cleanLines.last != "" { cleanLines.append("") }
            } else if cleanLines.isEmpty {
                cleanLines.append(l)
            } else {
                let last = cleanLines.last!
                // Join if previous line doesn't end with sentence-ending punctuation
                // and current line doesn't start with a capital (continuation)
                let endsWithPunctuation = last.last.map { [".", "!", "?", ":", "•", ";", "»", "\""].contains($0) } ?? false
                let startsNewSentence = l.first?.isUppercase == true && last.last == "."
                if !endsWithPunctuation && !startsNewSentence && !last.isEmpty {
                    cleanLines[cleanLines.count - 1] = last + " " + l
                } else {
                    cleanLines.append(l)
                }
            }
        }

        // ── 5. Remove consecutive empty lines (max 1 paragraph break) ───────
        var result: [String] = []
        var lastWasEmpty = false
        for line in cleanLines {
            if line.isEmpty {
                if !lastWasEmpty { result.append(line) }
                lastWasEmpty = true
            } else {
                result.append(line)
                lastWasEmpty = false
            }
        }

        return result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Attribution header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("GUÍA DEFINITIVA")
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .tracking(2.5)
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                Text("·")
                    .font(.system(size: 9, design: .serif))
                    .foregroundStyle(Color.tarotGold.opacity(0.40))
                Text("FIEBIG & BÜRGER")
                    .font(.system(size: 9, weight: .regular, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Color.tarotGold.opacity(0.60))
                Spacer()
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.tarotGold.opacity(0.50))
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Thin rule
            Rectangle()
                .fill(Color.tarotGold.opacity(0.22))
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            // Body text — serif, generous line height, multiline
            Text(displayText)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(colorScheme == .dark
                    ? Color(red: 0.88, green: 0.85, blue: 0.78)
                    : Color(red: 0.15, green: 0.12, blue: 0.08))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, isLong ? 4 : 18)
                .animation(.easeInOut(duration: 0.28), value: expanded)

            // Expand / collapse button
            if isLong {
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Text(expanded ? "Mostrar menos" : "Continuar leyendo")
                            .font(.system(size: 12, weight: .regular, design: .serif))
                            .tracking(0.5)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.tarotGold.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color(red: 0.12, green: 0.09, blue: 0.06).opacity(0.85)
                    : Color(red: 0.97, green: 0.94, blue: 0.88).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.tarotGold.opacity(0.20), lineWidth: 0.5)
        )
        .shadow(color: Color(red: 0.40, green: 0.22, blue: 0.04).opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
