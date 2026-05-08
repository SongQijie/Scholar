import SwiftUI

struct TasksSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ProjectManagementViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("项目任务", "Project Tasks"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("这里仅展示项目任务，不再和课题任务混用。", "Only project tasks are shown here, separate from thesis tasks."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.syncAllProjectTasksToReminders()
                } label: {
                    Label(
                        viewModel.isReminderSyncing ? language.text("同步中", "Syncing") : language.text("同步提醒事项", "Sync Reminders"),
                        systemImage: "checklist"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isReminderSyncing)

                Button {
                    viewModel.beginCreatingTask()
                } label: {
                    Label(language.text("新建项目任务", "New Project Task"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.secondary)
            }

            filterBar

            if !viewModel.reminderSyncMessage.isEmpty {
                HStack(spacing: AppTheme.spacingXs) {
                    Image(systemName: "bell.badge")
                    Text(viewModel.reminderSyncMessage)
                }
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.spacingSm)
                .padding(.vertical, AppTheme.spacingXs)
                .background(AppTheme.background)
                .clipShape(Capsule())
            }

            if viewModel.showTaskForm {
                taskForm
            }

            if viewModel.filteredTasks.isEmpty {
                emptyState(language.text("当前筛选条件下没有项目任务。", "No project tasks match the current filters."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.filteredTasks) { task in
                        ProjectTaskRowView(
                            task: task,
                            projectName: viewModel.projects.first { $0.id == task.projectId }?.name ?? language.text("未找到项目", "Project Not Found"),
                            onToggleComplete: { viewModel.toggleTaskCompletion(task) },
                            onToggleToday: { viewModel.toggleTaskToday(task) },
                            onEdit: { viewModel.beginEditingTask(task) },
                            onDelete: { viewModel.deleteTask(task) }
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
            Picker(language.text("项目筛选", "Project Filter"), selection: $viewModel.selectedProjectFilter) {
                Text(language.text("全部项目", "All Projects")).tag(nil as UUID?)
                ForEach(viewModel.projects) { project in
                    Text(project.name).tag(project.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .workspaceControl()

            Picker(language.text("状态筛选", "Status Filter"), selection: $viewModel.taskStatusFilter) {
                Text(language.text("全部状态", "All Statuses")).tag(nil as TaskStatus?)
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status as TaskStatus?)
                }
            }
            .pickerStyle(.menu)
            .workspaceControl()

            Toggle(language.text("显示已完成", "Show Completed"), isOn: $viewModel.showCompletedTasks)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)

            Spacer()
        }
        .onChange(of: viewModel.selectedProjectFilter) {
            viewModel.loadTasks()
        }
        .onChange(of: viewModel.taskStatusFilter) {
            viewModel.loadTasks()
        }
        .onChange(of: viewModel.showCompletedTasks) {
            viewModel.loadTasks()
        }
    }

    private var taskForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingTaskId == nil ? language.text("新建项目任务", "New Project Task") : language.text("编辑项目任务", "Edit Project Task"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSm) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("任务标题", "Task Title"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField(language.text("任务标题", "Task Title"), text: $viewModel.taskFormTitle)
                        .textFieldStyle(WorkspaceTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("所属项目", "Project"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("所属项目", "Project"), selection: $viewModel.taskFormProjectId) {
                        Text(language.text("请选择项目", "Select a Project")).tag(nil as UUID?)
                        ForEach(viewModel.projects) { project in
                            Text(project.name).tag(project.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
            }

            HStack(spacing: AppTheme.spacingSm) {
                Picker(language.text("优先级", "Priority"), selection: $viewModel.taskFormPriority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
                Picker(language.text("循环", "Recurrence"), selection: $viewModel.taskFormRecurrence) {
                    ForEach(TaskRecurrence.allCases, id: \.self) { recurrence in
                        Text(recurrence.displayName).tag(recurrence)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
            }

            DatePicker(language.text("截止时间", "Due Time"), selection: $viewModel.taskFormDueDate, displayedComponents: [.date, .hourAndMinute])
                .workspaceControl()

            HStack {
                Button(viewModel.editingTaskId == nil ? language.text("保存任务", "Save Task") : language.text("更新任务", "Update Task")) {
                    viewModel.saveTask()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.secondary)

                Button(language.text("取消", "Cancel")) {
                    viewModel.resetTaskForm()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
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

struct ProjectTaskRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    let projectName: String
    var onToggleComplete: () -> Void
    var onToggleToday: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(spacing: AppTheme.spacingSm) {
                    Text(task.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    badge(task.priority.shortName, color: Color(hex: task.priority.color))
                    badge(task.recurrence.displayName, color: AppTheme.secondary)
                }

                Text(projectName)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: AppTheme.spacingMd) {
                    meta(language.text("状态", "Status"), task.status.displayName, color: task.status == .completed ? AppTheme.success : AppTheme.textSecondary)
                    meta(language.text("截止", "Due"), task.dueDate?.formatted("MM/dd HH:mm") ?? language.text("未设", "Unset"), color: task.isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                    meta(language.text("今日推进", "Today"), task.isToday ? language.text("是", "Yes") : language.text("否", "No"), color: task.isToday ? AppTheme.warning : AppTheme.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: AppTheme.spacingXs) {
                Button {
                    onToggleToday()
                } label: {
                    Image(systemName: task.isToday ? "sun.max.fill" : "sun.max")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onToggleComplete()
                } label: {
                    Image(systemName: task.status == .completed ? "arrow.uturn.backward" : "checkmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func meta(_ title: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(AppTheme.captionFont)
                .foregroundStyle(color)
        }
    }
}
