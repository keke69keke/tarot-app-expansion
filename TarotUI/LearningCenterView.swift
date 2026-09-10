import SwiftUI
import TarotCore

// MARK: - Book Cover Colors (deterministic from title hash)
private func bookCoverGradient(for title: String) -> [Color] {
    let palettes: [[Color]] = [
        [Color(red: 0.42, green: 0.10, blue: 0.35), Color(red: 0.18, green: 0.05, blue: 0.28)],   // deep purple
        [Color(red: 0.55, green: 0.30, blue: 0.05), Color(red: 0.28, green: 0.12, blue: 0.02)],   // amber
        [Color(red: 0.08, green: 0.22, blue: 0.42), Color(red: 0.04, green: 0.08, blue: 0.22)],   // midnight blue
        [Color(red: 0.35, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.04, blue: 0.04)],   // deep crimson
        [Color(red: 0.05, green: 0.28, blue: 0.22), Color(red: 0.02, green: 0.12, blue: 0.10)],   // teal emerald
        [Color(red: 0.40, green: 0.35, blue: 0.05), Color(red: 0.18, green: 0.14, blue: 0.02)],   // gold
        [Color(red: 0.22, green: 0.05, blue: 0.40), Color(red: 0.10, green: 0.02, blue: 0.20)],   // violet
        [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.18, green: 0.10, blue: 0.22)],   // dark
        [Color(red: 0.38, green: 0.18, blue: 0.02), Color(red: 0.18, green: 0.08, blue: 0.01)],   // copper
    ]
    let idx = abs(title.hashValue) % palettes.count
    return palettes[idx]
}

private func bookCoverIcon(for title: String) -> String {
    let icons = ["books.vertical.fill", "scroll.fill", "moon.stars.fill", "sparkles",
                 "flame.fill", "leaf.fill", "star.fill", "eye.fill", "atom"]
    return icons[abs(title.hashValue) % icons.count]
}

// MARK: - Premium Book Cover Card
private struct BookCoverCard: View {
    let title: String
    let subtitle: String
    let size: CGSize
    @State private var hovered = false

    var body: some View {
        let colors = bookCoverGradient(for: title)
        let icon = bookCoverIcon(for: title)

        ZStack(alignment: .bottomLeading) {
            // Background gradient
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))

            // Decorative pattern
            Canvas { context, sz in
                let step: CGFloat = 22
                var p = Path()
                for x in stride(from: -sz.height, to: sz.width + sz.height, by: step) {
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + sz.height, y: sz.height))
                    p.move(to: CGPoint(x: x, y: sz.height))
                    p.addLine(to: CGPoint(x: x + sz.height, y: 0))
                }
                context.stroke(p, with: .color(Color.white.opacity(0.06)), lineWidth: 0.75)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Top icon
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.25))
                        .padding(12)
                }
                Spacer()
            }

            // Bottom text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .lineLimit(1)
            }
            .padding(10)

            // Gold border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(colors: [Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.6),
                                             Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.15)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(hovered ? 1.03 : 1.0)
        .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: hovered ? 18 : 10, x: 0, y: 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
        .onHover { hovered = $0 }
    }
}

