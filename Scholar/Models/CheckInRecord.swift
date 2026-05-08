import Foundation

struct CheckInRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var type: CheckInType
    var leaveType: LeaveType?
    var startTime: Date?
    var endTime: Date?
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: CheckInType,
        leaveType: LeaveType? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.leaveType = leaveType
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
    }

    var isOngoing: Bool {
        return type == .work && startTime != nil && endTime == nil
    }

    var formattedDuration: String {
        duration.formattedAsDuration
    }

    enum CodingKeys: String, CodingKey {
        case id, date, type, leaveType, startTime, endTime, duration
    }
}
