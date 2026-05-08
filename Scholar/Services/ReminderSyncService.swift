import EventKit
import Foundation

final class ReminderSyncService {
    static let shared = ReminderSyncService()

    private let eventStore = EKEventStore()
    private let markerPrefix = "ScholarTaskID:"
    private let legacyMarkerPrefix = "PhDMasterWorkspaceTaskID:"

    private init() {}

    struct ReminderListOption: Identifiable, Hashable {
        var id: String
        var title: String
    }

    enum OwnerKind {
        case project
        case thesis

        var label: String {
            switch self {
            case .project: return "项目"
            case .thesis: return "课题"
            }
        }
    }

    struct SyncResult {
        var createdLocal: Int = 0
        var updatedLocal: Int = 0
        var pushedToReminders: Int = 0
        var removedLocal: Int = 0
    }

    enum SyncError: LocalizedError {
        case accessDenied
        case calendarUnavailable

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "没有获得提醒事项访问权限。请在系统设置中允许 Workspace 访问提醒事项。"
            case .calendarUnavailable:
                return "无法找到选中的提醒事项列表。"
            }
        }
    }

    func reminderLists() async throws -> [ReminderListOption] {
        try await ensureAccess()
        return eventStore.calendars(for: .reminder)
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            .map { ReminderListOption(id: $0.calendarIdentifier, title: $0.title) }
    }

    func syncTasks(
        ownerId: UUID,
        ownerKind: OwnerKind,
        ownerTitle: String,
        calendarIdentifier: String,
        tasks: inout [Task]
    ) async throws -> SyncResult {
        try await ensureAccess()
        guard let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw SyncError.calendarUnavailable
        }

        let reminders = try await fetchReminders(in: [calendar])
        let remindersByIdentifier = Dictionary(uniqueKeysWithValues: reminders.map { ($0.calendarItemIdentifier, $0) })
        var result = SyncResult()

        for reminder in reminders {
            if let index = tasks.firstIndex(where: { $0.reminderIdentifier == reminder.calendarItemIdentifier })
                ?? legacyTaskIndex(for: reminder, in: tasks) {
                if shouldReminderWin(reminder, over: tasks[index]) {
                    tasks[index].apply(reminder: reminder, ownerId: ownerId, ownerKind: ownerKind)
                    result.updatedLocal += 1
                } else {
                    try saveReminder(from: tasks[index], ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId, calendar: calendar, existing: reminder)
                    result.pushedToReminders += 1
                }
            } else {
                let imported = Task(reminder: reminder, ownerId: ownerId, ownerKind: ownerKind)
                tasks.append(imported)
                try saveReminder(from: imported, ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId, calendar: calendar, existing: reminder)
                result.createdLocal += 1
            }
        }

        for index in tasks.indices {
            guard tasks[index].belongs(to: ownerId, ownerKind: ownerKind) else { continue }
            if let identifier = tasks[index].reminderIdentifier,
               let reminder = remindersByIdentifier[identifier] {
                if !shouldReminderWin(reminder, over: tasks[index]) {
                    try saveReminder(from: tasks[index], ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId, calendar: calendar, existing: reminder)
                    result.pushedToReminders += 1
                }
            } else if tasks[index].reminderIdentifier == nil {
                let reminder = try saveReminder(from: tasks[index], ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId, calendar: calendar, existing: nil)
                tasks[index].reminderIdentifier = reminder.calendarItemIdentifier
                result.pushedToReminders += 1
            }
        }

        let fetchedIdentifiers = Set(reminders.map(\.calendarItemIdentifier))
        let beforeDelete = tasks.count
        tasks.removeAll { task in
            task.belongs(to: ownerId, ownerKind: ownerKind)
                && task.reminderIdentifier != nil
                && !fetchedIdentifiers.contains(task.reminderIdentifier ?? "")
        }
        result.removedLocal = beforeDelete - tasks.count

        return result
    }

    func upsertTask(
        _ task: Task,
        ownerKind: OwnerKind,
        ownerTitle: String,
        ownerId: UUID,
        calendarIdentifier: String
    ) async throws -> String {
        try await ensureAccess()
        guard let calendar = eventStore.calendar(withIdentifier: calendarIdentifier) else {
            throw SyncError.calendarUnavailable
        }
        let existing = existingReminder(for: task, in: calendar)
        let reminder = try saveReminder(from: task, ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId, calendar: calendar, existing: existing)
        return reminder.calendarItemIdentifier
    }

    func deleteReminder(for task: Task) async throws {
        try await ensureAccess()
        guard let identifier = task.reminderIdentifier,
              let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return
        }
        try eventStore.remove(reminder, commit: true)
    }

    private func ensureAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .reminder)

        switch status {
        case .authorized, .fullAccess:
            return
        case .notDetermined:
            let granted = try await requestReminderAccess()
            if !granted {
                throw SyncError.accessDenied
            }
        case .denied, .restricted, .writeOnly:
            throw SyncError.accessDenied
        @unknown default:
            throw SyncError.accessDenied
        }
    }

    private func requestReminderAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToReminders { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    private func fetchReminders(in calendars: [EKCalendar]) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = eventStore.predicateForReminders(in: calendars)
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func existingReminder(for task: Task, in calendar: EKCalendar) -> EKReminder? {
        if let identifier = task.reminderIdentifier,
           let reminder = eventStore.calendarItem(withIdentifier: identifier) as? EKReminder {
            return reminder
        }

        let semaphore = DispatchSemaphore(value: 0)
        let predicate = eventStore.predicateForReminders(in: [calendar])
        var matched: EKReminder?
        eventStore.fetchReminders(matching: predicate) { reminders in
            matched = reminders?.first { reminder in
                self.legacyTaskId(from: reminder) == task.id
            }
            semaphore.signal()
        }
        semaphore.wait()
        return matched
    }

    @discardableResult
    private func saveReminder(
        from task: Task,
        ownerKind: OwnerKind,
        ownerTitle: String,
        ownerId: UUID,
        calendar: EKCalendar,
        existing: EKReminder?
    ) throws -> EKReminder {
        let reminder = existing ?? EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = task.title
        reminder.notes = notes(for: task, ownerKind: ownerKind, ownerTitle: ownerTitle, ownerId: ownerId)
        reminder.priority = reminderPriority(for: task.priority)
        reminder.isCompleted = task.status == .completed
        reminder.completionDate = task.status == .completed ? (reminder.completionDate ?? Date()) : nil
        reminder.dueDateComponents = task.dueDate.map { Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0) }
        reminder.startDateComponents = task.startDate.map { Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0) }
        reminder.recurrenceRules = recurrenceRules(for: task.recurrence)
        try eventStore.save(reminder, commit: true)
        return reminder
    }

    private func notes(for task: Task, ownerKind: OwnerKind, ownerTitle: String, ownerId: UUID) -> String {
        [
            "Scholar \(ownerKind.label)：\(ownerTitle)",
            "优先级：\(task.priority.displayName)",
            "状态：\(task.status.displayName)",
            "今日推进：\(task.isToday ? "是" : "否")"
        ].joined(separator: "\n")
    }

    private func legacyTaskIndex(for reminder: EKReminder, in tasks: [Task]) -> Int? {
        guard let taskId = legacyTaskId(from: reminder) else { return nil }
        return tasks.firstIndex { $0.id == taskId }
    }

    private func legacyTaskId(from reminder: EKReminder) -> UUID? {
        guard let notes = reminder.notes else { return nil }
        guard let range = notes.range(of: markerPrefix) ?? notes.range(of: legacyMarkerPrefix) else { return nil }
        let raw = notes[range.upperBound...]
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        return UUID(uuidString: raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func shouldReminderWin(_ reminder: EKReminder, over task: Task) -> Bool {
        guard let modified = reminder.lastModifiedDate else {
            return false
        }
        return modified > task.updatedAt
    }

    private func reminderPriority(for priority: TaskPriority) -> Int {
        switch priority {
        case .urgentImportant: return 1
        case .urgent, .important: return 5
        case .low: return 9
        }
    }

    private func taskPriority(for reminderPriority: Int) -> TaskPriority {
        switch reminderPriority {
        case 1...3: return .urgentImportant
        case 4...6: return .important
        case 7...9: return .low
        default: return .important
        }
    }

    private func recurrence(from rules: [EKRecurrenceRule]?) -> TaskRecurrence {
        guard let frequency = rules?.first?.frequency else { return .none }
        switch frequency {
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .monthly
        @unknown default: return .none
        }
    }

    private func recurrenceRules(for recurrence: TaskRecurrence) -> [EKRecurrenceRule]? {
        let frequency: EKRecurrenceFrequency
        switch recurrence {
        case .none: return nil
        case .daily: frequency = .daily
        case .weekly: frequency = .weekly
        case .monthly: frequency = .monthly
        }
        return [EKRecurrenceRule(recurrenceWith: frequency, interval: 1, end: nil)]
    }
}

private extension Task {
    init(reminder: EKReminder, ownerId: UUID, ownerKind: ReminderSyncService.OwnerKind) {
        self.init(
            title: reminder.title ?? "",
            projectId: ownerKind == .project ? ownerId : nil,
            thesisId: ownerKind == .thesis ? ownerId : nil,
            priority: ReminderSyncService.shared.priority(from: reminder.priority),
            status: reminder.isCompleted ? .completed : .notStarted,
            dueDate: reminder.dueDateComponents?.date,
            startDate: reminder.startDateComponents?.date,
            recurrence: ReminderSyncService.shared.recurrenceValue(from: reminder.recurrenceRules),
            completionRate: reminder.isCompleted ? 100 : 0,
            isToday: reminder.dueDateComponents?.date.map { Calendar.current.isDateInToday($0) } ?? false,
            reminderIdentifier: reminder.calendarItemIdentifier,
            createdAt: reminder.creationDate ?? Date(),
            updatedAt: reminder.lastModifiedDate ?? Date()
        )
    }

    mutating func apply(reminder: EKReminder, ownerId: UUID, ownerKind: ReminderSyncService.OwnerKind) {
        title = reminder.title ?? title
        projectId = ownerKind == .project ? ownerId : nil
        thesisId = ownerKind == .thesis ? ownerId : nil
        priority = ReminderSyncService.shared.priority(from: reminder.priority)
        status = reminder.isCompleted ? .completed : .notStarted
        dueDate = reminder.dueDateComponents?.date
        startDate = reminder.startDateComponents?.date
        recurrence = ReminderSyncService.shared.recurrenceValue(from: reminder.recurrenceRules)
        completionRate = reminder.isCompleted ? 100 : 0
        isToday = dueDate.map { Calendar.current.isDateInToday($0) } ?? false
        reminderIdentifier = reminder.calendarItemIdentifier
        updatedAt = reminder.lastModifiedDate ?? Date()
    }

    func belongs(to ownerId: UUID, ownerKind: ReminderSyncService.OwnerKind) -> Bool {
        switch ownerKind {
        case .project:
            return projectId == ownerId && thesisId == nil
        case .thesis:
            return thesisId == ownerId && projectId == nil
        }
    }
}

private extension ReminderSyncService {
    func priority(from reminderPriority: Int) -> TaskPriority {
        taskPriority(for: reminderPriority)
    }

    func recurrenceValue(from rules: [EKRecurrenceRule]?) -> TaskRecurrence {
        recurrence(from: rules)
    }
}
