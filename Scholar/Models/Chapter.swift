import Foundation

struct Chapter: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var progress: Int
    var status: ChapterStatus
    var order: Int

    init(id: UUID = UUID(), name: String = "", progress: Int = 0, status: ChapterStatus = .draft, order: Int = 0) {
        self.id = id; self.name = name; self.progress = progress; self.status = status; self.order = order
    }
}
