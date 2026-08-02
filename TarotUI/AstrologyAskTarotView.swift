import SwiftUI
import TarotCore
import TarotContent

// MARK: - Zodiac Signs

public enum ZodiacSign: String, CaseIterable, Identifiable {
    case aries = "Aries"
    case taurus = "Tauro"
    case gemini = "Géminis"
    case cancer = "Cáncer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Escorpio"
    case sagittarius = "Sagitario"
    case capricorn = "Capricornio"
    case aquarius = "Acuario"
    case pisces = "Piscis"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }

    public var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fuego"
        case .taurus, .virgo, .capricorn: return "Tierra"
        case .gemini, .libra, .aquarius: return "Aire"
        case .cancer, .scorpio, .pisces: return "Agua"
        }
    }

    public var dates: String {
        switch self {
        case .aries: return "21 Mar - 19 Abr"
        case .taurus: return "20 Abr - 20 May"
        case .gemini: return "21 May - 20 Jun"
        case .cancer: return "21 Jun - 22 Jul"
        case .leo: return "23 Jul - 22 Ago"
        case .virgo: return "23 Ago - 22 Sep"
        case .libra: return "23 Sep - 22 Oct"
        case .scorpio: return "23 Oct - 21 Nov"
        case .sagittarius: return "22 Nov - 21 Dic"
        case .capricorn: return "22 Dic - 19 Ene"
        case .aquarius: return "20 Ene - 18 Feb"
        case .pisces: return "19 Feb - 20 Mar"
        }
    }

    public var dailyHoroscope: String {
        switch self {
        case .aries:
            return "Hoy la energía del Fuego impulsa tu intuición. Es un excelente momento para iniciar proyectos con liderazgo. El Tarot te invita a actuar con valentía sin descuidar los detalles."
        case .taurus:
            return "La estabilidad de la Tierra te brinda paciencia. El universo sugiere consolidar tus finanzas y buscar paz en tus relaciones. Una carta de Oros rige tu jornada."
        case .gemini:
            return "Tu mente brilla con creatividad y comunicación fluida. Las cartas sugieren tomar decisiones importantes con claridad y honestidad interior."
        case .cancer:
            return "Momento de reconectar con tu mundo emocional y tu familia. Las cartas de Copas indican bendiciones afectivas e intuición elevada hoy."
        case .leo:
            return "Tu magnetismo personal está al máximo. Confía en tu fuerza y brilla sin temor. La rueda del destino gira a tu favor en temas de proyectos."
        case .virgo:
            return "Día ideal para organizar tu espacio y tus pensamientos. El orden te traerá serenidad. El Tarot promete respuestas claras a lo que dudas."
        case .libra:
            return "La armonía y el equilibrio guían tu día. Es un momento propicio para solucionar desacuerdos y rodearte de arte y belleza."
        case .scorpio:
            return "Transformación profunda e intuición aguda. Revelaciones importantes en temas personales. Confía en tu poder de regeneración."
        case .sagittarius:
            return "Expansión, optimismo y deseos de explorar nuevos horizontes. La energía del Tarot favorece viajes, estudios y decisiones valientes."
        case .capricorn:
            return "Tu disciplina da frutos sólidos. Mantén tu enfoque en tus metas a largo plazo. La perseverancia te coronará con éxito."
        case .aquarius:
            return "Ideas innovadoras y visión de futuro. Un encuentro o reflexión inesperada te abrirá nuevas perspectivas en tu camino."
        case .pisces:
            return "Sensibilidad y conexión espiritual amplificadas. Escucha tus sueños e corazonadas hoy; traen mensajes valiosos de guía."
        }
    }
}

// MARK: - Ask Tarot View (Pregunta al Tarot)

public struct AskTarotView: View {
    let repository: any CardRepository
    @State private var question: String = ""
    @State private var selectedTopic: String = "General"
    @State private var drawnCard: Card? = nil
    @State private var isRevealed: Bool = false
    @State private var isShuffling: Bool = false

