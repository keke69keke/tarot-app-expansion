import Foundation

public struct ImportedBook: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let fileName: String
    public let dateAdded: Date
    public var lastReadPage: Int
    public var totalPages: Int?
    
    public init(id: UUID = UUID(), title: String, fileName: String, dateAdded: Date = Date(), lastReadPage: Int = 1, totalPages: Int? = nil) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.dateAdded = dateAdded
        self.lastReadPage = lastReadPage
        self.totalPages = totalPages
    }
}
