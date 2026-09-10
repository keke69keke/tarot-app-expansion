import Foundation
import Combine

public struct SecretVaultEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var imageFileName: String
    public let dateAdded: Date
    
    public init(id: UUID = UUID(), title: String, notes: String = "", imageFileName: String, dateAdded: Date = Date()) {
        self.id = id
        self.title = title
        self.notes = notes
        self.imageFileName = imageFileName
        self.dateAdded = dateAdded
    }
}

@MainActor
public class SecretVaultManager: ObservableObject {
    @Published public private(set) var entries: [SecretVaultEntry] = []
    @Published public private(set) var isUnlocked: Bool = false
    
    private let pinDefaultsKey = "TarotSecretVault_PIN"
    private let entriesDefaultsKey = "TarotSecretVault_Entries"
    
    public init() {
        loadEntries()
    }
    
    public var hasPINSet: Bool {
        UserDefaults.standard.string(forKey: pinDefaultsKey) != nil
    }
    
    public func setPIN(_ pin: String) {
        UserDefaults.standard.set(pin, forKey: pinDefaultsKey)
        isUnlocked = true
    }
    
    public func unlock(with pin: String) -> Bool {
        guard let savedPIN = UserDefaults.standard.string(forKey: pinDefaultsKey) else {
            // First time setup
            setPIN(pin)
            return true
        }
        
        if savedPIN == pin {
            isUnlocked = true
            return true
        }
        return false
    }
    
    public func lock() {
        isUnlocked = false
    }
    
    public func getVaultDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let vaultFolder = paths[0].appendingPathComponent(".SecretTarotVault", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: vaultFolder.path) {
            try? FileManager.default.createDirectory(at: vaultFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return vaultFolder
    }
    
    public func savePhoto(data: Data, title: String, notes: String) -> SecretVaultEntry? {
        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = getVaultDirectory().appendingPathComponent(fileName)
        
        do {
            try data.write(to: destinationURL)
            let entry = SecretVaultEntry(title: title.isEmpty ? "Lectura Fásica \(Date().formatted(date: .numeric, time: .shortened))" : title, notes: notes, imageFileName: fileName)
            entries.insert(entry, at: 0)
            saveEntries()
            return entry
        } catch {
            print("Error saving vault photo: \(error)")
            return nil
        }
    }
    
    public func deleteEntry(_ entry: SecretVaultEntry) {
        entries.removeAll { $0.id == entry.id }
        let fileURL = getVaultDirectory().appendingPathComponent(entry.imageFileName)
        try? FileManager.default.removeItem(at: fileURL)
        saveEntries()
    }
    
    public func getImageURL(for entry: SecretVaultEntry) -> URL {
        return getVaultDirectory().appendingPathComponent(entry.imageFileName)
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesDefaultsKey),
           let decoded = try? JSONDecoder().decode([SecretVaultEntry].self, from: data) {
            self.entries = decoded
        }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesDefaultsKey)
        }
    }
}
