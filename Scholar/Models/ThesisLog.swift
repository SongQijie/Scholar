import Foundation

struct ThesisLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var activityType: String
    var durationMinutes: Int
    var wordCount: Int
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), activityType: String = "", durationMinutes: Int = 0, wordCount: Int = 0, notes: String = "") {
        self.id = id; self.date = date; self.activityType = activityType; self.durationMinutes = durationMinutes; self.wordCount = wordCount; self.notes = notes
    }
}
