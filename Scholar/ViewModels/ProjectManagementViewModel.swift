import Foundation
import Combine

class ProjectManagementViewModel: ObservableObject {
    @Published var stats: AppDataStore.ProjectBoardStats = .init()
    @Published var projects: [Project] = []
    @Published var tasks: [Task] = []
    @Published var selectedProjectFilter: UUID? = nil
    @Published var hideCompletedTasks: Bool = UserDefaults.standard.bool(forKey: "Scholar.ProjectTasks.HideCompleted") {
        didSet { UserDefaults.standard.set(hideCompletedTasks, forKey: "Scholar.ProjectTasks.HideCompleted") }
    }
    @Published var projectFormTitle: String = ""
    @Published var projectFormResult: String = ""
    @Published var projectFormSharedDocumentLink: String = ""
    @Published var projectFormCategory: ProjectCategory = .horizontal
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
    @Published var projectFormHasStartDate: Bool = false
    @Published var projectFormDeadline: Date = Date()
    @Published var projectFormHasDeadline: Bool = false
    @Published var projectFormNotes: String = ""
    @Published var showProjectForm: Bool = false
    @Published var editingProjectId: UUID? = nil

    @Published var taskFormTitle: String = ""
    @Published var taskFormDetails: String = ""
    @Published var taskFormProjectId: UUID? = nil
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormHasDueDate: Bool = false
    @Published var taskFormRecurrence: TaskRecurrence = .none
    @Published var taskFormIsToday: Bool = false
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil

    private var store: AppDataStore { AppDataStore.shared }

    func loadData() {
        stats = store.computeProjectBoardStats()
        projects = store.projects.filter { !$0.isArchived }.sorted { $0.createdAt > $1.createdAt }
        loadTasks()
    }

    func loadTasks() {
        let activeProjectIds = Set(store.projects.filter { !$0.isArchived }.map(\.id))
        var all = store.tasks.filter { task in
            guard let projectId = task.projectId else { return false }
            return activeProjectIds.contains(projectId) && task.thesisId == nil && task.affairId == nil
        }
        if let filter = selectedProjectFilter {
            all = all.filter { $0.projectId == filter }
        }
        tasks = all.sorted { a, b in
            let aDue = a.dueDate ?? .distantFuture
            let bDue = b.dueDate ?? .distantFuture
            if aDue != bDue { return aDue < bDue }
            if a.priority.rawValue != b.priority.rawValue { return a.priority.rawValue < b.priority.rawValue }
            return a.createdAt < b.createdAt
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
        projectFormHasStartDate = project.startDate != nil
        projectFormDeadline = project.deadline ?? Date()
        projectFormHasDeadline = project.deadline != nil
        projectFormNotes = project.notes
        showProjectForm = true
    }

    func saveProject() {
        guard projectFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let keywords = projectFormKeywords.normalizedLines
        let budget = Double(projectFormBudget.trimmingCharacters(in: .whitespaces))
        let startDate = projectFormHasStartDate ? projectFormStartDate : nil
        let deadline = projectFormHasDeadline ? projectFormDeadline : nil
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
            store.projects[index].startDate = startDate
            store.projects[index].deadline = deadline
            store.projects[index].notes = projectFormNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            store.projects[index].updatedAt = Date()
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
                startDate: startDate,
                deadline: deadline,
                notes: projectFormNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            store.projects.append(project)
        }

        store.save()
        resetProjectForm()
        loadData()
    }

    func deleteProject(_ project: Project) {
        store.projects.removeAll { $0.id == project.id }
        store.tasks.removeAll { $0.projectId == project.id && $0.thesisId == nil && $0.affairId == nil }
        store.save()
        loadData()
    }

    func archiveProject(_ project: Project) {
        guard let index = store.projects.firstIndex(where: { $0.id == project.id }) else { return }
        store.projects[index].isArchived = true
        store.projects[index].stage = .completed
        store.projects[index].updatedAt = Date()
        if selectedProjectFilter == project.id {
            selectedProjectFilter = nil
        }
        store.save()
        loadData()
    }

