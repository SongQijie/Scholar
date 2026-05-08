import Foundation

struct Milestone: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var isCompleted: Bool
    var deadline: Date?
    var order: Int

    init(id: UUID = UUID(), name: String = "", isCompleted: Bool = false, deadline: Date? = nil, order: Int = 0) {
        self.id = id; self.name = name; self.isCompleted = isCompleted; self.deadline = deadline; self.order = order
    }
}