    private let topics = ["General", "Amor", "Trabajo", "Dinero", "Decisión Sí/No"]

    public init(repository: any CardRepository) {
        self.repository = repository
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Header Hero Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.tarotGold)
                            Text("CONSULTA AL ORÁCULO")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(2)
                                .foregroundStyle(Color.tarotGold)
                        }
                        Text("Pregunta al Tarot")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(.primary)

                        Text("Escribe cualquier pregunta personal o inquietud y consulta las cartas para recibir una respuesta orientadora personalizada.")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.tarotGold.opacity(0.5), Color.tarotBurgundy.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )

                    // Topic Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tema de tu consulta")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.tarotGold)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(topics, id: \.self) { t in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedTopic = t
                                        }
                                    } label: {
                                        Text(t)
                                            .font(.system(size: 13, weight: .semibold, design: .serif))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(selectedTopic == t
                                                        ? LinearGradient(colors: [Color.tarotGold, Color(red: 0.75, green: 0.55, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                                                        : LinearGradient(colors: [Color.tarotPanel.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                                    )
                                            )
                                            .overlay(
                                                Capsule().stroke(selectedTopic == t ? Color.clear : Color.tarotGold.opacity(0.25), lineWidth: 0.8)
                                            )
                                            .foregroundStyle(selectedTopic == t ? Color(red: 0.04, green: 0.08, blue: 0.16) : Color.primary)
                                            .shadow(color: selectedTopic == t ? Color.tarotGold.opacity(0.35) : Color.clear, radius: 8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Question Input Box
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tu Pregunta")
                            .font(.system(size: 15, weight: .bold, design: .serif))

                        TextField("Ej: ¿Cómo debo actuar en mi trabajo esta semana?", text: $question)
                            .font(.system(size: 15, design: .serif))
                            .padding(16)
                            .background(Color.tarotPanel.opacity(0.95))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.tarotGold.opacity(0.35), lineWidth: 1)
                            )
                    }

                    // Draw Button
                    Button {
                        guard !question.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isShuffling = true
                        drawnCard = nil
                        isRevealed = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let all = repository.allCards()
                            drawnCard = all.randomElement()
                            isShuffling = false
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isRevealed = true
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isShuffling ? "sparkles" : "hand.tap.fill")
                            Text(isShuffling ? "Consultando al Oráculo…" : "Consultar Tarot")
                                .font(.system(size: 16, weight: .bold, design: .serif))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LinearGradient(colors: [Color.tarotGold, Color.tarotBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .foregroundStyle(Color(red: 0.97, green: 0.93, blue: 0.82))
                        .shadow(color: Color.tarotGold.opacity(0.4), radius: 14, x: 0, y: 6)
                        .opacity(question.isEmpty ? 0.5 : 1)
                    }
                    .disabled(question.isEmpty || isShuffling)

                    // Answer Result Block
                    if let card = drawnCard {
                        VStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.tarotGold)
                                Text("RESPUESTA DEL TAROT")
                                    .font(.system(size: 12, weight: .bold, design: .serif))
                                    .tracking(2)
                                    .foregroundStyle(Color.tarotGold)
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.tarotGold)
                            }

                            ZStack {
                                Circle()
                                    .fill(Color.tarotGold.opacity(0.30))
                                    .frame(width: 160, height: 160)
                                    .blur(radius: 20)

                                CardFace(name: card.name, imageName: card.imageName, textureName: card.textureImageName, reversed: false, useTexture: true, size: CGSize(width: 150, height: 225))
                                    .shadow(color: Color.tarotGold.opacity(0.5), radius: 18, x: 0, y: 8)
                            }

                            Text(card.name)
                                .font(.system(size: 22, weight: .bold, design: .serif))

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "quote.opening")
                                        .font(.caption)
                                        .foregroundStyle(Color.tarotGold)
                                    Text(question)
                                        .font(.system(size: 14, weight: .medium, design: .serif).italic())
                                        .foregroundStyle(Color.tarotGold)
                                }

                                Divider().overlay(Color.tarotGold.opacity(0.3))

                                let interp = repository.interpretation(for: card, position: nil, orientation: .upright)
                                Text(interp.summary)
                                    .font(.system(size: 15, design: .serif))
                                    .lineSpacing(7)
                                    .foregroundStyle(.primary.opacity(0.95))

                                if selectedTopic == "Decisión Sí/No" {
                                    HStack(spacing: 8) {
                                        Text("Veredicto:")
                                            .font(.system(size: 14, weight: .bold, design: .serif))
                                        Text(card.arcanaType == .major ? "✨ SÍ (Muy Favorable)" : "⚖️ Depende de tu voluntad")
                                            .font(.system(size: 14, weight: .semibold, design: .serif))
                                            .foregroundStyle(Color.tarotGold)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(20)
                            .background(Color.tarotPanel.opacity(0.92))
                            .cornerRadius(22)
                        }
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.tarotGold.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [Color.tarotGold.opacity(0.5), Color.tarotBurgundy.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Pregunta al Tarot")
        }
    }
}

