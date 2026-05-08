import Foundation
import Combine

class ThesisManagementViewModel: ObservableObject {
    @Published var theses: [ThesisInfo] = []
    @Published var tasks: [Task] = []
    @Published var selectedThesisFilter: UUID? = nil
    @Published var showCompletedTasks: Bool = true
    @Published var isReminderSyncing: Bool = false
    @Published var reminderSyncMessage: String = ""
    @Published var reminderLists: [ReminderSyncService.ReminderListOption] = []

    @Published var thesisFormTitle: String = ""
    @Published var thesisFormStage: ThesisStage = .literatureReview
    @Published var thesisFormSharedDocumentLink: String = ""
    @Published var thesisFormNotes: String = ""
    @Published var thesisFormStudents: String = ""
    @Published var thesisFormReminderCalendarIdentifier: String? = nil
    @Published var showThesisForm: Bool = false
    @Published var editingThesisId: UUID? = nil

    @Published var taskFormTitle: String = ""
    @Published var taskFormThesisId: UUID? = nil
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormRecurrence: TaskRecurrence = .none
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil

    @Published var taskStatusFilter: TaskStatus? = nil

    private var store: AppDataStore { AppDataStore.shared }
    private var didRunInitialReminderSync = false

    func loadData() {
        theses = store.thesisInfos.sorted {
            if $0.title != $1.title {
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
            return $0.id.uuidString < $1.id.uuidString
        }
        loadTasks()
        loadReminderListsIfNeeded()
        syncBoundThesesOnceIfNeeded()
    }

    func loadTasks() {
        var all = store.tasks.filter { $0.thesisId != nil && $0.projectId == nil }
        if let filter = selectedThesisFilter {
            all = all.filter { $0.thesisId == filter }
        }
        tasks = all.sorted { a, b in
            if a.status.rawValue != b.status.rawValue { return a.status.rawValue < b.status.rawValue }
            if a.dueDate != b.dueDate { return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
            return a.priority.rawValue < b.priority.rawValue
        }
    }

    func beginCreatingThesis() {
        resetThesisForm()
        showThesisForm = true
    }

    func beginEditingThesis(_ thesis: ThesisInfo) {
        editingThesisId = thesis.id
        thesisFormTitle = thesis.title
        thesisFormStage = thesis.stage
        thesisFormSharedDocumentLink = thesis.sharedDocumentLink
        thesisFormNotes = thesis.notes
        thesisFormStudents = thesis.students.map(\.name).joined(separator: ", ")
        thesisFormReminderCalendarIdentifier = thesis.reminderCalendarIdentifier
        showThesisForm = true
    }

    func saveThesis() {
        guard thesisFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let students = thesisFormStudents.normalizedLines.map { Student(name: $0, role: "参与学生") }
        var savedThesisId: UUID?

        if let editingThesisId, let index = store.thesisInfos.firstIndex(where: { $0.id == editingThesisId }) {
            store.thesisInfos[index].title = thesisFormTitle
            store.thesisInfos[index].stage = thesisFormStage
            store.thesisInfos[index].sharedDocumentLink = thesisFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            store.thesisInfos[index].notes = thesisFormNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            store.thesisInfos[index].students = students
            store.thesisInfos[index].reminderCalendarIdentifier = thesisFormReminderCalendarIdentifier
            savedThesisId = store.thesisInfos[index].id
        } else {
            let thesis = ThesisInfo(
                title: thesisFormTitle,
                stage: thesisFormStage,
                notes: thesisFormNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                sharedDocumentLink: thesisFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                reminderCalendarIdentifier: thesisFormReminderCalendarIdentifier,
                students: students
            )
            store.thesisInfos.append(thesis)
            savedThesisId = thesis.id
        }

        store.save()
        resetThesisForm()
        loadData()
        if let savedThesisId,
           let thesis = store.thesisInfos.first(where: { $0.id == savedThesisId }),
           thesis.reminderCalendarIdentifier != nil {
            syncThesisToReminders(thesis)
        }
    }

    func deleteThesis(_ thesis: ThesisInfo) {
        store.thesisInfos.removeAll { $0.id == thesis.id }
        store.tasks.removeAll { $0.thesisId == thesis.id && $0.projectId == nil }
        store.save()
        loadData()
    }

    func resetThesisForm() {
        thesisFormTitle = ""
        thesisFormStage = .literatureReview
        thesisFormSharedDocumentLink = ""
        thesisFormNotes = ""
        thesisFormStudents = ""
        thesisFormReminderCalendarIdentifier = nil
        editingThesisId = nil
        showThesisForm = false
    }

    func beginCreatingTask(prefilledThesisId: UUID? = nil) {
        resetTaskForm()
        taskFormThesisId = prefilledThesisId ?? selectedThesisFilter ?? theses.first?.id
        showTaskForm = true
    }

    func beginEditingTask(_ task: Task) {
        editingTaskId = task.id
        taskFormTitle = task.title
        taskFormThesisId = task.thesisId
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormRecurrence = task.recurrence
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        guard let thesisId = taskFormThesisId else { return }
        var savedTaskId: UUID?

        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle
            store.tasks[index].projectId = nil
            store.tasks[index].thesisId = thesisId
            store.tasks[index].priority = taskFormPriority
            store.tasks[index].dueDate = taskFormDueDate
            store.tasks[index].recurrence = taskFormRecurrence
            store.tasks[index].isToday = Calendar.current.isDateInToday(taskFormDueDate)
            store.tasks[index].updatedAt = Date()
            savedTaskId = store.tasks[index].id
        } else {
            let task = Task(
                title: taskFormTitle,
                projectId: nil,
                thesisId: thesisId,
                priority: taskFormPriority,
                dueDate: taskFormDueDate,
                recurrence: taskFormRecurrence,
                isToday: Calendar.current.isDateInToday(taskFormDueDate)
            )
            store.tasks.append(task)
            savedTaskId = task.id
        }

        store.save()
        resetTaskForm()
        loadData()
        if let savedTaskId {
            syncTaskToReminders(taskId: savedTaskId)
        }
    }

    func deleteTask(_ task: Task) {
        syncDeletedTaskToReminders(task)
        store.tasks.removeAll { $0.id == task.id }
        store.save()
        loadData()
    }

    func toggleTaskCompletion(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            if store.tasks[idx].status == .completed {
                store.tasks[idx].status = .notStarted
                store.tasks[idx].completionRate = 0
            } else {
                store.tasks[idx].status = .completed
                store.tasks[idx].completionRate = 100
            }
            store.tasks[idx].updatedAt = Date()
            store.save()
            loadData()
            syncTaskToReminders(taskId: store.tasks[idx].id)
        }
    }

