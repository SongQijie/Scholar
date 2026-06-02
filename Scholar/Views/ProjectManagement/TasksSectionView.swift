import SwiftUI

struct TasksSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ProjectManagementViewModel
    @State private var taskToDelete: Task?
    @State private var showDeleteConfirmation = false
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
                    viewModel.beginCreatingTask()
                } label: {
                    Label(language.text("新建项目任务", "New Project Task"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.secondary)
            }

            filterBar

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
                            onDelaySaved: { viewModel.loadData() },
                            onDelete: {
                                taskToDelete = task
                                showDeleteConfirmation = true
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
        .alert(language.text("删除任务", "Delete Task"), isPresented: $showDeleteConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let task = taskToDelete {
                    viewModel.deleteTask(task)
                }
                taskToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个任务吗？", "Delete this task?"))
        }
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

            Toggle(language.text("隐藏已完成", "Hide Completed"), isOn: $viewModel.hideCompletedTasks)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)

            Spacer()
        }
        .onChange(of: viewModel.selectedProjectFilter) {
            viewModel.loadTasks()
        }
        .onChange(of: viewModel.hideCompletedTasks) {
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

            formField(language.text("任务标题", "Task Title"), text: $viewModel.taskFormTitle)

            HStack(spacing: AppTheme.spacingSm) {
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

                optionalDatePicker(
                    title: language.text("截止时间", "Due Time"),
                    hasDate: $viewModel.taskFormHasDueDate,
                    date: $viewModel.taskFormDueDate
                )

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("关注", "Watched"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Toggle(language.text("关注", "Watched"), isOn: $viewModel.taskFormIsToday)
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                        .frame(height: 38)
                }
            }

            multilineField(language.text("任务详情", "Details"), text: $viewModel.taskFormDetails)

            TaskDependencyFormFields(
                blockedReason: $viewModel.taskFormBlockedReason,
                waitingFor: $viewModel.taskFormWaitingFor,
                prerequisiteTaskId: $viewModel.taskFormPrerequisiteTaskId,
                shouldPostpone: $viewModel.taskFormShouldPostpone,
                postponementDuration: $viewModel.taskFormPostponementDuration,
                editingTaskId: viewModel.editingTaskId
            )

            HStack {
                Button(viewModel.editingTaskId == nil ? language.text("保存任务", "Save Task") : language.text("更新任务", "Update Task")) {
                    viewModel.saveTask()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.secondary)

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

    private func optionalDatePicker(title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Toggle(title, isOn: hasDate)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacingXs) {
                DatePicker(language.text("日期", "Date"), selection: date, displayedComponents: .date)
                    .labelsHidden()
                DatePicker(language.text("时间", "Time"), selection: date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .workspaceControl()
            .disabled(!hasDate.wrappedValue)
            .opacity(hasDate.wrappedValue ? 1 : 0.45)
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

struct ProjectTaskRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    let projectName: String
    var onToggleComplete: () -> Void
    var onToggleToday: () -> Void
    var onEdit: () -> Void
    var onDelaySaved: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.status == .completed ? AppTheme.success : AppTheme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(spacing: AppTheme.spacingSm) {
                    Text(task.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(task.status == .completed ? AppTheme.textTertiary : AppTheme.textPrimary)
                        .strikethrough(task.status == .completed, color: AppTheme.textTertiary)
                        .lineLimit(1)
                    badge(task.priority.displayName, color: Color(hex: task.priority.color))
                    if task.recurrence != .none {
                        badge(task.recurrence.displayName, color: AppTheme.secondary)
                    }
                    if task.isToday {
                        badge(language.text("关注", "Watched"), color: AppTheme.warning)
                    }
                }

                Text(projectName)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack(spacing: AppTheme.spacingMd) {
                    meta(language.text("截止", "Due"), task.dueDate?.formatted("MM/dd HH:mm") ?? language.text("未设", "Unset"), color: task.isOverdue ? AppTheme.danger : AppTheme.textSecondary)
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
