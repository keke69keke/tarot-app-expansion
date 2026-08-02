import SwiftUI
import TarotCore
import TarotContent

// MARK: - Chat Models

public struct ChatMessage: Identifiable, Equatable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date

    public enum Role: Equatable {
        case user
        case assistant
        case system
    }

    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - AI Chat Service

@MainActor
final class TarotAIChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var apiKey: String
    private let repository: any CardRepository

    private let systemPrompt = """
    Eres una lectora de tarot sabia, empática y perspicaz llamada "Arcana". \
    Tu especialidad es el Tarot Rider-Waite y sus 78 cartas. \
    Respondes siempre en español con un tono cálido, misterioso y espiritual. \
    Cuando el usuario pregunta sobre una carta específica, describes su simbolismo, \
    arquetipos y cómo puede aplicarse a su situación. \
    Cuando el usuario pide una lectura, haces preguntas clarificadoras antes de proceder. \
    Siempre recuerdas que el tarot es una herramienta de reflexión y autoconocimiento, \
    no predicción del futuro. Usas emojis de luna, estrellas y cartas ocasionalmente. \
    Mantienes las respuestas concisas (máximo 3 párrafos) a menos que se pida detalle. \
    No tienes acceso a internet ni a información externa; solo tu conocimiento del tarot.
    """

    init(apiKey: String, repository: any CardRepository) {
        self.apiKey = apiKey
        self.repository = repository
    }

    func updateAPIKey(_ key: String) {
        self.apiKey = key
    }

    func send(userMessage: String) async {
        let userMsg = ChatMessage(role: .user, content: userMessage)
        messages.append(userMsg)
        isLoading = true
        errorMessage = nil

        do {
            let reply = try await callOpenAI(userMessage: userMessage)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            if let chatError = error as? ChatError {
                errorMessage = chatError.localizedDescription
            } else {
                errorMessage = "Error de conexión: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    func clearHistory() {
        messages.removeAll()
    }

    private func callOpenAI(userMessage: String) async throws -> String {
        guard !apiKey.isEmpty, apiKey != "sk-..." else {
            // Fallback: local tarot response engine
            return try await localTarotResponse(for: userMessage)
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var history: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for msg in messages.dropLast() {
            switch msg.role {
            case .user: history.append(["role": "user", "content": msg.content])
            case .assistant: history.append(["role": "assistant", "content": msg.content])
            default: break
            }
        }
        history.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": history,
            "temperature": 0.85,
            "max_tokens": 600
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 {
                throw ChatError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
                throw ChatError.rateLimited
            }
            throw ChatError.serverError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatError.parseError
        }
        return content
    }

    // MARK: - Local Tarot Engine (no API key needed)
    private func localTarotResponse(for query: String) async throws -> String {
        // Small artificial delay for realism
        try await Task.sleep(nanoseconds: 900_000_000)

        let q = query.lowercased()
        let allCards = repository.allCards()

        // Check if query mentions a specific card
        if let card = allCards.first(where: { q.contains($0.name.lowercased()) }) {
            let interp = repository.interpretation(for: card, position: nil, orientation: .upright)
            return """
            ✨ **\(card.name)** es una carta de gran profundidad. \
            \(interp.summary)

            🌙 Palabras clave: \(interp.keywords.prefix(5).joined(separator: " · "))

            Recuerda que las cartas son espejos de tu alma interior. ¿Qué resuena más contigo en este momento?
            """
        }

        // Draw a random card for general questions
        let randomCard = allCards.randomElement()!
        let interp = repository.interpretation(for: randomCard, position: nil, orientation: .upright)

        let responses = [
            """
            🌟 Las cartas me muestran **\(randomCard.name)** para tu pregunta.

            \(interp.summary)

            ¿Hay algo específico en tu vida sobre lo que quieras explorar con mayor profundidad?
            """,
            """
            ✨ El universo responde con **\(randomCard.name)**.

            \(interp.summary)

            Energías presentes: \(interp.keywords.prefix(4).joined(separator: " · ")). ¿Cómo se relaciona esto con tu situación?
            """,
            """
            🔮 Siento la energía de **\(randomCard.name)** rodeando tu pregunta.

            \(interp.summary)

            Las cartas siempre revelan lo que necesitamos ver, no siempre lo que queremos. ¿Qué te habla esta energía?
            """
        ]

        return responses.randomElement()!
    }
}

enum ChatError: LocalizedError {
    case invalidAPIKey
    case rateLimited
    case serverError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: return "API Key inválida. Ve a Ajustes y verifica tu clave de OpenAI."
        case .rateLimited: return "Demasiadas consultas. Espera un momento antes de continuar."
        case .serverError(let code): return "Error del servidor (\(code)). Intenta de nuevo."
        case .parseError: return "Error al procesar la respuesta. Intenta de nuevo."
        }
    }
}

// MARK: - TarotChatView

public struct TarotChatView: View {
    @StateObject private var service: TarotAIChatService
    @State private var inputText = ""
    @State private var showClearAlert = false
    @Environment(\.colorScheme) private var colorScheme