// MARK: - Horoscopes View (Horóscopo Diario por Signo)

public struct HoroscopeView: View {
    @State private var selectedSign: ZodiacSign = .aries
    let repository: any CardRepository

    public init(repository: any CardRepository) {
        self.repository = repository
    }

    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.sparkles.fill")
                                .foregroundStyle(Color.tarotGold)
                            Text("ZODÍACO & TAROT")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(2)
                                .foregroundStyle(Color.tarotGold)
                        }
                        Text("Horóscopo Astrológico")
                            .font(.system(size: 26, weight: .bold, design: .serif))

                        Text("Selecciona tu signo para consultar tu lectura astral y la energía de las cartas que rigen tu jornada.")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.tarotGold.opacity(0.5), Color.tarotBurgundy.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )

                    // Zodiac Grid Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ZodiacSign.allCases) { sign in
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedSign = sign
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(sign.symbol)
                                            .font(.system(size: 32))
                                        Text(sign.rawValue)
                                            .font(.system(size: 12, weight: .semibold, design: .serif))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(selectedSign == sign
                                                ? Color.tarotGold.opacity(0.24)
                                                : Color.tarotPanel.opacity(0.90)
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(selectedSign == sign ? Color.tarotGold : Color.tarotGold.opacity(0.15), lineWidth: selectedSign == sign ? 1.5 : 0.8)
                                    )
                                    .foregroundStyle(selectedSign == sign ? Color.tarotGold : Color.primary)
                                    .shadow(color: selectedSign == sign ? Color.tarotGold.opacity(0.3) : Color.clear, radius: 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Sign Detail Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 10) {
                                Text(selectedSign.symbol)
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.tarotGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedSign.rawValue)
                                        .font(.system(size: 24, weight: .bold, design: .serif))
                                    Text(selectedSign.dates)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("Elemento: \(selectedSign.element)")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.tarotGold.opacity(0.2)))
                                .foregroundStyle(Color.tarotGold)
                        }

                        Rectangle()
                            .fill(LinearGradient(colors: [Color.tarotGold.opacity(0.05), Color.tarotGold.opacity(0.4), Color.tarotGold.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 1)

                        Text("Lectura Astrológica de Hoy")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)

                        Text(selectedSign.dailyHoroscope)
                            .font(.system(size: 15, weight: .regular, design: .serif))
                            .lineSpacing(8)
                            .foregroundStyle(.primary.opacity(0.95))
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.tarotPanel.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Color.tarotGold.opacity(0.4), Color.tarotBurgundy.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.tarotShadow.opacity(0.3), radius: 12)
                }
                .padding(20)
            }
            .navigationTitle("Horóscopo")
        }
    }
}
