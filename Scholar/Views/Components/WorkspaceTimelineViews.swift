import SwiftUI

struct ProjectTimelineSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ProjectManagementViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        WorkspaceTimelineLauncher(
            title: language.text("项目时间线", "Project Timeline"),
            subtitle: language.text("悬浮查看项目节点、任务变化和补充动态。", "Open a floating view for project milestones, tasks, and updates."),
            options: viewModel.projects.map { .init(id: $0.id, title: $0.name) },
            entriesFor: projectEntries,
            addLog: { viewModel.addTimelineLog(to: $0, title: $1, details: $2, date: $3) }
        )
    }

    private func projectEntries(_ id: UUID) -> [WorkspaceTimelineEntry] {
        guard let project = store.projects.first(where: { $0.id == id }) else { return [] }
        var entries = project.timelineLogs.map {
            WorkspaceTimelineEntry(id: "log-\($0.id)", date: $0.date, title: $0.title, detail: $0.details, icon: "note.text", color: AppTheme.primary)
        }
        entries.append(.init(id: "created-\(id)", date: project.createdAt, title: language.text("创建项目", "Project Created"), detail: project.name, icon: "plus.circle.fill", color: AppTheme.success, badge: language.text("已完成", "Done")))
        if let deadline = project.deadline {
            let ddlBadge = deadline < Date() ? language.text("已逾期", "Overdue") : language.text("待处理", "Pending")
            entries.append(.init(id: "deadline-\(id)", date: deadline, title: language.text("项目 DDL", "Project DDL"), detail: project.name, icon: "flag.fill", color: AppTheme.warning, badge: ddlBadge))
        }
        let projectTasks = store.tasks.filter { $0.projectId == id }
        entries += projectTasks.map {
            .init(id: "task-\($0.id)", date: $0.updatedAt, title: $0.title, detail: taskDetail($0), icon: taskIcon($0), color: taskBadge($0).color, badge: taskBadge($0).text)
        }
        entries += projectTasks.flatMap(postponementEntries)
        return entries.sorted { $0.date > $1.date }
    }

    private func taskDetail(_ task: Task) -> String {
        task.isBlocked ? language.text("任务受阻 · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)", "Blocked · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)") : language.text("任务状态 · \(task.status.displayName)", "Task · \(task.status.displayName)")
    }

    private func taskBadge(_ task: Task) -> (text: String, color: Color) {
        timelineTaskBadge(task, language: language)
    }

    private func taskIcon(_ task: Task) -> String {
        task.status == .completed ? "checkmark.circle.fill" : "checklist"
    }

    private func postponementEntries(_ task: Task) -> [WorkspaceTimelineEntry] {
        task.postponementLogs.map {
            .init(id: "postponed-\($0.id)", date: $0.date, title: language.text("任务延期 · \(task.title)", "Task Postponed · \(task.title)"), detail: postponementDetail($0, language: language), icon: "clock.arrow.circlepath", color: AppTheme.warning, badge: language.text("+\($0.days) 天", "+\($0.days)d"))
        }
    }
}

