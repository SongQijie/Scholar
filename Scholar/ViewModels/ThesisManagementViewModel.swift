import Foundation
import Combine

class ThesisManagementViewModel: ObservableObject {
    @Published var boardStats: AppDataStore.ThesisBoardStats = .init()
    @Published var theses: [ThesisInfo] = []
    @Published var tasks: [Task] = []
    @Published var selectedThesisFilter: UUID? = nil
    @Published var hideCompletedTasks: Bool = UserDefaults.standard.bool(forKey: "Scholar.ThesisTasks.HideCompleted") {
        didSet { UserDefaults.standard.set(hideCompletedTasks, forKey: "Scholar.ThesisTasks.HideCompleted") }
    }
    @Published var thesisFormTitle: String = ""
    @Published var thesisFormStage: ThesisStage = .literatureReview
    @Published var thesisFormSharedDocumentLink: String = ""
    @Published var thesisFormDueDate: Date = Date()
    @Published var thesisFormHasDueDate: Bool = false
    @Published var thesisFormNotes: String = ""
    @Published var thesisFormStudents: String = ""
    @Published var showThesisForm: Bool = false
    @Published var editingThesisId: UUID? = nil

    @Published var taskFormTitle: String = ""
    @Published var taskFormDetails: String = ""
    @Published var taskFormThesisId: UUID? = nil
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormHasDueDate: Bool = false
    @Published var taskFormRecurrence: TaskRecurrence = .none
    @Published var taskFormIsToday: Bool = false
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil
    @Published var taskFormError: String? = nil

    private var store: AppDataStore { AppDataStore.shared }

    func loadData() {
        boardStats = store.computeThesisBoardStats()
        theses = store.thesisInfos.filter { !$0.isArchived }.sorted {
            if $0.title != $1.title {
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
            return $0.id.uuidString < $1.id.uuidString
        }
        loadTasks()
    }

    func loadTasks() {
        let activeThesisIds = Set(store.thesisInfos.filter { !$0.isArchived }.map(\.id))
        var all = store.tasks.filter { task in
            guard let thesisId = task.thesisId else { return false }
            return activeThesisIds.contains(thesisId) && task.projectId == nil && task.affairId == nil
        }
        if let filter = selectedThesisFilter {
            all = all.filter { $0.thesisId == filter }
        }
        tasks = all.sorted { a, b in
            let aDue = a.dueDate ?? .distantFuture
            let bDue = b.dueDate ?? .distantFuture
            if aDue != bDue { return aDue < bDue }
            if a.priority.rawValue != b.priority.rawValue { return a.priority.rawValue < b.priority.rawValue }
            return a.createdAt < b.createdAt
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
        thesisFormDueDate = thesis.dueDate ?? Date()
        thesisFormHasDueDate = thesis.dueDate != nil
        thesisFormNotes = thesis.notes
        thesisFormStudents = thesis.students.map(\.name).joined(separator: ", ")
        showThesisForm = true
    }

    func saveThesis() {
        guard thesisFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let students = thesisFormStudents.normalizedLines.map { Student(name: $0, role: "参与学生") }
        if let editingThesisId, let index = store.thesisInfos.firstIndex(where: { $0.id == editingThesisId }) {
            store.thesisInfos[index].title = thesisFormTitle
            store.thesisInfos[index].stage = thesisFormStage
            store.thesisInfos[index].sharedDocumentLink = thesisFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            store.thesisInfos[index].dueDate = thesisFormHasDueDate ? thesisFormDueDate : nil
            store.thesisInfos[index].notes = thesisFormNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            store.thesisInfos[index].students = students
        } else {
            let thesis = ThesisInfo(
                title: thesisFormTitle,
                stage: thesisFormStage,
                notes: thesisFormNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                sharedDocumentLink: thesisFormSharedDocumentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: thesisFormHasDueDate ? thesisFormDueDate : nil,
                students: students
            )
            store.thesisInfos.append(thesis)
        }

        store.save()
        resetThesisForm()
        loadData()
    }

    func deleteThesis(_ thesis: ThesisInfo) {
        store.thesisInfos.removeAll { $0.id == thesis.id }
        store.tasks.removeAll { $0.thesisId == thesis.id && $0.projectId == nil && $0.affairId == nil }
        store.save()
        loadData()
    }

    func archiveThesis(_ thesis: ThesisInfo) {
        guard let index = store.thesisInfos.firstIndex(where: { $0.id == thesis.id }) else { return }
        store.thesisInfos[index].isArchived = true
        store.thesisInfos[index].stage = .submitted
        if selectedThesisFilter == thesis.id {
            selectedThesisFilter = nil
        }
        store.save()
        loadData()
    }

    func resetThesisForm() {
        thesisFormTitle = ""
        thesisFormStage = .literatureReview
        thesisFormSharedDocumentLink = ""
        thesisFormDueDate = Date()
        thesisFormHasDueDate = false
        thesisFormNotes = ""
        thesisFormStudents = ""
        editingThesisId = nil
        showThesisForm = false
    }

    func beginCreatingTask(prefilledThesisId: UUID? = nil) {
        resetTaskForm()
        taskFormThesisId = prefilledThesisId ?? selectedThesisFilter ?? theses.first?.id
        if let thesis = store.thesisInfos.first(where: { $0.id == taskFormThesisId }),
           let thesisDueDate = thesis.dueDate,
           taskFormDueDate > thesisDueDate {
            taskFormDueDate = thesisDueDate
        }
        taskFormHasDueDate = false
        showTaskForm = true
    }

    func beginEditingTask(_ task: Task) {
        editingTaskId = task.id
        taskFormTitle = task.title
        taskFormDetails = task.details
        taskFormThesisId = task.thesisId
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormHasDueDate = task.dueDate != nil
        taskFormRecurrence = task.recurrence
        taskFormIsToday = task.isToday
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        guard let thesisId = taskFormThesisId else { return }
        let dueDate = taskFormHasDueDate ? taskFormDueDate : nil
        if let thesis = store.thesisInfos.first(where: { $0.id == thesisId }),
           let thesisDueDate = thesis.dueDate,
           let taskDueDate = dueDate,
           taskDueDate > thesisDueDate {
            taskFormError = "任务截止时间不能晚于课题 DDL（\(thesisDueDate.formatted("yyyy-MM-dd HH:mm"))）"
            return
        }
        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle
            store.tasks[index].details = taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].projectId = nil
            store.tasks[index].thesisId = thesisId
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
                projectId: nil,
                thesisId: thesisId,
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
        taskFormThesisId = nil
        taskFormPriority = .important
        taskFormDueDate = Date()
        taskFormHasDueDate = false
        taskFormRecurrence = .none
        taskFormIsToday = false
        taskFormError = nil
        editingTaskId = nil
        showTaskForm = false
    }

    var filteredTasks: [Task] {
        var result = tasks
        if hideCompletedTasks { result = result.filter { $0.status != .completed } }
        return result
    }

    var stats: ThesisStats {
        let total = theses.count
        let active = theses.filter { $0.overallProgress < 1.0 }.count
        let completed = theses.filter { $0.overallProgress >= 1.0 }.count
        let thesisTasks = store.tasks.filter { $0.thesisId != nil && $0.projectId == nil && $0.affairId == nil }
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