    func toggleTaskToday(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].isToday.toggle()
            store.tasks[idx].updatedAt = Date()
            store.save()
            loadData()
            syncTaskToReminders(taskId: store.tasks[idx].id)
        }
    }

    func syncAllThesisTasksToReminders() {
        guard !isReminderSyncing else { return }
        isReminderSyncing = true
        reminderSyncMessage = ""

        Swift.Task { @MainActor in
            var imported = 0
            var updated = 0
            var pushed = 0
            var removed = 0
            var failed = 0

            for thesis in store.thesisInfos where thesis.reminderCalendarIdentifier != nil {
                do {
                    let result = try await syncThesisNow(thesis)
                    imported += result.createdLocal
                    updated += result.updatedLocal
                    pushed += result.pushedToReminders
                    removed += result.removedLocal
                } catch {
                    failed += 1
                }
            }

            isReminderSyncing = false
            reminderSyncMessage = failed == 0
                ? "课题提醒事项已同步：导入 \(imported)，更新 \(updated)，推送 \(pushed)，删除 \(removed)。"
                : "课题提醒事项部分同步失败：\(failed) 个课题失败。"
            store.save()
            loadData()
        }
    }

    func syncThesisToReminders(_ thesis: ThesisInfo) {
        guard !isReminderSyncing else { return }
        isReminderSyncing = true
        reminderSyncMessage = ""

        Swift.Task { @MainActor in
            do {
                let result = try await syncThesisNow(thesis)
                isReminderSyncing = false
                reminderSyncMessage = "已同步 \(thesis.title)：导入 \(result.createdLocal)，更新 \(result.updatedLocal)，推送 \(result.pushedToReminders)。"
                store.save()
                loadData()
            } catch {
                isReminderSyncing = false
                reminderSyncMessage = "提醒事项同步失败：\(error.localizedDescription)"
            }
        }
    }

    private func syncTaskToReminders(taskId: UUID) {
        Swift.Task { @MainActor in
            guard let task = store.tasks.first(where: { $0.id == taskId }) else { return }
            do {
                try await syncTaskToRemindersNow(task)
                reminderSyncMessage = "已同步到绑定的提醒事项列表。"
                loadData()
            } catch {
                reminderSyncMessage = "提醒事项同步失败：\(error.localizedDescription)"
            }
        }
    }

    private func syncTaskToRemindersNow(_ task: Task) async throws {
        guard let thesis = store.thesisInfos.first(where: { $0.id == task.thesisId }),
              let calendarIdentifier = thesis.reminderCalendarIdentifier else {
            return
        }
        let identifier = try await ReminderSyncService.shared.upsertTask(
            task,
            ownerKind: .thesis,
            ownerTitle: thesis.title,
            ownerId: thesis.id,
            calendarIdentifier: calendarIdentifier
        )

        if let index = store.tasks.firstIndex(where: { $0.id == task.id }),
           store.tasks[index].reminderIdentifier != identifier {
            store.tasks[index].reminderIdentifier = identifier
            store.tasks[index].updatedAt = Date()
            store.save()
        }
    }

    private func syncDeletedTaskToReminders(_ task: Task) {
        Swift.Task { @MainActor in
            do {
                try await ReminderSyncService.shared.deleteReminder(for: task)
                reminderSyncMessage = "已从提醒事项删除对应任务。"
            } catch {
                reminderSyncMessage = "提醒事项删除失败：\(error.localizedDescription)"
            }
        }
    }

    private func syncThesisNow(_ thesis: ThesisInfo) async throws -> ReminderSyncService.SyncResult {
        guard let calendarIdentifier = thesis.reminderCalendarIdentifier else {
            return ReminderSyncService.SyncResult()
        }
        return try await ReminderSyncService.shared.syncTasks(
            ownerId: thesis.id,
            ownerKind: .thesis,
            ownerTitle: thesis.title,
            calendarIdentifier: calendarIdentifier,
            tasks: &store.tasks
        )
    }

    private func loadReminderListsIfNeeded() {
        guard reminderLists.isEmpty else { return }
        Swift.Task { @MainActor in
            do {
                reminderLists = try await ReminderSyncService.shared.reminderLists()
            } catch {
                reminderSyncMessage = "读取提醒事项列表失败：\(error.localizedDescription)"
            }
        }
    }

    private func syncBoundThesesOnceIfNeeded() {
        guard !didRunInitialReminderSync else { return }
        guard store.thesisInfos.contains(where: { $0.reminderCalendarIdentifier != nil }) else { return }
        didRunInitialReminderSync = true
        syncAllThesisTasksToReminders()
    }

    func resetTaskForm() {
        taskFormTitle = ""
        taskFormThesisId = nil
        taskFormPriority = .important
        taskFormDueDate = Date()
        taskFormRecurrence = .none
        editingTaskId = nil
        showTaskForm = false
    }

    var filteredTasks: [Task] {
        var result = tasks
        if let filter = taskStatusFilter { result = result.filter { $0.status == filter } }
        if !showCompletedTasks { result = result.filter { $0.status != .completed } }
        return result
    }

    var stats: ThesisStats {
        let total = theses.count
        let active = theses.filter { $0.overallProgress < 1.0 }.count
        let completed = theses.filter { $0.overallProgress >= 1.0 }.count
        let thesisTasks = store.tasks.filter { $0.thesisId != nil && $0.projectId == nil }
        return ThesisStats(
            totalTheses: total,
            activeTheses: active,
            completedTheses: completed,
            totalTasks: thesisTasks.count,
            completedTasks: thesisTasks.filter { $0.status == .completed }.count
        )
    }

    struct ThesisStats {
        var totalTheses: Int = 0
        var activeTheses: Int = 0
        var completedTheses: Int = 0
        var totalTasks: Int = 0
        var completedTasks: Int = 0
    }
}
