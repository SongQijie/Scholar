import SwiftUI
import Combine

struct TodayExecutionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: OverviewViewModel
    @State private var localTaskTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack {
                Text(language.text("今日执行", "Today's Execution"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(language.text("进行中 \(viewModel.inProgressTasks.count)", "In Progress \(viewModel.inProgressTasks.count)"))
                    .font(AppTheme.captionFont)
                    .padding(.horizontal, AppTheme.spacingSm)
                    .padding(.vertical, 2)
                    .background(AppTheme.primary.opacity(0.1))
                    .foregroundStyle(AppTheme.primary)
                    .clipShape(Capsule())
            }

            // New task button
            if !viewModel.showNewTaskField {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showNewTaskField = true
                    }
                } label: {
                    Label(language.text("新增临时任务", "New Quick Task"), systemImage: "plus")
                        .font(AppTheme.captionFont)
                        .padding(.horizontal, AppTheme.spacingSm)
                        .padding(.vertical, AppTheme.spacingXs)
                        .background(AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    TextField(language.text("任务名称", "Task Title"), text: $localTaskTitle)
                        .textFieldStyle(WorkspaceTextFieldStyle())
                        .focused($isTextFieldFocused)
                        .onAppear {
                            // 延迟设置焦点，避免与视图刷新冲突
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true
                            }
                        }
                        .onSubmit {
                            submitTask()
                        }
                    Button(language.text("添加", "Add")) {
                        submitTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    Button(language.text("取消", "Cancel")) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showNewTaskField = false
                            localTaskTitle = ""
                            isTextFieldFocused = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            // Task list
            if viewModel.todayTasks.isEmpty {
                Text(language.text("暂无今日任务", "No tasks for today"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                ForEach(viewModel.todayTasks) { task in
                    TaskRowView(task: task) {
                        viewModel.startTask(task)
                    } onEnd: {
                        viewModel.endTask(task)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func submitTask() {
        guard localTaskTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        viewModel.newTaskTitle = localTaskTitle
        viewModel.addTemporaryTask()
        localTaskTitle = ""
        isTextFieldFocused = false
    }
}

struct TaskRowView: View {
    let task: Task
    var onStart: () -> Void
    var onEnd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppTheme.spacingXs) {
                    Text(task.priority.displayName)
                        .font(.system(size: 10))
                        .padding(.horizontal, AppTheme.spacingXs)
                        .padding(.vertical, 1)
                        .background(Color(hex: task.priority.color).opacity(0.1))
                        .foregroundStyle(Color(hex: task.priority.color))
                        .clipShape(Capsule())

                    if let due = task.dueDate {
                        Text(due.formatted("MM/dd"))
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            Spacer()

            switch task.status {
            case .notStarted:
                Button(AppLanguage.storedPreference.text("开始", "Start")) {
                    onStart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            case .inProgress:
                Button(AppLanguage.storedPreference.text("结束", "End")) {
                    onEnd()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.success)
                .controlSize(.small)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.success)
            }
        }
        .padding(.horizontal, AppTheme.spacingSm)
        .padding(.vertical, AppTheme.spacingXs)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}
