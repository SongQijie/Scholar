import Foundation

struct FileAttachment: Codable, Identifiable, Hashable {
    var id: UUID
    var originalFileName: String
    var storedFileName: String
    var relativePath: String
    var fileExtension: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        originalFileName: String,
        storedFileName: String,
        relativePath: String,
        fileExtension: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.relativePath = relativePath
        self.fileExtension = fileExtension
        self.createdAt = createdAt
    }
}
