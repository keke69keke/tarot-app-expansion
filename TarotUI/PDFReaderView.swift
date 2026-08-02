import SwiftUI
import PDFKit
import TarotContent

// MARK: - PDF Reader Tab View

public struct PDFBookView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            PDFReaderContainerView()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 1) {
                            Text("Guía Definitiva")
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .foregroundStyle(.primary)
                            Text("Fiebig & Bürger · Rider-Waite")
                                .font(.system(size: 11, weight: .regular, design: .serif))
                                .foregroundStyle(Color.tarotGold)
                        }
                    }
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        }
    }
}

// MARK: - Container (platform-aware)

private struct PDFReaderContainerView: View {
    private var pdfURL: URL? {
        Bundle.tarotContent.url(forResource: "rider_waite_guide", withExtension: "pdf")
    }

    var body: some View {
        if let url = pdfURL {
            #if os(iOS)
            IOSPDFReaderView(url: url)
            #else
            MacPDFPlaceholderView(url: url)
            #endif
        } else {
            unavailableView
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(Color.tarotGold.opacity(0.55))
            Text("Libro no disponible")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
            Text("El archivo del libro no se encontró en el paquete de la app.")
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - macOS placeholder

#if !os(iOS)
private struct MacPDFPlaceholderView: View {
    let url: URL
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.tarotGold)
            Text("Lector disponible en iPhone / iPad")
                .font(.system(size: 16, weight: .semibold, design: .serif))
            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif

// MARK: - iOS PDF Reader

#if os(iOS)
private struct IOSPDFReaderView: View {
    let url: URL
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 1
    @State private var pdfViewRef: PDFView? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // PDF View fills the screen
            PDFKitRepresentable(url: url,
                                currentPage: $currentPage,
                                totalPages: $totalPages,
                                pdfViewRef: $pdfViewRef)
                .ignoresSafeArea(edges: .bottom)

            // Bottom navigation chrome
            HStack(spacing: 0) {
                Button { goTo(currentPage - 1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(currentPage <= 1 ? Color.secondary.opacity(0.35) : Color.tarotGold)
                        .frame(width: 52, height: 52)
                        .contentShape(Rectangle())
                }
                .disabled(currentPage <= 1)

                Spacer()

                VStack(spacing: 2) {
                    Text("Página \(currentPage)")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(.primary)
                    Text("de \(totalPages)")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button { goTo(currentPage + 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(currentPage >= totalPages ? Color.secondary.opacity(0.35) : Color.tarotGold)
                        .frame(width: 52, height: 52)
                        .contentShape(Rectangle())
                }
                .disabled(currentPage >= totalPages)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().fill(Color.tarotGold.opacity(0.20)).frame(height: 0.5), alignment: .top)
        }
    }

    private func goTo(_ page: Int) {
        guard let view = pdfViewRef, let doc = view.document else { return }
        let idx = max(0, min(page - 1, doc.pageCount - 1))
        if let p = doc.page(at: idx) { view.go(to: p) }
    }
}

// MARK: - UIViewRepresentable wrapper

private struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    @Binding var pdfViewRef: PDFView?

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage, totalPages: $totalPages)
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor.systemBackground

        if let doc = PDFDocument(url: url) {
            view.document = doc
            DispatchQueue.main.async {
                totalPages = doc.pageCount
                pdfViewRef = view
            }
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    final class Coordinator: NSObject {
        @Binding var currentPage: Int
        @Binding var totalPages: Int
        init(currentPage: Binding<Int>, totalPages: Binding<Int>) {
            _currentPage = currentPage
            _totalPages = totalPages
        }
        @objc func pageChanged(_ notification: Notification) {
            guard let view = notification.object as? PDFView,
                  let doc = view.document,
                  let page = view.currentPage else { return }
            let idx = doc.index(for: page)
            DispatchQueue.main.async {
                self.currentPage = idx + 1
                self.totalPages = doc.pageCount
            }
        }
    }
}
#endif
