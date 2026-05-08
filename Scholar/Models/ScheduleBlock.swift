import Foundation

struct ScheduleBlock: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var taskTitle: String
    var colorHex: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date = Date(),
        taskTitle: String = "",
        colorHex: String = "8B5CF6"
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.taskTitle = taskTitle
        self.colorHex = colorHex
    }
}
