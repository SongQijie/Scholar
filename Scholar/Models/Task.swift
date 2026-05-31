import Foundation

struct Task: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var details: String
    var collaborator: String
    var projectId: UUID?
    var thesisId: UUID? // 关联课题
    var affairId: UUID? // 关联事务
    var priority: TaskPriority
    var status: TaskStatus
    var dueDate: Date?
    var startDate: Date?
    var recurrence: TaskRecurrence
    var completionRate: Int
    var isToday: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        details: String = "",
        collaborator: String = "本人",
        projectId: UUID? = nil,
        thesisId: UUID? = nil,
        affairId: UUID? = nil,
        priority: TaskPriority = .important,
        status: TaskStatus = .notStarted,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        recurrence: TaskRecurrence = .none,
        completionRate: Int = 0,
        isToday: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.collaborator = collaborator
        self.projectId = projectId
        self.thesisId = thesisId
        self.affairId = affairId
        self.priority = priority
        self.status = status
        self.dueDate = dueDate
        self.startDate = startDate
        self.recurrence = recurrence
        self.completionRate = completionRate
        self.isToday = isToday
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && status != .completed
    }

    var isDueWithin7Days: Bool {
        guard let due = dueDate else { return false }
        let sevenDays = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return due <= sevenDays && due >= Date()
    }

    var ownerLabel: String {
        if projectId != nil { return "项目任务" }
        if thesisId != nil { return "课题任务" }
        if affairId != nil { return "事务任务" }
        return "未归类任务"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, details, collaborator, projectId, thesisId, affairId, priority, status, dueDate, startDate, recurrence, completionRate, isToday, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        collaborator = try container.decodeIfPresent(String.self, forKey: .collaborator) ?? "本人"
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        thesisId = try container.decodeIfPresent(UUID.self, forKey: .thesisId)
        affairId = try container.decodeIfPresent(UUID.self, forKey: .affairId)
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .important
        status = try container.decodeIfPresent(TaskStatus.self, forKey: .status) ?? .notStarted
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        recurrence = try container.decodeIfPresent(TaskRecurrence.self, forKey: .recurrence) ?? .none
        completionRate = try container.decodeIfPresent(Int.self, forKey: .completionRate) ?? 0
        isToday = try container.decodeIfPresent(Bool.self, forKey: .isToday) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
