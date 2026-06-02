import Foundation

struct WorkspaceTimelineLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var title: String
    var details: String

    init(id: UUID = UUID(), date: Date = Date(), title: String = "", details: String = "") {
        self.id = id
        self.date = date
        self.title = title
        self.details = details
    }
}
