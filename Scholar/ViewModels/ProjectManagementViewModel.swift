import Foundation
import Combine

class ProjectManagementViewModel: ObservableObject {
    @Published var stats: AppDataStore.ProjectBoardStats = .init()
    @Published var projects: [Project] = []
    @Published var tasks: [Task] = []
    @Published var selectedProjectFilter: UUID? = nil
    @Published var showCompletedTasks: Bool = true
    @Published var isReminderSyncing: Bool = false
    @Published var reminderSyncMessage: String = ""
    @Published var reminderLists: [ReminderSyncService.ReminderListOption] = []

    @Published var projectFormTitle: String = ""
    @Published var projectFormResult: String = ""
    @Published var projectFormSharedDocumentLink: String = ""
    @Published var projectFormCategory: ProjectCategory = .other
    @Published var projectFormStage: ProjectStage = .planning
    @Published var projectFormPriority: ProjectPriority = .medium
    @Published var projectFormOwner: String = ""
    @Published var projectFormCollaborators: String = ""
    @Published var projectFormSummary: String = ""
    @Published var projectFormKeywords: String = ""
    @Published var projectFormFundingSource: String = ""
    @Published var projectFormExpectedDeliverables: String = ""
    @Published var projectFormBudget: String = ""
    @Published var projectFormStartDate: Date = Date()
    @Published var projectFormDeadline: Date = Date()
    @Published var projectFormNotes: String = ""
    @Published var projectFormReminderCalendarIdentifier: String? = nil
    @Published var showProjectForm: Bool = false
    @Published var editingProjectId: UUID? = nil

    @Published var taskFormTitle: String = ""
    @Published var taskFormProjectId: UUID? = nil
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormRecurrence: TaskRecurrence = .none
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil

    @Published var taskStatusFilter: TaskStatus? = nil

    private var store: AppDataStore { AppDataStore.shared }
    private var didRunInitialReminderSync = false

    func loadData() {
        stats = store.computeProjectBoardStats()
        projects = store.projects.sorted { $0.createdAt > $1.createdAt }
        loadTasks()
        loadReminderListsIfNeeded()
        syncBoundProjectsOnceIfNeeded()
    }

