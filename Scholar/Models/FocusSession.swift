import Foundation

struct FocusSession: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var taskTitle: String
    var theme: String
    var notes: String
    var isManual: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        taskTitle: String = "",
        theme: String = "",
        notes: String = "",
        isManual: Bool = false
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.taskTitle = taskTitle
        self.theme = theme
        self.notes = notes
        self.isManual = isManual
    }

    var formattedDuration: String {
        duration.formattedAsDuration
    }
}