struct AffairTimelineSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: AffairManagementViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        WorkspaceTimelineLauncher(
            title: language.text("事务时间线", "Affair Timeline"),
            subtitle: language.text("悬浮查看事务节点、关联任务和补充动态。", "Open a floating view for affair milestones, tasks, and updates."),
            options: viewModel.affairs.map { .init(id: $0.id, title: $0.sectionTitle) },
            entriesFor: affairEntries,
            addLog: { viewModel.addTimelineLog(to: $0, title: $1, details: $2, date: $3) }
        )
    }

    private func affairEntries(_ id: UUID) -> [WorkspaceTimelineEntry] {
        guard let affair = store.affairs.first(where: { $0.id == id }) else { return [] }
        var entries = affair.timelineLogs.map {
            WorkspaceTimelineEntry(id: "log-\($0.id)", date: $0.date, title: $0.title, detail: $0.details, icon: "note.text", color: AppTheme.primary)
        }
        entries.append(.init(id: "created-\(id)", date: affair.createdAt, title: language.text("创建事务", "Affair Created"), detail: affair.title, icon: "plus.circle.fill", color: AppTheme.success, badge: language.text("已完成", "Done")))
        if let dueDate = affair.dueDate {
            let ddlBadge = dueDate < Date() ? language.text("已逾期", "Overdue") : language.text("待处理", "Pending")
            entries.append(.init(id: "deadline-\(id)", date: dueDate, title: language.text("事务 DDL", "Affair DDL"), detail: affair.title, icon: "flag.fill", color: AppTheme.warning, badge: ddlBadge))
        }
        let affairTasks = store.tasks.filter { $0.affairId == id }
        entries += affairTasks.map {
            .init(id: "task-\($0.id)", date: $0.updatedAt, title: $0.title, detail: taskDetail($0), icon: taskIcon($0), color: taskBadge($0).color, badge: taskBadge($0).text)
        }
        entries += affairTasks.flatMap(postponementEntries)
        return entries.sorted { $0.date > $1.date }
    }

    private func taskDetail(_ task: Task) -> String {
        task.isBlocked ? language.text("任务受阻 · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)", "Blocked · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)") : language.text("任务状态 · \(task.status.displayName)", "Task · \(task.status.displayName)")
    }

    private func taskBadge(_ task: Task) -> (text: String, color: Color) {
        timelineTaskBadge(task, language: language)
    }

    private func taskIcon(_ task: Task) -> String {
        task.status == .completed ? "checkmark.circle.fill" : "checklist"
    }

    private func postponementEntries(_ task: Task) -> [WorkspaceTimelineEntry] {
        task.postponementLogs.map {
            .init(id: "postponed-\($0.id)", date: $0.date, title: language.text("任务延期 · \(task.title)", "Task Postponed · \(task.title)"), detail: postponementDetail($0, language: language), icon: "clock.arrow.circlepath", color: AppTheme.warning, badge: language.text("+\($0.days) 天", "+\($0.days)d"))
        }
    }
}

private func postponementDetail(_ log: TaskPostponementLog, language: AppLanguage) -> String {
    let dueDate = log.newDueDate.formatted("yyyy-MM-dd HH:mm")
    let reason = log.blockedReason.isEmpty ? language.text("未填写阻塞原因", "No blocker reason") : log.blockedReason
    let waiting = log.waitingFor.isEmpty ? "" : language.text(" · 等待：\(log.waitingFor)", " · Waiting: \(log.waitingFor)")
    return language.text("新截止时间：\(dueDate) · \(reason)\(waiting)", "New due: \(dueDate) · \(reason)\(waiting)")
}

