import SwiftUI

struct ThesisTimelineSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ThesisManagementViewModel
    @State private var selectedThesisId: UUID?
    @State private var selectedKind: ThesisTimelineKind?
    @State private var showEntryForm = false
    @State private var entryKind: ThesisTimelineKind = .log
    @State private var entryTitle = ""
    @State private var entryDetail = ""
    @State private var entryDate = Date()
    @State private var chapterProgress = 0
    @State private var showTimeline = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        timelineLauncher
            .sheet(isPresented: $showTimeline) {
                timelinePanel
                    .environmentObject(store)
                    .frame(minWidth: 780, idealWidth: 920, minHeight: 560, idealHeight: 680)
            }
    }

    private var timelineLauncher: some View {
        Button {
            showTimeline = true
        } label: {
            Label(language.text("查看时间线", "Timeline"), systemImage: "point.3.connected.trianglepath.dotted")
        }
        .buttonStyle(.borderedProminent)
        .workspaceButton()
        .tint(AppTheme.secondary)
        .controlSize(.regular)
        .disabled(viewModel.theses.isEmpty)
    }

    private var timelinePanel: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("课题时间线", "Topic Timeline"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("组会前快速回顾日志、里程碑、章节进度、任务与投稿动态。", "Review logs, milestones, chapters, tasks, and submissions before meetings."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Picker(language.text("课题", "Topic"), selection: selectedThesisBinding) {
                    ForEach(viewModel.theses) { thesis in
                        Text(thesis.title).tag(thesis.id)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
                .frame(width: 220)
                .disabled(viewModel.theses.isEmpty)

                Button {
                    showEntryForm.toggle()
                } label: {
                    Label(language.text("补充动态", "Add Update"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)
                .controlSize(.small)
                .disabled(viewModel.theses.isEmpty)

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

            HStack(spacing: AppTheme.spacingXs) {
                filterButton(language.text("全部", "All"), kind: nil)
                ForEach(ThesisTimelineKind.allCases, id: \.self) { kind in
                    filterButton(kind.title(language), kind: kind)
                }
                Spacer()
            }

            Divider()

            if timelineEntries.isEmpty {
                Text(language.text("该课题还没有时间线记录。可先补充课题日志、章节、里程碑、任务或关联成果。", "No timeline entries yet. Add topic logs, chapters, milestones, tasks, or linked outcomes."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.spacingLg)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(timelineEntries) { entry in
                        timelineRow(entry)
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
        .padding(AppTheme.spacingLg)
        .background(AppTheme.background)
        .onAppear {
            if selectedThesisId == nil {
                selectedThesisId = viewModel.selectedThesisFilter ?? viewModel.theses.first?.id
            }
        }
        .onChange(of: viewModel.theses.map(\.id)) {
            if let selectedThesisId, viewModel.theses.contains(where: { $0.id == selectedThesisId }) {
                return
            }
            selectedThesisId = viewModel.theses.first?.id
        }
    }

    private var selectedThesisBinding: Binding<UUID> {
        Binding(
            get: { selectedThesisId ?? viewModel.theses.first?.id ?? UUID() },
            set: { selectedThesisId = $0 }
        )
    }

    private var entryForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("动态类型", "Update Type"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("动态类型", "Update Type"), selection: $entryKind) {
                        Text(language.text("课题日志", "Topic Log")).tag(ThesisTimelineKind.log)
                        Text(language.text("里程碑", "Milestone")).tag(ThesisTimelineKind.milestone)
                        Text(language.text("章节进度", "Chapter Progress")).tag(ThesisTimelineKind.chapter)
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
                .frame(width: 150)

                timelineField(entryKind == .chapter ? language.text("章节名称", "Chapter Name") : language.text("标题", "Title"), text: $entryTitle)

                if entryKind == .chapter {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                        Text(language.text("进度 \(chapterProgress)%", "Progress \(chapterProgress)%"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        Slider(value: Binding(get: { Double(chapterProgress) }, set: { chapterProgress = Int($0) }), in: 0...100, step: 5)
                    }
                    .frame(width: 190)
                } else {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                        Text(language.text("日期", "Date"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        DatePicker(language.text("日期", "Date"), selection: $entryDate, displayedComponents: .date)
                            .labelsHidden()
                            .workspaceControl()
                    }
                    .frame(width: 150)
                }
            }

            if entryKind == .log {
                timelineField(language.text("进展说明", "Progress Notes"), text: $entryDetail)
            }

            HStack {
                Button(language.text("保存动态", "Save Update")) {
                    saveEntry()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)
                .controlSize(.small)
                .disabled(entryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button(language.text("取消", "Cancel")) {
                    resetEntryForm()
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)
            }
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private var selectedThesis: ThesisInfo? {
        guard let selectedThesisId else { return viewModel.theses.first }
        return viewModel.theses.first { $0.id == selectedThesisId }
    }

    private var timelineEntries: [ThesisTimelineEntry] {
        guard let thesis = selectedThesis else { return [] }
        var entries: [ThesisTimelineEntry] = []

        entries.append(.init(id: "created-\(thesis.id)", date: thesis.createdAt, kind: .created, title: language.text("创建课题", "Topic Created"), detail: thesis.title, badge: language.text("已完成", "Done")))
        entries += thesis.logs.map {
            .init(id: "log-\($0.id)", date: $0.date, kind: .log, title: $0.activityType.isEmpty ? language.text("课题日志", "Topic Log") : $0.activityType, detail: $0.notes.isEmpty ? language.text("记录了阶段性进展", "Progress update") : $0.notes)
        }
        entries += thesis.milestones.compactMap { milestone in
            guard let deadline = milestone.deadline else { return nil }
            let badge = milestone.isCompleted
                ? language.text("已完成", "Done")
                : (deadline < Date() ? language.text("已逾期", "Overdue") : language.text("待处理", "Pending"))
            return .init(id: "milestone-\(milestone.id)", date: deadline, kind: .milestone, title: milestone.name, detail: milestone.isCompleted ? language.text("里程碑已完成", "Milestone completed") : language.text("里程碑计划节点", "Planned milestone"), badge: badge)
        }
        entries += thesis.chapters.map {
            let chapterBadge: String
            if $0.progress == 100 {
                chapterBadge = language.text("已完成", "Done")
            } else if $0.progress > 0 {
                chapterBadge = language.text("跟进中 \($0.progress)%", "Progress \($0.progress)%")
            } else {
                chapterBadge = language.text("待处理", "Pending")
            }
            return .init(id: "chapter-\($0.id)", date: Date(), kind: .chapter, title: $0.name, detail: language.text("当前进度 \($0.progress)% · \($0.status.displayName)", "Current progress \($0.progress)% · \($0.status.displayName)"), badge: chapterBadge)
        }
        let thesisTasks = store.tasks.filter { $0.thesisId == thesis.id }
        entries += thesisTasks.map {
            let badge = taskStatusBadge($0)
            return .init(id: "task-\($0.id)", date: $0.updatedAt, kind: .task, title: $0.title, detail: taskDetail($0), badge: badge)
        }
        entries += thesisTasks.flatMap { task in
            task.postponementLogs.map {
                .init(id: "postponed-\($0.id)", date: $0.date, kind: .postponement, title: language.text("任务延期 · \(task.title)", "Task Postponed · \(task.title)"), detail: postponementDetail($0), badge: language.text("+\($0.days) 天", "+\($0.days)d"))
            }
        }
        for submission in (store.submissions + store.archivedData.submissions).filter({ $0.thesisId == thesis.id }) {
            entries.append(.init(id: "submission-\(submission.id)", date: submission.submissionDate ?? submission.updatedAt, kind: .submission, title: submission.name, detail: language.text("\(submission.type.displayName) · \(submission.stage.displayName)", "\(submission.type.displayName) · \(submission.stage.displayName)")))
            entries += submission.logs.map {
                .init(id: "submission-log-\($0.id)", date: $0.date, kind: .submission, title: submission.name, detail: $0.content)
            }
        }

        return entries
            .filter { selectedKind == nil || $0.kind == selectedKind }
            .sorted { $0.date > $1.date }
    }

    private func taskDetail(_ task: Task) -> String {
        if task.isBlocked {
            return language.text("任务受阻 · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)", "Blocked · \(task.blockedReason.isEmpty ? task.waitingFor : task.blockedReason)")
        }
        return language.text("任务状态 · \(task.status.displayName)", "Task · \(task.status.displayName)")
    }

    private func taskStatusBadge(_ task: Task) -> String {
        if task.status == .completed {
            return language.text("已完成", "Done")
        }
        if task.isOverdue {
            return language.text("已逾期", "Overdue")
        }
        if task.isBlocked {
            return language.text("待跟进", "Follow Up")
        }
        if task.isToday {
            return language.text("已关注", "Watched")
        }
        return language.text("待处理", "Open")
    }

    private func postponementDetail(_ log: TaskPostponementLog) -> String {
        let reason = log.blockedReason.isEmpty ? language.text("未填写阻塞原因", "No blocker reason") : log.blockedReason
        let waiting = log.waitingFor.isEmpty ? "" : language.text(" · 等待：\(log.waitingFor)", " · Waiting: \(log.waitingFor)")
        return language.text("新截止时间：\(log.newDueDate.formatted("yyyy-MM-dd HH:mm")) · \(reason)\(waiting)", "New due: \(log.newDueDate.formatted("yyyy-MM-dd HH:mm")) · \(reason)\(waiting)")
    }

    private func timelineField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(WorkspaceTextFieldStyle())
        }
        .frame(maxWidth: .infinity)
    }

    private func saveEntry() {
        guard let thesisId = selectedThesis?.id else { return }
        let title = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        switch entryKind {
        case .log:
            viewModel.addTimelineLog(to: thesisId, title: title, notes: entryDetail.trimmingCharacters(in: .whitespacesAndNewlines), date: entryDate)
        case .milestone:
            viewModel.addTimelineMilestone(to: thesisId, title: title, date: entryDate)
        case .chapter:
            viewModel.addTimelineChapter(to: thesisId, title: title, progress: chapterProgress)
        case .created, .task, .postponement, .submission:
            break
        }
        resetEntryForm()
    }

    private func resetEntryForm() {
        showEntryForm = false
        entryKind = .log
        entryTitle = ""
        entryDetail = ""
        entryDate = Date()
        chapterProgress = 0
    }

    private func filterButton(_ title: String, kind: ThesisTimelineKind?) -> some View {
        Button {
            selectedKind = kind
        } label: {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(selectedKind == kind ? AppTheme.primary : AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.spacingSm)
                .padding(.vertical, 4)
                .background(selectedKind == kind ? AppTheme.primary.opacity(0.12) : AppTheme.background)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func timelineRow(_ entry: ThesisTimelineEntry) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Text(entry.date.formatted("MM/dd"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 42, alignment: .leading)

            VStack(spacing: 0) {
                Image(systemName: timelineIcon(entry))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(timelineColor(entry))
                    .frame(width: 28, height: 28)
                    .background(timelineColor(entry).opacity(0.12))
                    .clipShape(Circle())
                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(width: 1, height: 26)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppTheme.spacingXs) {
                    Text(entry.title)
                        .font(AppTheme.bodyFont)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textPrimary)
                    if let badge = entry.badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(taskBadgeColor(badge))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(taskBadgeColor(badge).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text(entry.kind.title(language))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(entry.kind.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(entry.kind.color.opacity(0.1))
                        .clipShape(Capsule())
                }
                Text(entry.detail)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
    }

    private func taskBadgeColor(_ badge: String) -> Color {
        switch badge {
        case let s where s.contains(language.text("已完成", "Done")) || s.contains("已完成") || s.contains("Done"):
            return AppTheme.success
        case let s where s.contains(language.text("已逾期", "Overdue")) || s.contains("已逾期") || s.contains("Overdue"):
            return AppTheme.danger
        case let s where s.contains(language.text("待跟进", "Follow Up")) || s.contains("待跟进") || s.contains("Follow Up"):
            return AppTheme.warning
        case let s where s.contains(language.text("已关注", "Watched")) || s.contains("已关注") || s.contains("Watched"):
            return AppTheme.primary
        default:
            return AppTheme.accent
        }
    }

    private func timelineIcon(_ entry: ThesisTimelineEntry) -> String {
        if entry.kind == .task, let badge = entry.badge, isCompletedBadge(badge) {
            return "checkmark.circle.fill"
        }
        return entry.kind.icon
    }

    private func timelineColor(_ entry: ThesisTimelineEntry) -> Color {
        if entry.kind == .created {
            return AppTheme.success
        }
        if entry.kind == .task, let badge = entry.badge {
            return taskBadgeColor(badge)
        }
        return entry.kind.color
    }

    private func isCompletedBadge(_ badge: String) -> Bool {
        badge.contains(language.text("已完成", "Done")) || badge.contains("已完成") || badge.contains("Done")
    }
}

private struct ThesisTimelineEntry: Identifiable {
    let id: String
    let date: Date
    let kind: ThesisTimelineKind
    let title: String
    let detail: String
    var badge: String? = nil
}

private enum ThesisTimelineKind: CaseIterable {
    case created
    case log
    case milestone
    case chapter
    case task
    case postponement
    case submission

    var icon: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .log: return "note.text"
        case .milestone: return "flag.fill"
        case .chapter: return "doc.text.fill"
        case .task: return "checklist"
        case .postponement: return "clock.arrow.circlepath"
        case .submission: return "paperplane.fill"
        }
    }

    var color: Color {
        switch self {
        case .created: return AppTheme.success
        case .log: return AppTheme.primary
        case .milestone: return AppTheme.warning
        case .chapter: return AppTheme.secondary
        case .task: return AppTheme.accent
        case .postponement: return AppTheme.warning
        case .submission: return AppTheme.success
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .created: return language.text("创建", "Created")
        case .log: return language.text("日志", "Logs")
        case .milestone: return language.text("里程碑", "Milestones")
        case .chapter: return language.text("章节", "Chapters")
        case .task: return language.text("任务", "Tasks")
        case .postponement: return language.text("延期", "Delayed")
        case .submission: return language.text("投稿", "Submissions")
        }
    }
}