// MARK: - LearningCenterView (Premium Redesign)
public struct LearningCenterView: View {
    @StateObject private var libraryManager = LibraryManager()
    @State private var showingFilePicker = false
    @State private var showingBrowser = false
    @State private var selectedSection: LibrarySection = .books
    @State private var animateIn = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Deep background gradient
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.04, blue: 0.10), Color(red: 0.08, green: 0.04, blue: 0.16)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: Header
                        headerView
                            .padding(.bottom, 20)

                        // MARK: Mystic Music Player
                        MysticMusicPlayerBar()
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        // MARK: Section Tabs
                        sectionTabs
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        // MARK: Content
                        switch selectedSection {
                        case .books:    booksSection
                        case .spreads:  spreadsInfoSection
                        case .tools:    toolsSection
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    try? libraryManager.importPDF(from: url)
                }
            }
            .sheet(isPresented: $showingBrowser) {
                NavigationStack {
                    TarotWebBrowserView()
                        .navigationTitle("Navegador Arcano")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button("Cerrar") { showingBrowser = false }
                            }
                        }
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { animateIn = true } }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biblioteca Arcana")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(red: 0.95, green: 0.85, blue: 0.50),
                                                     Color(red: 0.78, green: 0.58, blue: 0.22)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Sabiduría Esotérica · \(libraryManager.importedBooks.count) libros")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.7))
                }
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -20)
    }

    // MARK: - Section Tabs
    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(LibrarySection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: section.icon).font(.caption)
                        Text(section.label).font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        selectedSection == section
                            ? Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.20)
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedSection == section
                            ? Color(red: 0.95, green: 0.85, blue: 0.50)
                            : Color.white.opacity(0.45)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedSection == section
                                    ? Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.5)
                                    : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Books Section
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quick actions
            quickActionsBar.padding(.horizontal)

            // Built-in guide
            sectionLabel("📖 Guía Integrada").padding(.horizontal)
            NavigationLink(destination: PDFBookView()) {
                builtInBookRow
            }
            .padding(.horizontal)

                // Escuela de Tarot — cursos y talleres
                sectionLabel("🎓 Escuela de Tarot").padding(.horizontal)
                schoolSection.padding(.horizontal)

            // Library
            if libraryManager.importedBooks.isEmpty {
                emptyLibraryView.padding(.horizontal)
            } else {
                sectionLabel("📚 Biblioteca Esotérica — \(libraryManager.importedBooks.count) obras").padding(.horizontal)
                // 2-column book grid
                bookGrid
            }
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }

    private var quickActionsBar: some View {
        HStack(spacing: 10) {
            quickActionButton(icon: "safari.fill", label: "Navegador", color: Color(red: 0.3, green: 0.6, blue: 1.0)) {
                showingBrowser = true
            }
            quickActionButton(icon: "doc.badge.plus", label: "Importar PDF", color: Color(red: 0.85, green: 0.72, blue: 0.38)) {
                showingFilePicker = true
            }
            NavigationLink(destination: SecretVaultView()) {
                VStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 20))
                    Text("Bóveda").font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.42, green: 0.25, blue: 0.65).opacity(0.6), lineWidth: 1))
                .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 1.0))
            }
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.5), lineWidth: 1))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    private var builtInBookRow: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.42, green: 0.28, blue: 0.05),
                                                   Color(red: 0.20, green: 0.12, blue: 0.02)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 72)
                Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.45))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Guía Definitiva del Tarot")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("Fiebig & Bürger · Rider-Waite · Incluida")
                    .font(.caption).foregroundStyle(Color.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.white.opacity(0.3)).font(.caption)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.3), lineWidth: 1))
    }

    private var bookGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
            ForEach(libraryManager.importedBooks) { book in
                NavigationLink(destination: GenericPDFReaderView(url: libraryManager.getFileURL(for: book))) {
                    BookCoverCard(title: book.title, subtitle: book.fileName, size: CGSize(width: 160, height: 220))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        libraryManager.deleteBook(book)
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Escuela de Tarot
    private var schoolSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(schoolCourses, id: \ .self) { course in
                    NavigationLink(destination: SchoolCourseView(title: course)) {
                        BookCoverCard(title: course, subtitle: "Curso · 3 lecciones", size: CGSize(width: 220, height: 140))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var schoolCourses: [String] {
        ["Interpretación de Arcanos", "Tiradas Prácticas", "Cábala y Tarot", "Astrología Aplicada", "Trabajo con la Sombra"]
    }

    private struct SchoolCourseView: View {
        let title: String
        var body: some View {
            VStack(spacing: 16) {
                Text(title).font(.title).bold()
                Text("Contenido del curso — lecciones, videos y ejercicios prácticos.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical").font(.system(size: 48)).foregroundStyle(Color.white.opacity(0.2))
            Text("Biblioteca vacía").font(.headline).foregroundStyle(Color.white.opacity(0.5))
            Text("Importa PDFs o espera a que los libros precargados se carguen automáticamente.")
                .font(.subheadline).foregroundStyle(Color.white.opacity(0.35)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Spreads Info Section
    private var spreadsInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("🔮 Catálogo de Tiradas").padding(.horizontal)

            ForEach(SpreadType.allCases, id: \.rawValue) { spread in
                spreadInfoRow(spread: spread)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private func spreadInfoRow(spread: SpreadType) -> some View {
        let isEsoteric = [SpreadType.temperance, .treeOfLife, .starDavid, .soulMirror, .alchemyPath, .moonCycle].contains(spread)
        return HStack(spacing: 14) {
            Text(spread.symbol)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(isEsoteric ? Color(red: 0.42, green: 0.10, blue: 0.35).opacity(0.4)
                                        : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(spread.label)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    if isEsoteric {
                        Text("ESOTÉRICO").font(.system(size: 9, weight: .black)).foregroundStyle(Color(red: 0.95, green: 0.72, blue: 0.38))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(spread.esotericDescription)
                    .font(.caption).foregroundStyle(Color.white.opacity(0.5)).lineLimit(2)
                Text("\(spread.positions.count) cartas")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.8))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(isEsoteric ? 0.07 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isEsoteric ? Color(red: 0.85, green: 0.60, blue: 0.20).opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Tools Section
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("🛠 Herramientas Arcanas").padding(.horizontal)

            toolRow(icon: "safari.fill", title: "Navegador Arcano", subtitle: "Explora recursos esotéricos en internet",
                    color: Color(red: 0.3, green: 0.6, blue: 1.0)) { showingBrowser = true }
            toolRow(icon: "doc.badge.plus", title: "Importar PDF", subtitle: "Añade libros desde tus archivos",
                    color: Color(red: 0.85, green: 0.72, blue: 0.38)) { showingFilePicker = true }

            NavigationLink(destination: SecretVaultView()) {
                toolRowContent(icon: "lock.shield.fill", title: "Bóveda Secreta",
                               subtitle: "Notas privadas protegidas con PIN y cámara",
                               color: Color(red: 0.72, green: 0.42, blue: 1.0))
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private func toolRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolRowContent(icon: icon, title: title, subtitle: subtitle, color: color)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func toolRowContent(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(Color.white.opacity(0.5)).lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.8))
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

// MARK: - Section Enum
private enum LibrarySection: CaseIterable, Hashable {
    case books, spreads, tools
    var label: String {
        switch self { case .books: return "Libros"; case .spreads: return "Tiradas"; case .tools: return "Herramientas" }
    }
    var icon: String {
        switch self { case .books: return "books.vertical"; case .spreads: return "sparkles"; case .tools: return "wrench.and.screwdriver" }
    }
}

// MARK: - GenericPDFReaderView
public struct GenericPDFReaderView: View {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public var body: some View {
        #if os(iOS)
        GenericIOSPDFView(url: url)
            .navigationTitle(url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "))
            .navigationBarTitleDisplayMode(.inline)
        #else
        Text("Lector PDF disponible en iPhone")
        #endif
    }
}

#if os(iOS)
import PDFKit

private struct GenericIOSPDFView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 1)
        if let doc = PDFDocument(url: url) {
            view.document = doc
        }
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
#endif
