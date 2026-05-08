import SwiftUI

struct ThesisTasksSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ThesisManagementViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("课题任务", "Thesis Tasks"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("这里仅展示课题任务，和项目任务彻底分开。", "Only thesis tasks are shown here, completely separate from project tasks."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if viewModel.selectedThesisFilter != nil {
                    Button(language.text("全部任务", "All Tasks")) {
                        viewModel.selectedThesisFilter = nil
                        viewModel.loadTasks()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Button {
                    viewModel.syncAllThesisTasksToReminders()
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
                    Label(language.text("新建课题任务", "New Thesis Task"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
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
                emptyState(language.text("当前筛选条件下没有课题任务。", "No thesis tasks match the current filters."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.filteredTasks) { task in
                        ThesisTaskRowView(
                            task: task,
                            thesisTitle: viewModel.theses.first { $0.id == task.thesisId }?.title ?? language.text("未找到课题", "Thesis Not Found"),
                            onToggle: { viewModel.toggleTaskCompletion(task) },
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
            Picker(language.text("课题筛选", "Thesis Filter"), selection: $viewModel.selectedThesisFilter) {
                Text(language.text("全部课题", "All Theses")).tag(nil as UUID?)
                ForEach(viewModel.theses) { thesis in
                    Text(thesis.title).tag(thesis.id as UUID?)
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
        .onChange(of: viewModel.selectedThesisFilter) {
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
                Text(viewModel.editingTaskId == nil ? language.text("新建课题任务", "New Thesis Task") : language.text("编辑课题任务", "Edit Thesis Task"))
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
                    Text(language.text("所属课题", "Thesis"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("所属课题", "Thesis"), selection: $viewModel.taskFormThesisId) {
                        Text(language.text("请选择课题", "Select a Thesis")).tag(nil as UUID?)
                        ForEach(viewModel.theses) { thesis in
                            Text(thesis.title).tag(thesis.id as UUID?)
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
                .tint(AppTheme.accent)

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

struct ThesisTaskRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    let thesisTitle: String
    var onToggle: () -> Void
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
                    badge(task.recurrence.displayName, color: AppTheme.accent)
                }

                Text(thesisTitle)
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
                    onToggle()
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