    func loadTasks() {
        var all = store.tasks.filter { $0.projectId != nil && $0.thesisId == nil }
        if let filter = selectedProjectFilter {
            all = all.filter { $0.projectId == filter }
        }
        tasks = all.sorted { a, b in
            if a.status.rawValue != b.status.rawValue { return a.status.rawValue < b.status.rawValue }
            if a.dueDate != b.dueDate { return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
            return a.priority.rawValue < b.priority.rawValue
        }
    }

    func beginCreatingProject() {
        resetProjectForm()
        showProjectForm = true
    }

    func beginEditingProject(_ project: Project) {
        editingProjectId = project.id
        projectFormTitle = project.name
        projectFormResult = project.result
        projectFormSharedDocumentLink = project.sharedDocumentLink
        projectFormCategory = project.category
        projectFormStage = project.stage
        projectFormPriority = project.priority
        projectFormOwner = project.owner
        projectFormCollaborators = project.collaborators
        projectFormSummary = project.summary
        projectFormKeywords = project.keywords.joined(separator: ", ")
        projectFormFundingSource = project.fundingSource
        projectFormExpectedDeliverables = project.expectedDeliverables
        projectFormBudget = project.budget.map { String($0) } ?? ""
        projectFormStartDate = project.startDate ?? Date()
        projectFormDeadline = project.deadline ?? Date()
        projectFormNotes = project.notes
        projectFormReminderCalendarIdentifier = project.reminderCalendarIdentifier
        showProjectForm = true
    }

    func saveProject() {
        guard projectFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let keywords = projectFormKeywords.normalizedLines
        let budget = Double(projectFormBudget.trimmingCharacters(in: .whitespaces))
        var savedProjectId: UUID?

        if let editingProjectId, let index = store.projects.firstIndex(where: { $0.id == editingProjectId }) {
            store.projects[index].name = projectFormTitle
            store.projects[index].result = projectFormResult
            store.projects[index].sharedDocumentLink = projectFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            store.projects[index].category = projectFormCategory
            store.projects[index].stage = projectFormStage
            store.projects[index].priority = projectFormPriority
            store.projects[index].owner = projectFormOwner.trimmingCharacters(in: .whitespaces)
            store.projects[index].collaborators = projectFormCollaborators.trimmingCharacters(in: .whitespaces)
            store.projects[index].summary = projectFormSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            store.projects[index].keywords = keywords
            store.projects[index].fundingSource = projectFormFundingSource.trimmingCharacters(in: .whitespaces)
            store.projects[index].expectedDeliverables = projectFormExpectedDeliverables.trimmingCharacters(in: .whitespacesAndNewlines)
            store.projects[index].budget = budget
            store.projects[index].startDate = projectFormStartDate
            store.projects[index].deadline = projectFormDeadline
            store.projects[index].notes = projectFormNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            store.projects[index].reminderCalendarIdentifier = projectFormReminderCalendarIdentifier
            store.projects[index].updatedAt = Date()
            savedProjectId = store.projects[index].id
        } else {
            let project = Project(
                name: projectFormTitle,
                result: projectFormResult,
                sharedDocumentLink: projectFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                category: projectFormCategory,
                stage: projectFormStage,
                priority: projectFormPriority,
                owner: projectFormOwner.trimmingCharacters(in: .whitespaces),
                collaborators: projectFormCollaborators.trimmingCharacters(in: .whitespaces),
                summary: projectFormSummary.trimmingCharacters(in: .whitespacesAndNewlines),
                keywords: keywords,
                fundingSource: projectFormFundingSource.trimmingCharacters(in: .whitespaces),
                expectedDeliverables: projectFormExpectedDeliverables.trimmingCharacters(in: .whitespacesAndNewlines),
                budget: budget,
                startDate: projectFormStartDate,
                deadline: projectFormDeadline,
                notes: projectFormNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                reminderCalendarIdentifier: projectFormReminderCalendarIdentifier
            )
            store.projects.append(project)
            savedProjectId = project.id
        }

        store.save()
        resetProjectForm()
        loadData()
        if let savedProjectId,
           let project = store.projects.first(where: { $0.id == savedProjectId }),
           project.reminderCalendarIdentifier != nil {
            syncProjectToReminders(project)
        }
    }

    func deleteProject(_ project: Project) {
        store.projects.removeAll { $0.id == project.id }
        store.tasks.removeAll { $0.projectId == project.id && $0.thesisId == nil }
        store.save()
        loadData()
    }

    func resetProjectForm() {
        projectFormTitle = ""
        projectFormResult = ""
        projectFormSharedDocumentLink = ""
        projectFormCategory = .other
        projectFormStage = .planning
        projectFormPriority = .medium
        projectFormOwner = ""
        projectFormCollaborators = ""
        projectFormSummary = ""
        projectFormKeywords = ""
        projectFormFundingSource = ""
        projectFormExpectedDeliverables = ""
        projectFormBudget = ""
        projectFormStartDate = Date()
        projectFormDeadline = Date()
        projectFormNotes = ""
        projectFormReminderCalendarIdentifier = nil
        editingProjectId = nil
        showProjectForm = false
    }

    func beginCreatingTask(prefilledProjectId: UUID? = nil) {
        resetTaskForm()
        taskFormProjectId = prefilledProjectId ?? selectedProjectFilter ?? projects.first?.id
        showTaskForm = true
    }

    func beginEditingTask(_ task: Task) {
        editingTaskId = task.id
        taskFormTitle = task.title
        taskFormProjectId = task.projectId
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormRecurrence = task.recurrence
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        guard let projectId = taskFormProjectId else { return }
        var savedTaskId: UUID?

        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle
            store.tasks[index].projectId = projectId
            store.tasks[index].thesisId = nil
            store.tasks[index].priority = taskFormPriority
            store.tasks[index].dueDate = taskFormDueDate
            store.tasks[index].recurrence = taskFormRecurrence
            store.tasks[index].isToday = Calendar.current.isDateInToday(taskFormDueDate)
            store.tasks[index].updatedAt = Date()
            savedTaskId = store.tasks[index].id
        } else {
            let task = Task(
                title: taskFormTitle,
                projectId: projectId,
                thesisId: nil,
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

    func syncAllProjectTasksToReminders() {
        guard !isReminderSyncing else { return }
        isReminderSyncing = true
        reminderSyncMessage = ""

        Swift.Task { @MainActor in
            var imported = 0
            var updated = 0
            var pushed = 0
            var removed = 0
            var failed = 0

            for project in store.projects where project.reminderCalendarIdentifier != nil {
                do {
                    let result = try await syncProjectNow(project)
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
                ? "项目提醒事项已同步：导入 \(imported)，更新 \(updated)，推送 \(pushed)，删除 \(removed)。"
                : "项目提醒事项部分同步失败：\(failed) 个项目失败。"
            store.save()
            loadData()
        }
    }

    func syncProjectToReminders(_ project: Project) {
        guard !isReminderSyncing else { return }
        isReminderSyncing = true
        reminderSyncMessage = ""

        Swift.Task { @MainActor in
            do {
                let result = try await syncProjectNow(project)
                isReminderSyncing = false
                reminderSyncMessage = "已同步 \(project.name)：导入 \(result.createdLocal)，更新 \(result.updatedLocal)，推送 \(result.pushedToReminders)。"
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
        guard let project = store.projects.first(where: { $0.id == task.projectId }),
              let calendarIdentifier = project.reminderCalendarIdentifier else {
            return
        }
        let identifier = try await ReminderSyncService.shared.upsertTask(
            task,
            ownerKind: .project,
            ownerTitle: project.name,
            ownerId: project.id,
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

    private func syncProjectNow(_ project: Project) async throws -> ReminderSyncService.SyncResult {
        guard let calendarIdentifier = project.reminderCalendarIdentifier else {
            return ReminderSyncService.SyncResult()
        }
        return try await ReminderSyncService.shared.syncTasks(
            ownerId: project.id,
            ownerKind: .project,
            ownerTitle: project.name,
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

    private func syncBoundProjectsOnceIfNeeded() {
        guard !didRunInitialReminderSync else { return }
        guard store.projects.contains(where: { $0.reminderCalendarIdentifier != nil }) else { return }
        didRunInitialReminderSync = true
        syncAllProjectTasksToReminders()
    }

    func resetTaskForm() {
        taskFormTitle = ""
        taskFormProjectId = nil
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

    var notStartedTasks: [Task] { filteredTasks.filter { $0.status == .notStarted } }
    var inProgressTasks: [Task] { filteredTasks.filter { $0.status == .inProgress } }
    var completedTasks: [Task] { filteredTasks.filter { $0.status == .completed } }

    var projectsByCategory: [(ProjectCategory, [Project])] {
        Dictionary(grouping: projects, by: \.category)
            .map { ($0.key, $0.value.sorted { $0.updatedAt > $1.updatedAt }) }
            .sorted { $0.0.rawValue < $1.0.rawValue }
    }
}