    // Suggested questions
    private let suggestions = [
        "¿Qué me dice El Loco?",
        "Necesito una lectura rápida",
        "¿Qué significa La Torre?",
        "Léeme para el amor",
        "¿Cómo interpreto cartas invertidas?",
        "Explícame el significado de La Luna"
    ]

    public init(apiKey: String, repository: any CardRepository) {
        _service = StateObject(wrappedValue: TarotAIChatService(apiKey: apiKey, repository: repository))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                backgroundGradient

                VStack(spacing: 0) {
                    // Messages list
                    messagesArea

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("Arcana IA")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 30, height: 30)
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Arcana IA")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(service.isLoading ? "escribiendo..." : "Lectora de Tarot")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showClearAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(service.messages.isEmpty)
                }
                #endif
            }
            .alert("Limpiar conversación", isPresented: $showClearAlert) {
                Button("Limpiar", role: .destructive) { service.clearHistory() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Borrar todos los mensajes de esta sesión?")
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.04, green: 0.06, blue: 0.14), Color(red: 0.06, green: 0.03, blue: 0.12)]
                    : [Color(red: 0.97, green: 0.95, blue: 0.90), Color(red: 0.92, green: 0.88, blue: 0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient orbs
            Circle()
                .fill(Color(red: 0.78, green: 0.58, blue: 0.18).opacity(colorScheme == .dark ? 0.08 : 0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color(red: 0.42, green: 0.10, blue: 0.10).opacity(colorScheme == .dark ? 0.10 : 0.04))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 140, y: 100)
        }
    }

    // MARK: - Messages Area

    @ViewBuilder
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Welcome banner if empty
                    if service.messages.isEmpty {
                        welcomeBanner
                    }

                    // Messages
                    ForEach(service.messages) { message in
                        if message.role != .system {
                            MessageBubble(message: message)
                                .id(message.id)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                        }
                    }

                    // Typing indicator
                    if service.isLoading {
                        TypingIndicator()
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                            .id("typing")
                    }

                    // Error message
                    if let error = service.errorMessage {
                        ErrorBanner(message: error)
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                    }

                    Color.clear.frame(height: 12).id("bottom")
                }
                .padding(.top, 12)
            }
            .onChange(of: service.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: service.isLoading) { loading in
                if loading {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Welcome Banner

    private var welcomeBanner: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.20), Color(red: 0.42, green: 0.10, blue: 0.10).opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 90, height: 90)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.92, green: 0.78, blue: 0.45), Color(red: 0.65, green: 0.45, blue: 0.20)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 0.98, green: 0.90, blue: 0.60), Color(red: 0.85, green: 0.65, blue: 0.30)],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            .shadow(color: Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.40), radius: 20)

            VStack(spacing: 8) {
                Text("Arcana IA")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Tu guía de tarot con inteligencia artificial.\nHaz preguntas sobre cartas, tiradas o pide una lectura.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Suggestion chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Prueba preguntando:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                FlowLayout(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            Task { await service.send(userMessage: suggestion) }
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.78, green: 0.58, blue: 0.18))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.10))
                                        .overlay(Capsule().stroke(Color(red: 0.78, green: 0.58, blue: 0.18).opacity(0.30), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.tarotPanel.opacity(0.70))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.tarotBorder, lineWidth: 1))
            )
        }
        .padding(24)
        .padding(.top, 12)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Pregunta a Arcana...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $inputText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(minHeight: 38, maxHeight: 120)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.tarotPanel.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.tarotBorder.opacity(inputText.isEmpty ? 1 : 2), lineWidth: 1)
                    )
            )

            // Send button
            Button {
                sendMessage()
            } label: {
                ZStack {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading {
                        Circle()
                            .fill(Color.secondary.opacity(0.20))
                            .frame(width: 40, height: 40)
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 40, height: 40)
                    }

                    Image(systemName: service.isLoading ? "ellipsis" : "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.tarotBorder.opacity(0.5))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !service.isLoading else { return }
        inputText = ""
        Task { await service.send(userMessage: text) }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            if !isUser {
                // Arcana avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Bubble
                Text(LocalizedStringKey(markdownSafe(message.content)))
                    .font(.body)
                    .foregroundStyle(isUser ? Color.white : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.tarotPanel.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.tarotBorder.opacity(0.5), lineWidth: 1)
                )
        }
    }

    /// Converts **bold** markdown for SwiftUI LocalizedStringKey compatibility
    private func markdownSafe(_ text: String) -> String {
        text // SwiftUI's Text with LocalizedStringKey handles **bold** natively
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Arcana avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.78, green: 0.58, blue: 0.18), Color(red: 0.42, green: 0.10, blue: 0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.tarotGold)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .opacity(phase == i ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.tarotPanel.opacity(0.95))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tarotBorder.opacity(0.5), lineWidth: 1))
            )

            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                phase = 1
            }
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.tarotBurgundy)
                .font(.caption)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.tarotBurgundy)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.tarotBurgundy.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.tarotBurgundy.opacity(0.25), lineWidth: 1))
        )
    }
}

// MARK: - FlowLayout (wrapping chip layout)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.minX + bounds.minX, y: frame.minY + bounds.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    y += rowHeight + spacing
                    x = 0
                    rowHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
