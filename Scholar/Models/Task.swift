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
    var blockedReason: String
    var waitingFor: String
    var prerequisiteTaskId: UUID?
    var blockedSince: Date?
    var postponementLogs: [TaskPostponementLog]
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
        blockedReason: String = "",
        waitingFor: String = "",
        prerequisiteTaskId: UUID? = nil,
        blockedSince: Date? = nil,
        postponementLogs: [TaskPostponementLog] = [],
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
        self.blockedReason = blockedReason
        self.waitingFor = waitingFor
        self.prerequisiteTaskId = prerequisiteTaskId
        self.blockedSince = blockedSince ?? ((!blockedReason.isEmpty || !waitingFor.isEmpty) ? Date() : nil)
        self.postponementLogs = postponementLogs
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

    var isBlocked: Bool {
        !blockedReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !waitingFor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isBlockedOverSevenDays: Bool {
        guard status != .completed, isBlocked, let blockedSince else { return false }
        let threshold = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return blockedSince <= threshold
    }

    mutating func updateDependencyState(blockedReason: String, waitingFor: String, prerequisiteTaskId: UUID?) {
        let wasBlocked = isBlocked
        self.blockedReason = blockedReason.trimmingCharacters(in: .whitespacesAndNewlines)
        self.waitingFor = waitingFor.trimmingCharacters(in: .whitespacesAndNewlines)
        self.prerequisiteTaskId = prerequisiteTaskId
        if isBlocked {
            if !wasBlocked || blockedSince == nil {
                blockedSince = Date()
            }
        } else {
            blockedSince = nil
        }
    }

    mutating func postpone(by duration: TaskPostponementDuration, reason: String, waitingFor: String) {
        let previousDueDate = dueDate
        let baseDate = previousDueDate ?? Date()
        let newDueDate = Calendar.current.date(byAdding: .day, value: duration.days, to: baseDate) ?? baseDate
        dueDate = newDueDate
        postponementLogs.append(
            TaskPostponementLog(
                days: duration.days,
                previousDueDate: previousDueDate,
                newDueDate: newDueDate,
                blockedReason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
                waitingFor: waitingFor.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, title, details, collaborator, projectId, thesisId, affairId, priority, status, dueDate, startDate, recurrence, completionRate, isToday
        case blockedReason, waitingFor, prerequisiteTaskId, blockedSince, postponementLogs, createdAt, updatedAt
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
        blockedReason = try container.decodeIfPresent(String.self, forKey: .blockedReason) ?? ""
        waitingFor = try container.decodeIfPresent(String.self, forKey: .waitingFor) ?? ""
        prerequisiteTaskId = try container.decodeIfPresent(UUID.self, forKey: .prerequisiteTaskId)
        blockedSince = try container.decodeIfPresent(Date.self, forKey: .blockedSince)
        postponementLogs = try container.decodeIfPresent([TaskPostponementLog].self, forKey: .postponementLogs) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

enum TaskPostponementDuration: Int, Codable, CaseIterable, Identifiable {
    case oneDay = 1
    case twoDays = 2
    case threeDays = 3
    case oneWeek = 7

    var id: Int { rawValue }
    var days: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneDay: return AppLanguage.storedPreference.text("延期 1 天", "Postpone 1 Day")
        case .twoDays: return AppLanguage.storedPreference.text("延期 2 天", "Postpone 2 Days")
        case .threeDays: return AppLanguage.storedPreference.text("延期 3 天", "Postpone 3 Days")
        case .oneWeek: return AppLanguage.storedPreference.text("延期 1 周", "Postpone 1 Week")
        }
    }
}

struct TaskPostponementLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var days: Int
    var previousDueDate: Date?
    var newDueDate: Date
    var blockedReason: String
    var waitingFor: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        days: Int,
        previousDueDate: Date?,
        newDueDate: Date,
        blockedReason: String,
        waitingFor: String
    ) {
        self.id = id
        self.date = date
        self.days = days
        self.previousDueDate = previousDueDate
        self.newDueDate = newDueDate
        self.blockedReason = blockedReason
        self.waitingFor = waitingFor
    }
}
