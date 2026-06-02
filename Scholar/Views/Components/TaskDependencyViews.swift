import SwiftUI

struct TaskDependencyFormFields: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var blockedReason: String
    @Binding var waitingFor: String
    @Binding var prerequisiteTaskId: UUID?
    @Binding var shouldPostpone: Bool
    @Binding var postponementDuration: TaskPostponementDuration
    var editingTaskId: UUID?
    private var language: AppLanguage { store.appLanguage }

    private var availableTasks: [Task] {
        store.tasks
            .filter { $0.id != editingTaskId && $0.status != .completed }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Label(language.text("依赖与阻塞", "Dependencies & Blockers"), systemImage: "link.badge.plus")
                    .font(AppTheme.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.warning)
                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)
            }

            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                field(language.text("被什么阻塞", "Blocked By"), text: $blockedReason, placeholder: language.text("例如：等待实验结果", "e.g. waiting for experiment results"))
                field(language.text("等待谁反馈", "Waiting For"), text: $waitingFor, placeholder: language.text("例如：导师、合作者", "e.g. advisor, collaborator"))

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("前置任务", "Prerequisite Task"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("前置任务", "Prerequisite Task"), selection: $prerequisiteTaskId) {
                        Text(language.text("无", "None")).tag(nil as UUID?)
                        ForEach(availableTasks) { task in
                            Text("\(task.ownerLabel) · \(task.title)").tag(task.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
                .frame(maxWidth: .infinity)
            }

            TaskPostponementControls(
                shouldPostpone: $shouldPostpone,
                duration: $postponementDuration
            )
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.warning.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.warning.opacity(0.16), lineWidth: 0.75)
        )
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(WorkspaceTextFieldStyle())
        }
        .frame(maxWidth: .infinity)
    }
}

struct TaskPostponementControls: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var shouldPostpone: Bool
    @Binding var duration: TaskPostponementDuration
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Toggle(language.text("需要延期", "Postpone Deadline"), isOn: $shouldPostpone)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            Picker(language.text("延期时长", "Duration"), selection: $duration) {
                ForEach(TaskPostponementDuration.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .workspaceControl()
            .frame(width: 150)
            .disabled(!shouldPostpone)
            .opacity(shouldPostpone ? 1 : 0.45)

            Text(language.text("勾选后会调整截止时间，并写入时间线。", "Updates the deadline and adds a timeline entry."))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}

struct TaskDelayButton: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    var onSaved: () -> Void = {}
    @State private var showSheet = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "clock.arrow.circlepath")
        }
        .buttonStyle(.bordered)
        .workspaceButton()
        .controlSize(.small)
        .help(language.text("记录阻塞与延期", "Record Blocker and Delay"))
        .sheet(isPresented: $showSheet) {
            TaskDelaySheet(task: task, onSaved: onSaved)
                .environmentObject(store)
        }
    }
}

private struct TaskDelaySheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let task: Task
    let onSaved: () -> Void
    @State private var blockedReason: String
    @State private var waitingFor: String
    @State private var prerequisiteTaskId: UUID?
    @State private var shouldPostpone = false
    @State private var duration: TaskPostponementDuration = .oneDay
    @State private var errorMessage: String?
    private var language: AppLanguage { store.appLanguage }

    init(task: Task, onSaved: @escaping () -> Void) {
        self.task = task
        self.onSaved = onSaved
        _blockedReason = State(initialValue: task.blockedReason)
        _waitingFor = State(initialValue: task.waitingFor)
        _prerequisiteTaskId = State(initialValue: task.prerequisiteTaskId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("记录阻塞与延期", "Record Blocker and Delay"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(task.title)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
            }

            TaskDependencyFormFields(
                blockedReason: $blockedReason,
                waitingFor: $waitingFor,
                prerequisiteTaskId: $prerequisiteTaskId,
                shouldPostpone: $shouldPostpone,
                postponementDuration: $duration,
                editingTaskId: task.id
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
            }

            HStack {
                Spacer()
                Button(language.text("取消", "Cancel")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .workspaceButton()

                Button(language.text("保存记录", "Save Record")) {
                    if let errorMessage = store.updateTaskBlocker(
                        taskId: task.id,
                        blockedReason: blockedReason,
                        waitingFor: waitingFor,
                        prerequisiteTaskId: prerequisiteTaskId,
                        shouldPostpone: shouldPostpone,
                        duration: duration
                    ) {
                        self.errorMessage = errorMessage
                        return
                    }
                    onSaved()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.warning)
            }
        }
        .padding(AppTheme.spacingLg)
        .frame(width: 720)
        .background(AppTheme.background)
    }
}

struct TaskDependencySummary: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    private var language: AppLanguage { store.appLanguage }

    private var prerequisiteTitle: String? {
        guard let prerequisiteTaskId = task.prerequisiteTaskId else { return nil }
        return store.tasks.first { $0.id == prerequisiteTaskId }?.title
    }

    var body: some View {
        if task.isBlocked || prerequisiteTitle != nil {
            HStack(spacing: AppTheme.spacingSm) {
                if task.isBlocked {
                    Label(language.text("阻塞", "Blocked"), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.warning)
                    if !task.blockedReason.isEmpty {
                        Text(task.blockedReason)
                    }
                    if !task.waitingFor.isEmpty {
                        Text(language.text("等待：\(task.waitingFor)", "Waiting: \(task.waitingFor)"))
                    }
                }
                if let prerequisiteTitle {
                    Label(language.text("前置：\(prerequisiteTitle)", "Prerequisite: \(prerequisiteTitle)"), systemImage: "link")
                        .foregroundStyle(AppTheme.secondary)
                }
            }
            .font(AppTheme.captionFont)
            .foregroundStyle(AppTheme.textSecondary)
            .lineLimit(1)
        }
    }
}
