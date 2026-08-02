import Foundation
import Combine

@MainActor
public class LibraryManager: ObservableObject {
    @Published public private(set) var importedBooks: [ImportedBook] = []

    private let userDefaultsKey = "TarotLibrary_ImportedBooks"
    /// Minimum size (in bytes) a PDF must be to be considered a real, non-stub file.
    private let minimumRealPDFSize: Int = 5_000

    public init() {
        loadBooks()
        preloadBundledBooksIfNeeded()
    }

    public func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let libraryFolder = documentsDirectory.appendingPathComponent("TarotLibrary", isDirectory: true)

        if !FileManager.default.fileExists(atPath: libraryFolder.path) {
            try? FileManager.default.createDirectory(at: libraryFolder, withIntermediateDirectories: true, attributes: nil)
        }

        return libraryFolder
    }

    public func importPDF(from url: URL) throws {
        // Access security scoped resource if coming from document picker
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let libraryFolder = getDocumentsDirectory()
        let fileName = url.lastPathComponent
        let destinationURL = libraryFolder.appendingPathComponent(fileName)

        // If file already exists, check if it's a valid (non-stub) size.
        // If it's too small, remove it and re-copy the real version from bundle.
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
            if existingSize >= minimumRealPDFSize {
                // File is already good, just ensure record exists
                if !importedBooks.contains(where: { $0.fileName == fileName }) {
                    addBookRecord(title: titleFromFileName(url.lastPathComponent), fileName: fileName)
                }
                return
            }
            // Stub file found – delete and re-copy
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: url, to: destinationURL)

        // Remove stale record if present (from stub era)
        importedBooks.removeAll { $0.fileName == fileName }
        addBookRecord(title: titleFromFileName(url.lastPathComponent), fileName: fileName)
    }

    private func titleFromFileName(_ fileName: String) -> String {
        return (fileName as NSString)
            .deletingPathExtension
            .replacingOccurrences(of: "_", with: " ")
    }

    private func addBookRecord(title: String, fileName: String) {
        let newBook = ImportedBook(title: title, fileName: fileName)
        importedBooks.append(newBook)
        saveBooks()
    }

    public func deleteBook(_ book: ImportedBook) {
        importedBooks.removeAll { $0.id == book.id }
        let libraryFolder = getDocumentsDirectory()
        let fileURL = libraryFolder.appendingPathComponent(book.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        saveBooks()
    }

    public func getFileURL(for book: ImportedBook) -> URL {
        let documentsURL = getDocumentsDirectory().appendingPathComponent(book.fileName)
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            return documentsURL
        }

        // If not found in Documents, attempt to locate the PDF directly inside available bundles
        for b in availableSearchBundles() {
            let resourceName = (book.fileName as NSString).deletingPathExtension
            if let url = b.url(forResource: resourceName, withExtension: "pdf") {
                return url
            }
            if let url = b.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Books") {
                return url
            }
            if let url = b.url(forResource: resourceName, withExtension: "pdf", subdirectory: "Resources/Books") {
                return url
            }
        }

        return documentsURL
    }

    private func loadBooks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let books = try? JSONDecoder().decode([ImportedBook].self, from: data) {
            self.importedBooks = books
        }
    }

    private func saveBooks() {
        if let data = try? JSONEncoder().encode(importedBooks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - Preload Bundled Books

    private func preloadBundledBooksIfNeeded() {
        let preloadedBookNames = [
            "La_Clave_Ilustrada_del_Tarot",
            "Guia_Tiradas_Avanzadas",
            "Tarot_de_los_Bohemios_Papus",
            "Libro_de_Thoth_y_Alquimia",
            "Astrologia_y_Decanatos_Zodiacales",
            "Simbologia_Arcanos_Menores",
            "Arbol_de_la_Vida_y_Cabala",
            "Manual_Tiradas_de_Amor",
            "Tarot_e_Intuicion_Psiquica"
        ]

        let searchBundles = availableSearchBundles()

        for name in preloadedBookNames {
            let fileName = "\(name).pdf"
            let destinationURL = getDocumentsDirectory().appendingPathComponent(fileName)

            // Check if destination already exists AND is a real (non-stub) file
            var destinationExistsAndGood = false
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
                if existingSize >= minimumRealPDFSize {
                    // Tentatively good — but we may still want to replace if bundle has a larger, richer file
                    destinationExistsAndGood = true
                } else {
                    // Stub file – remove so we can decide to copy a better bundle version
                    try? FileManager.default.removeItem(at: destinationURL)
                    importedBooks.removeAll { $0.fileName == fileName }
                }
            }

            // Find the PDF in any available bundle
            var foundURL: URL?
            for b in searchBundles {
                if let url = b.url(forResource: name, withExtension: "pdf") {
                    foundURL = url; break
                }
                if let url = b.url(forResource: name, withExtension: "pdf", subdirectory: "Books") {
                    foundURL = url; break
                }
                if let url = b.url(forResource: name, withExtension: "pdf", subdirectory: "Resources/Books") {
                    foundURL = url; break
                }
            }

            if let sourceURL = foundURL {
                // Verify source is real (not a stub)
                let sourceSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? Int) ?? 0
                if sourceSize >= minimumRealPDFSize {
                    // If Documents contains a smaller file than the bundle, prefer replacing it.
                    if destinationExistsAndGood {
                        let existingSize = (try? FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as? Int) ?? 0
                        if existingSize < sourceSize {
                            try? FileManager.default.removeItem(at: destinationURL)
                            // Copy the richer bundle PDF to Documents so user can annotate/copy
                            try? FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        }
                        // Ensure record exists
                        if !importedBooks.contains(where: { $0.fileName == fileName }) {
                            addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                        }
                    } else {
                        // Prefer to keep preloaded books in the bundle and reference them directly
                        if !importedBooks.contains(where: { $0.fileName == fileName }) {
                            addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                        }
                    }
                } else {
                    // Source is also a stub — add as bundle-reference record so it appears in UI
                    if !importedBooks.contains(where: { $0.fileName == fileName }) {
                        addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                    }
                }
            } else {
                // Book not found in bundle — add record anyway so UI shows it (opens stub)
                if !importedBooks.contains(where: { $0.fileName == fileName }) {
                    addBookRecord(title: titleFromFileName(fileName), fileName: fileName)
                }
            }
        }
    }

    private func availableSearchBundles() -> [Bundle] {
        var bundles: [Bundle] = [Bundle.main, Bundle(for: LibraryManager.self)]
        let tarotContentBundle = Bundle(identifier: "com.tarot.TarotContent")
            ?? Bundle(path: Bundle.main.bundlePath + "/TarotContent.bundle")
        if let tcb = tarotContentBundle, !bundles.contains(where: { $0.bundleURL == tcb.bundleURL }) {
            bundles.append(tcb)
        }
        return bundles
    }
}
