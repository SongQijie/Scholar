import Foundation

struct SubmissionLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var content: String

    init(id: UUID = UUID(), date: Date = Date(), content: String = "") {
        self.id = id; self.date = date; self.content = content
    }
}