    func resetProjectForm() {
        projectFormTitle = ""
        projectFormResult = ""
        projectFormSharedDocumentLink = ""
        projectFormCategory = .horizontal
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
        projectFormHasStartDate = false
        projectFormDeadline = Date()
        projectFormHasDeadline = false
        projectFormNotes = ""
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
        taskFormDetails = task.details
        taskFormProjectId = task.projectId
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormHasDueDate = task.dueDate != nil
        taskFormRecurrence = task.recurrence
        taskFormIsToday = task.isToday
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        guard let projectId = taskFormProjectId else { return }
        let dueDate = taskFormHasDueDate ? taskFormDueDate : nil
        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle
            store.tasks[index].details = taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].projectId = projectId
            store.tasks[index].thesisId = nil
            store.tasks[index].affairId = nil
            store.tasks[index].priority = taskFormPriority
            store.tasks[index].dueDate = dueDate
            store.tasks[index].recurrence = taskFormRecurrence
            store.tasks[index].isToday = taskFormIsToday
            store.tasks[index].updatedAt = Date()
        } else {
            let task = Task(
                title: taskFormTitle,
                details: taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                projectId: projectId,
                thesisId: nil,
                affairId: nil,
                priority: taskFormPriority,
                dueDate: dueDate,
                recurrence: taskFormRecurrence,
                isToday: taskFormIsToday
            )
            store.tasks.append(task)
        }

        store.save()
        resetTaskForm()
        loadData()
    }

    func deleteTask(_ task: Task) {
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
        }
    }

    func toggleTaskToday(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].isToday.toggle()
            store.tasks[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func resetTaskForm() {
        taskFormTitle = ""
        taskFormDetails = ""
        taskFormProjectId = nil
        taskFormPriority = .important
        taskFormDueDate = Date()
        taskFormHasDueDate = false
        taskFormRecurrence = .none
        taskFormIsToday = false
        editingTaskId = nil
        showTaskForm = false
    }

    var filteredTasks: [Task] {
        var result = tasks
        if hideCompletedTasks { result = result.filter { $0.status != .completed } }
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

class AffairManagementViewModel: ObservableObject {
    @Published var stats: AppDataStore.AffairBoardStats = .init()
    @Published var affairs: [Affair] = []
    @Published var tasks: [Task] = []
    @Published var selectedAffairFilter: UUID? = nil
    @Published var hideCompletedTasks: Bool = UserDefaults.standard.bool(forKey: "Scholar.AffairTasks.HideCompleted") {
        didSet { UserDefaults.standard.set(hideCompletedTasks, forKey: "Scholar.AffairTasks.HideCompleted") }
    }

    @Published var affairFormTitle: String = ""
    @Published var affairFormDetails: String = ""
    @Published var affairFormDueDate: Date = Date()
    @Published var affairFormHasDueDate: Bool = true
    @Published var affairFormSource: String = ""
    @Published var affairFormTags: String = ""
    @Published var showAffairForm: Bool = false
    @Published var editingAffairId: UUID? = nil

    @Published var taskFormTitle: String = ""
    @Published var taskFormDetails: String = ""
    @Published var taskFormCollaborator: String = "本人"
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormAffairId: UUID? = nil
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormHasDueDate: Bool = false
    @Published var taskFormIsToday: Bool = false
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil
    @Published var taskFormError: String? = nil

    private var store: AppDataStore { AppDataStore.shared }

    func loadData() {
        stats = store.computeAffairBoardStats()
        affairs = store.affairs.filter { !$0.isArchived }.sorted { a, b in
            if a.dueDate != b.dueDate { return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture) }
            return a.updatedAt > b.updatedAt
        }
        loadTasks()
    }

    func loadTasks() {
        let activeAffairIds = Set(store.affairs.filter { !$0.isArchived }.map(\.id))
        var all = store.tasks.filter { task in
            guard let affairId = task.affairId else { return false }
            return activeAffairIds.contains(affairId) && task.projectId == nil && task.thesisId == nil
        }
        if let selectedAffairFilter {
            all = all.filter { $0.affairId == selectedAffairFilter }
        }
        tasks = all.sorted { a, b in
            let aDue = a.dueDate ?? .distantFuture
            let bDue = b.dueDate ?? .distantFuture
            if aDue != bDue { return aDue < bDue }
            if a.priority.rawValue != b.priority.rawValue { return a.priority.rawValue < b.priority.rawValue }
            return a.createdAt < b.createdAt
        }
    }

    func beginCreatingAffair() {
        resetAffairForm()
        showAffairForm = true
    }

    func beginEditingAffair(_ affair: Affair) {
        editingAffairId = affair.id
        affairFormTitle = affair.title
        affairFormDueDate = affair.dueDate ?? Date()
        affairFormHasDueDate = affair.dueDate != nil
        affairFormTags = affair.tags.joined(separator: ", ")
        showAffairForm = true
    }

    func saveAffair() {
        guard affairFormTitle.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else { return }
        let tags = affairFormTags.normalizedLines
        let dueDate = affairFormHasDueDate ? affairFormDueDate : nil

        if let editingAffairId, let index = store.affairs.firstIndex(where: { $0.id == editingAffairId }) {
            store.affairs[index].title = affairFormTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            store.affairs[index].details = affairFormDetails
            store.affairs[index].dueDate = dueDate
            store.affairs[index].source = ""
            store.affairs[index].tags = tags
            store.affairs[index].updatedAt = Date()
        } else {
            let affair = Affair(
                title: affairFormTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                details: affairFormDetails,
                dueDate: dueDate,
                source: "",
                tags: tags
            )
            store.affairs.append(affair)
        }

        store.save()
        resetAffairForm()
        loadData()
    }

    func deleteAffair(_ affair: Affair) {
        store.affairs.removeAll { $0.id == affair.id }
        store.tasks.removeAll { $0.affairId == affair.id && $0.projectId == nil && $0.thesisId == nil }
        store.save()
        loadData()
    }

    func archiveAffair(_ affair: Affair) {
        guard let index = store.affairs.firstIndex(where: { $0.id == affair.id }) else { return }
        store.affairs[index].isArchived = true
        store.affairs[index].updatedAt = Date()
        if selectedAffairFilter == affair.id {
            selectedAffairFilter = nil
        }
        store.save()
        loadData()
    }

    func resetAffairForm() {
        affairFormTitle = ""
        affairFormDueDate = Date()
        affairFormHasDueDate = true
        affairFormTags = ""
        editingAffairId = nil
        showAffairForm = false
    }

    func beginCreatingTask(prefilledAffairId: UUID? = nil) {
        resetTaskForm()
        taskFormAffairId = prefilledAffairId ?? selectedAffairFilter ?? affairs.first?.id
        showTaskForm = true
    }

    func beginEditingTask(_ task: Task) {
        editingTaskId = task.id
        taskFormTitle = task.title
        taskFormDetails = task.details
        taskFormCollaborator = task.collaborator
        taskFormAffairId = task.affairId
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormHasDueDate = task.dueDate != nil
        taskFormIsToday = task.isToday
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else { return }
        guard let affairId = taskFormAffairId else { return }
        let dueDate = taskFormHasDueDate ? taskFormDueDate : nil

        if let affair = store.affairs.first(where: { $0.id == affairId }),
           let affairDeadline = affair.dueDate,
           let taskDeadline = dueDate {
            if taskDeadline > affairDeadline {
                taskFormError = "任务截止时间不能晚于事务截止时间（\(affairDeadline.formatted("yyyy-MM-dd HH:mm"))）"
                return
            }
        }

        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].details = taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].collaborator = normalizedTaskCollaborator
            store.tasks[index].projectId = nil
            store.tasks[index].thesisId = nil
            store.tasks[index].affairId = affairId
            store.tasks[index].priority = taskFormPriority
            store.tasks[index].dueDate = dueDate
            store.tasks[index].isToday = taskFormIsToday
            store.tasks[index].updatedAt = Date()
        } else {
            let task = Task(
                title: taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                details: taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                collaborator: normalizedTaskCollaborator,
                projectId: nil,
                thesisId: nil,
                affairId: affairId,
                priority: taskFormPriority,
                dueDate: dueDate,
                isToday: taskFormIsToday
            )
            store.tasks.append(task)
        }

        store.save()
        resetTaskForm()
        loadData()
    }

    func deleteTask(_ task: Task) {
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
        }
    }

    func toggleTaskToday(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].isToday.toggle()
            store.tasks[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func resetTaskForm() {
        taskFormTitle = ""
        taskFormDetails = ""
        taskFormCollaborator = "本人"
        taskFormPriority = .important
        taskFormAffairId = nil
        taskFormDueDate = Date()
        taskFormHasDueDate = false
        taskFormIsToday = false
        taskFormError = nil
        editingTaskId = nil
        showTaskForm = false
    }

    var filteredTasks: [Task] {
        hideCompletedTasks ? tasks.filter { $0.status != .completed } : tasks
    }

    private var normalizedTaskCollaborator: String {
        let trimmed = taskFormCollaborator.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "本人" : trimmed
    }

}
