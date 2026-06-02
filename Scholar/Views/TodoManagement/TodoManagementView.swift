import SwiftUI

struct TodoManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = TodoManagementViewModel()
    @State private var taskToDelete: Task?
    @State private var showDeleteTaskConfirmation = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLg) {
                overviewSection
                    .fadeIn()
                tasksSection
                    .fadeIn(delay: 0.1)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            viewModel.loadData()
        }
        .alert(language.text("删除待办", "Delete Todo"), isPresented: $showDeleteTaskConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let task = taskToDelete {
                    viewModel.deleteTask(task)
                }
                taskToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个待办吗？", "Delete this todo?"))
        }
    }

    private var overviewSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingLg) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text("待办管理", "Todo Management"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(language.text("管理非项目、非课题、非事务的独立待办", "Manage standalone todos outside projects, topics, and affairs"))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

            }
            .frame(width: 330, alignment: .leading)

            compactStatsPanel
                .frame(maxWidth: .infinity, minHeight: 118, alignment: .center)
        }
        .padding(AppTheme.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                        .stroke(AppTheme.primary.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var compactStatsPanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(spacing: AppTheme.spacingSm) {
                compactStatChip(language.text("总数", "Total"), "\(viewModel.stats.totalTasks)", color: AppTheme.primary)
                compactStatChip(language.text("未完成", "Open"), "\(viewModel.stats.incompleteTasks)", color: AppTheme.warning)
                compactStatChip(language.text("已完成", "Done"), "\(viewModel.stats.completedTasks)", color: AppTheme.success)
                compactStatChip(language.text("7天内", "7 Days"), "\(viewModel.stats.dueWithin7Days)", color: AppTheme.danger)
                compactStatChip(language.text("逾期", "Overdue"), "\(viewModel.stats.overdueTasks)", color: AppTheme.danger)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: AppTheme.spacingSm) {
                compactQuadrantChip(language.text("紧急\n且重要", "Urgent\nImportant"), viewModel.stats.todayMustDo, icon: "exclamationmark.triangle.fill", color: AppTheme.danger)
                compactQuadrantChip(language.text("重要\n不紧急", "Important\nNot Urgent"), viewModel.stats.todayShouldDo, icon: "arrow.up.circle.fill", color: AppTheme.warning)
                compactQuadrantChip(language.text("紧急\n不重要", "Urgent\nNot Important"), viewModel.stats.q3Tasks, icon: "bolt.fill", color: AppTheme.secondary)
                compactQuadrantChip(language.text("不紧急\n不重要", "Not Urgent\nNot Important"), viewModel.stats.q4Tasks, icon: "minus.circle.fill", color: AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, AppTheme.spacingSm)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .center)
        .background(AppTheme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border.opacity(0.45), lineWidth: 0.75)
        )
    }

    private func compactStatChip(_ title: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.spacingSm)
        .padding(.vertical, AppTheme.spacingXs)
        .frame(minWidth: 86, maxWidth: .infinity, minHeight: 50, alignment: .center)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(color.opacity(0.18), lineWidth: 0.75)
        )
    }

    private func compactQuadrantChip(_ title: String, _ count: Int, icon: String, color: Color) -> some View {
        HStack(spacing: AppTheme.spacingSm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(color.opacity(0.14), lineWidth: 0.75)
        )
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("待办任务", "Todo Tasks"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("只显示没有归属到项目、课题、事务的任务。", "Only tasks not linked to a project, topic, or affair are shown."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.beginCreatingTask()
                } label: {
                    Label(language.text("新建待办", "New Todo"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.accent)
            }

            filterBar

            if viewModel.showTaskForm {
                taskForm
            }

            if viewModel.filteredTasks.isEmpty {
                emptyState(language.text("当前没有待办任务。", "No todos yet."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.filteredTasks) { task in
                        TodoTaskRowView(
                            task: task,
                            onToggle: { viewModel.toggleTaskCompletion(task) },
                            onToggleToday: { viewModel.toggleTaskToday(task) },
                            onEdit: { viewModel.beginEditingTask(task) },
                            onDelaySaved: { viewModel.loadData() },
                            onDelete: {
                                taskToDelete = task
                                showDeleteTaskConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var filterBar: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Toggle(language.text("隐藏已完成", "Hide Completed"), isOn: $viewModel.hideCompletedTasks)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)

            Spacer()
        }
        .onChange(of: viewModel.hideCompletedTasks) {
            viewModel.loadTasks()
        }
    }

    private var taskForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingTaskId == nil ? language.text("新建待办", "New Todo") : language.text("编辑待办", "Edit Todo"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            formField(language.text("任务标题", "Task Title"), text: $viewModel.taskFormTitle)

            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("优先级", "Priority"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("优先级", "Priority"), selection: $viewModel.taskFormPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("循环", "Recurrence"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("循环", "Recurrence"), selection: $viewModel.taskFormRecurrence) {
                        ForEach(TaskRecurrence.allCases, id: \.self) { recurrence in
                            Text(recurrence.displayName).tag(recurrence)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                todoDatePicker(
                    title: language.text("DDL", "DDL"),
                    hasDate: $viewModel.taskFormHasDueDate,
                    date: $viewModel.taskFormDueDate
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("关注", "Watched"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Toggle(language.text("关注", "Watched"), isOn: $viewModel.taskFormIsToday)
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                        .frame(height: 38, alignment: .center)
                }
                .frame(width: 80, alignment: .leading)
            }

            multilineField(language.text("任务内容", "Task Content"), text: $viewModel.taskFormDetails)

            TaskDependencyFormFields(
                blockedReason: $viewModel.taskFormBlockedReason,
                waitingFor: $viewModel.taskFormWaitingFor,
                prerequisiteTaskId: $viewModel.taskFormPrerequisiteTaskId,
                shouldPostpone: $viewModel.taskFormShouldPostpone,
                postponementDuration: $viewModel.taskFormPostponementDuration,
                editingTaskId: viewModel.editingTaskId
            )

            HStack {
                Button(viewModel.editingTaskId == nil ? language.text("保存待办", "Save Todo") : language.text("更新待办", "Update Todo")) {
                    viewModel.saveTask()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.accent)
                Button(language.text("取消", "Cancel")) {
                    viewModel.resetTaskForm()
                }
                .buttonStyle(.bordered)
                .workspaceButton()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func formField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(WorkspaceTextFieldStyle())
        }
    }

    private func multilineField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(title, text: text, axis: .vertical)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .lineLimit(2...4)
        }
    }

    private func todoDatePicker(title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacingSm) {
                Toggle(title, isOn: hasDate)
                    .labelsHidden()
                    .toggleStyle(.checkbox)

                DatePicker(language.text("日期", "Date"), selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .disabled(!hasDate.wrappedValue)
                    .opacity(hasDate.wrappedValue ? 1 : 0.45)

                DatePicker(language.text("时间", "Time"), selection: date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .disabled(!hasDate.wrappedValue)
                    .opacity(hasDate.wrappedValue ? 1 : 0.45)
            }
            .frame(height: 38)
            .padding(.horizontal, AppTheme.spacingSm)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border, lineWidth: 0.75)
            )
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.bodyFont)
            .foregroundStyle(AppTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacingXl)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}

private struct TodoTaskRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    var onToggle: () -> Void
    var onToggleToday: () -> Void
    var onEdit: () -> Void
    var onDelaySaved: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Button {
                onToggle()
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.status == .completed ? AppTheme.success : AppTheme.textSecondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(spacing: AppTheme.spacingSm) {
                    Text(task.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                        .strikethrough(task.status == .completed, color: AppTheme.textSecondary)

                    badge(task.priority.displayName, color: priorityColor)
                    if task.recurrence != .none {
                        badge(task.recurrence.displayName, color: AppTheme.secondary)
                    }
                    if task.isToday {
                        badge(language.text("关注", "Watched"), color: AppTheme.primary)
                    }

                    if let deadline = task.dueDate {
                        Text(deadline.formatted("MM/dd HH:mm"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(task.isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                    }
                }

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                TaskDependencySummary(task: task)
            }

            Spacer()

            HStack(spacing: AppTheme.spacingXs) {
                Button {
                    onToggleToday()
                } label: {
                    Image(systemName: task.isToday ? "flag.fill" : "flag")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)

                TaskDelayButton(task: task, onSaved: onDelaySaved)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private var priorityColor: Color {
        switch task.priority {
        case .urgentImportant:
            return AppTheme.danger
        case .urgent:
            return AppTheme.secondary
        case .important:
            return AppTheme.warning
        case .low:
            return AppTheme.textSecondary
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.10))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

final class TodoManagementViewModel: ObservableObject {
    @Published var stats: AppDataStore.TodoBoardStats = .init()
    @Published var tasks: [Task] = []
    @Published var hideCompletedTasks: Bool = UserDefaults.standard.bool(forKey: "Scholar.TodoTasks.HideCompleted") {
        didSet { UserDefaults.standard.set(hideCompletedTasks, forKey: "Scholar.TodoTasks.HideCompleted") }
    }

    @Published var taskFormTitle: String = ""
    @Published var taskFormDetails: String = ""
    @Published var taskFormPriority: TaskPriority = .important
    @Published var taskFormDueDate: Date = Date()
    @Published var taskFormHasDueDate: Bool = false
    @Published var taskFormRecurrence: TaskRecurrence = .none
    @Published var taskFormIsToday: Bool = false
    @Published var taskFormBlockedReason: String = ""
    @Published var taskFormWaitingFor: String = ""
    @Published var taskFormPrerequisiteTaskId: UUID? = nil
    @Published var taskFormShouldPostpone: Bool = false
    @Published var taskFormPostponementDuration: TaskPostponementDuration = .oneDay
    @Published var showTaskForm: Bool = false
    @Published var editingTaskId: UUID? = nil

    private var store: AppDataStore { AppDataStore.shared }

    var filteredTasks: [Task] {
        var result = tasks
        if hideCompletedTasks { result = result.filter { $0.status != .completed } }
        return result
    }

    func loadData() {
        stats = store.computeTodoBoardStats()
        loadTasks()
    }

    func loadTasks() {
        var all = store.tasks.filter { $0.projectId == nil && $0.thesisId == nil && $0.affairId == nil }
        if hideCompletedTasks {
            all = all.filter { $0.status != .completed }
        }
        tasks = all.sorted { a, b in
            let aDue = a.dueDate ?? .distantFuture
            let bDue = b.dueDate ?? .distantFuture
            if a.status != b.status {
                return a.status != .completed && b.status == .completed
            }
            if aDue != bDue { return aDue < bDue }
            if a.priority.rawValue != b.priority.rawValue { return a.priority.rawValue < b.priority.rawValue }
            return a.createdAt < b.createdAt
        }
    }

    func beginCreatingTask() {
        resetTaskForm()
        showTaskForm = true
    }

    func beginEditingTask(_ task: Task) {
        editingTaskId = task.id
        taskFormTitle = task.title
        taskFormDetails = task.details
        taskFormPriority = task.priority
        taskFormDueDate = task.dueDate ?? Date()
        taskFormHasDueDate = task.dueDate != nil
        taskFormRecurrence = task.recurrence
        taskFormIsToday = task.isToday
        taskFormBlockedReason = task.blockedReason
        taskFormWaitingFor = task.waitingFor
        taskFormPrerequisiteTaskId = task.prerequisiteTaskId
        showTaskForm = true
    }

    func saveTask() {
        guard taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else { return }
        let dueDate = taskFormHasDueDate ? taskFormDueDate : nil

        if let editingTaskId, let index = store.tasks.firstIndex(where: { $0.id == editingTaskId }) {
            store.tasks[index].title = taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].details = taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines)
            store.tasks[index].collaborator = "本人"
            store.tasks[index].projectId = nil
            store.tasks[index].thesisId = nil
            store.tasks[index].affairId = nil
            store.tasks[index].priority = taskFormPriority
            store.tasks[index].dueDate = dueDate
            store.tasks[index].recurrence = taskFormRecurrence
            store.tasks[index].isToday = taskFormIsToday
            store.tasks[index].updateDependencyState(blockedReason: taskFormBlockedReason, waitingFor: taskFormWaitingFor, prerequisiteTaskId: taskFormPrerequisiteTaskId)
            if taskFormShouldPostpone {
                store.tasks[index].postpone(by: taskFormPostponementDuration, reason: taskFormBlockedReason, waitingFor: taskFormWaitingFor)
            }
            store.tasks[index].updatedAt = Date()
        } else {
            var task = Task(
                title: taskFormTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                details: taskFormDetails.trimmingCharacters(in: .whitespacesAndNewlines),
                collaborator: "本人",
                projectId: nil,
                thesisId: nil,
                affairId: nil,
                priority: taskFormPriority,
                dueDate: dueDate,
                recurrence: taskFormRecurrence,
                isToday: taskFormIsToday,
                blockedReason: taskFormBlockedReason,
                waitingFor: taskFormWaitingFor,
                prerequisiteTaskId: taskFormPrerequisiteTaskId
            )
            if taskFormShouldPostpone {
                task.postpone(by: taskFormPostponementDuration, reason: taskFormBlockedReason, waitingFor: taskFormWaitingFor)
            }
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
        if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
            if store.tasks[index].status == .completed {
                store.tasks[index].status = .notStarted
                store.tasks[index].completionRate = 0
            } else {
                store.tasks[index].status = .completed
                store.tasks[index].completionRate = 100
            }
            store.tasks[index].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func toggleTaskToday(_ task: Task) {
        if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[index].isToday.toggle()
            store.tasks[index].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func resetTaskForm() {
        taskFormTitle = ""
        taskFormDetails = ""
        taskFormPriority = .important
        taskFormDueDate = Date()
        taskFormHasDueDate = false
        taskFormRecurrence = .none
        taskFormIsToday = false
        taskFormBlockedReason = ""
        taskFormWaitingFor = ""
        taskFormPrerequisiteTaskId = nil
        taskFormShouldPostpone = false
        taskFormPostponementDuration = .oneDay
        editingTaskId = nil
        showTaskForm = false
    }

}