private struct WorkspaceTimelineLauncher: View {
    @EnvironmentObject private var store: AppDataStore
    let title: String
    let subtitle: String
    let options: [WorkspaceTimelineOption]
    let entriesFor: (UUID) -> [WorkspaceTimelineEntry]
    let addLog: (UUID, String, String, Date) -> Void
    @State private var showTimeline = false
    @State private var selectedId: UUID?
    @State private var showEntryForm = false
    @State private var entryTitle = ""
    @State private var entryDetails = ""
    @State private var entryDate = Date()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        Button {
            selectedId = selectedId ?? options.first?.id
            showTimeline = true
        } label: {
            Label(language.text("查看时间线", "Timeline"), systemImage: "point.3.connected.trianglepath.dotted")
        }
        .buttonStyle(.borderedProminent)
        .workspaceButton()
        .tint(AppTheme.secondary)
        .controlSize(.regular)
        .disabled(options.isEmpty)
        .sheet(isPresented: $showTimeline) {
            timelinePanel
                .environmentObject(store)
                .frame(minWidth: 720, idealWidth: 860, minHeight: 520, idealHeight: 640)
        }
    }

    private var timelinePanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(title).font(AppTheme.subtitleFont).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Picker(title, selection: selectedBinding) {
                    ForEach(options) { option in Text(option.title).tag(option.id) }
                }
                .pickerStyle(.menu)
                .workspaceControl()
                .frame(width: 240)
                Button {
                    showEntryForm.toggle()
                } label: {
                    Label(language.text("补充动态", "Add Update"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)
                .controlSize(.small)

                Button {
                    showTimeline = false
                } label: {
                    Label(language.text("返回", "Back"), systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)
            }

            if showEntryForm {
                entryForm
            }

            Divider()
            ScrollView {
                if entries.isEmpty {
                    Text(language.text("暂时没有时间线记录。", "No timeline entries yet."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppTheme.spacingLg)
                } else {
                    VStack(spacing: 0) {
                        ForEach(entries) { entry in
                            timelineRow(entry)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.background)
    }

    private var entryForm: some View {
        VStack(spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                TextField(language.text("动态标题", "Update Title"), text: $entryTitle)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                DatePicker(language.text("日期", "Date"), selection: $entryDate, displayedComponents: .date)
                    .labelsHidden()
                    .workspaceControl()
            }
            TextField(language.text("补充说明", "Details"), text: $entryDetails)
                .textFieldStyle(WorkspaceTextFieldStyle())
            HStack {
                Button(language.text("保存动态", "Save Update")) { saveEntry() }
                    .buttonStyle(.borderedProminent)
                .workspaceButton()
                    .tint(AppTheme.primary)
                    .controlSize(.small)
                    .disabled(entryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(language.text("取消", "Cancel")) { resetEntryForm() }
                    .buttonStyle(.bordered)
                .workspaceButton()
                    .controlSize(.small)
                Spacer()
            }
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private var selectedBinding: Binding<UUID> {
        Binding(get: { selectedId ?? options.first?.id ?? UUID() }, set: { selectedId = $0 })
    }

    private var entries: [WorkspaceTimelineEntry] {
        guard let id = selectedId ?? options.first?.id else { return [] }
        return entriesFor(id)
    }

    private func saveEntry() {
        guard let id = selectedId ?? options.first?.id else { return }
        let title = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        addLog(id, title, entryDetails.trimmingCharacters(in: .whitespacesAndNewlines), entryDate)
        resetEntryForm()
    }

    private func resetEntryForm() {
        showEntryForm = false
        entryTitle = ""
        entryDetails = ""
        entryDate = Date()
    }

    private func timelineRow(_ entry: WorkspaceTimelineEntry) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Text(entry.date.formatted("MM/dd"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 42, alignment: .leading)
            VStack(spacing: 0) {
                Image(systemName: entry.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(entry.color)
                    .frame(width: 28, height: 28)
                    .background(entry.color.opacity(0.12))
                    .clipShape(Circle())
                Rectangle().fill(AppTheme.divider).frame(width: 1, height: 26)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppTheme.spacingXs) {
                    Text(entry.title).font(AppTheme.bodyFont).fontWeight(.medium).foregroundStyle(AppTheme.textPrimary)
                    if let badge = entry.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(entry.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(entry.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if !entry.detail.isEmpty {
                    Text(entry.detail).font(AppTheme.captionFont).foregroundStyle(AppTheme.textSecondary).lineLimit(2)
                }
            }
            Spacer()
        }
    }
}

private struct WorkspaceTimelineOption: Identifiable {
    let id: UUID
    let title: String
}

private struct WorkspaceTimelineEntry: Identifiable {
    let id: String
    let date: Date
    let title: String
    let detail: String
    let icon: String
    let color: Color
    var badge: String? = nil
}

private func timelineTaskBadge(_ task: Task, language: AppLanguage) -> (text: String, color: Color) {
    if task.status == .completed {
        return (language.text("已完成", "Done"), AppTheme.success)
    }
    if task.isOverdue {
        return (language.text("已逾期", "Overdue"), AppTheme.danger)
    }
    if task.isBlocked {
        return (language.text("待跟进", "Follow Up"), AppTheme.warning)
    }
    if task.isToday {
        return (language.text("已关注", "Watched"), AppTheme.primary)
    }
    return (language.text("待处理", "Open"), AppTheme.accent)
}
