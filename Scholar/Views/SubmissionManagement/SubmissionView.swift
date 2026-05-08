import SwiftUI
import AppKit

struct SubmissionView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = SubmissionViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                statisticsSection
                    .fadeIn(delay: 0.1)

                submissionBoard
                    .fadeIn(delay: 0.15)

                archiveSection
                    .fadeIn(delay: 0.2)

                if viewModel.selectedSubmission != nil {
                    submissionLogSection
                        .fadeIn(delay: 0.25)
                }
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("成果管理", "Submissions"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("追踪论文投稿与专利申请进度", "Track paper submissions and patent applications"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        ModernCard {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingMd) {
                    StatCard(
                        title: language.text("投稿总数", "Total"),
                        value: "\(viewModel.stats.totalCount)",
                        icon: "paperplane.fill",
                        color: AppTheme.primary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("进行中", "Active"),
                        value: "\(viewModel.stats.activeCount)",
                        icon: "hourglass",
                        color: AppTheme.secondary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("已发表", "Published"),
                        value: "\(viewModel.stats.publishedCount)",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("已拒绝", "Rejected"),
                        value: "\(viewModel.stats.rejectedCount)",
                        icon: "xmark.octagon.fill",
                        color: AppTheme.danger
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("本周新增", "New This Week"),
                        value: "\(viewModel.stats.newThisPeriod)",
                        icon: "plus.circle.fill",
                        color: AppTheme.warning
                    )
                    .hoverScale(1.02)
                }
                .padding(.vertical, AppTheme.spacingXs)
            }
        }
    }

    // MARK: - Submission Board

    private var submissionBoard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("投稿流程看板", "Submission Board"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.showNewSubmissionForm.toggle()
                } label: {
                    Label(language.text("添加投稿项目", "Add Submission"), systemImage: "plus")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .controlSize(.small)
            }

            if viewModel.showNewSubmissionForm {
                newSubmissionForm
            }

            if viewModel.activeSubmissions.isEmpty {
                Text(language.text("暂无进行中的投稿项目", "No active submissions"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingLg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                        ForEach(activeStages, id: \.self) { stage in
                            stageColumn(for: stage)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var activeStages: [SubmissionStage] {
        SubmissionStage.allCases.filter { $0.isActive }
    }

    private var newSubmissionForm: some View {
        VStack(spacing: AppTheme.spacingSm) {
            TextField(language.text("投稿名称", "Submission Title"), text: $viewModel.newSubmissionName)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .font(AppTheme.bodyFont)
            Picker(language.text("成果类型", "Outcome Type"), selection: $viewModel.newOutcomeType) {
                ForEach(ResearchOutcomeType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .workspaceSegmented()
            TextField(targetLabelPlaceholder, text: $viewModel.newTargetJournal)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .font(AppTheme.bodyFont)
            HStack {
                TextField(identifierPlaceholder, text: $viewModel.newTargetIdentifier)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .font(AppTheme.bodyFont)
                TextField(language.text("合作者 / 单位", "Collaborators / Organization"), text: $viewModel.newCollaborators)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .font(AppTheme.bodyFont)
            }

            if viewModel.newOutcomeType == .paper {
                paperFields
                TextField(language.text("成果摘要", "Summary"), text: $viewModel.newSubmissionSummary, axis: .vertical)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .font(AppTheme.bodyFont)
                    .lineLimit(2...4)
            }

            if viewModel.newOutcomeType == .patent {
                patentFields
            }

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack {
                    Text(language.text("待归档附件 \(viewModel.pendingAttachmentURLs.count) 个", "Pending attachments: \(viewModel.pendingAttachmentURLs.count)"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Button(language.text("添加附件", "Add Attachment")) {
                        importAttachmentForDraft()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if !viewModel.pendingAttachmentURLs.isEmpty {
                    ForEach(viewModel.pendingAttachmentURLs, id: \.self) { url in
                        Text(url.lastPathComponent)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            HStack {
                Button(language.text("添加", "Add")) {
                    viewModel.addSubmission()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .controlSize(.small)
                .disabled(viewModel.newSubmissionName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button(language.text("取消", "Cancel")) {
                    viewModel.showNewSubmissionForm = false
                    viewModel.newSubmissionName = ""
                    viewModel.newOutcomeType = .paper
                    viewModel.newTargetJournal = ""
                    viewModel.newTargetIdentifier = ""
                    viewModel.newCollaborators = ""
                    viewModel.newSubmissionSummary = ""
                    viewModel.newCCFGrade = .none
                    viewModel.newSCIGrade = .none
                    viewModel.newIsEI = false
                    viewModel.newIsCorrespondingAuthor = false
                    viewModel.newAuthors = ""
                    viewModel.newAuthorOrder = ""
                    viewModel.newPatentStatus = .submitted
                    viewModel.newRelatedStudents = ""
                    viewModel.pendingAttachmentURLs = []
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.textSecondary)
                .controlSize(.small)
                Spacer()
            }
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private var paperFields: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Picker("CCF", selection: $viewModel.newCCFGrade) {
                    ForEach(CCFGrade.allCases, id: \.self) { grade in
                        Text(grade.displayName).tag(grade)
                    }
                }
                .pickerStyle(.segmented)
                .workspaceSegmented()

                Picker("SCI", selection: $viewModel.newSCIGrade) {
                    ForEach(SCIGrade.allCases, id: \.self) { grade in
                        Text(grade.displayName).tag(grade)
                    }
                }
                .pickerStyle(.segmented)
                .workspaceSegmented()
            }

            HStack(spacing: AppTheme.spacingMd) {
                Toggle("EI", isOn: $viewModel.newIsEI)
                Toggle(language.text("通讯作者", "Corresponding Author"), isOn: $viewModel.newIsCorrespondingAuthor)
                TextField(language.text("第几作者", "Author Order"), text: $viewModel.newAuthorOrder)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .frame(width: 100)
                Spacer()
            }
            .font(AppTheme.bodyFont)

            TextField(language.text("作者（按论文顺序填写）", "Authors (paper order)"), text: $viewModel.newAuthors)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .font(AppTheme.bodyFont)
        }
    }

    private var patentFields: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Picker(language.text("专利状态", "Patent Status"), selection: $viewModel.newPatentStatus) {
                ForEach(PatentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .pickerStyle(.segmented)
            .workspaceSegmented()

            TextField(language.text("关联学生（逗号分隔）", "Related Students (comma separated)"), text: $viewModel.newRelatedStudents)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .font(AppTheme.bodyFont)
        }
    }

    private func stageColumn(for stage: SubmissionStage) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack {
                Text(stage.displayName)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(submissionsInStage(stage).count)")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.spacingXs)
                    .padding(.vertical, 2)
                    .background(AppTheme.background)
                    .clipShape(Capsule())
            }
            .padding(.bottom, AppTheme.spacingXs)

            if submissionsInStage(stage).isEmpty {
                Text(language.text("暂无", "Empty"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingSm)
            } else {
                ForEach(submissionsInStage(stage)) { submission in
                    submissionCard(submission)
                }
            }
        }
        .frame(width: 220)
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func submissionsInStage(_ stage: SubmissionStage) -> [Submission] {
        viewModel.activeSubmissions.filter { $0.stage == stage }
    }

    private func submissionCard(_ submission: Submission) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            HStack {
                Text(submission.name)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(submission.type.displayName)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
            }
            Text(submission.targetJournal.isEmpty ? language.text("未指定目标单位", "No target specified") : submission.targetJournal)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
            if !submission.targetIdentifier.isEmpty {
                Text(submission.targetIdentifier)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            metadataTags(for: submission)
            if !submission.summary.isEmpty {
                Text(submission.summary)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            Text(submission.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textTertiary)
            if !submission.attachments.isEmpty {
                Text(language.text("附件 \(submission.attachments.count) 个", "\(submission.attachments.count) attachments"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Divider()

            HStack(spacing: AppTheme.spacingXs) {
                if viewModel.nextStage(for: submission.stage) != nil {
                    Button {
                        if let next = viewModel.nextStage(for: submission.stage) {
                            viewModel.updateSubmissionStage(submission, stage: next)
                        }
                    } label: {
                        Label(language.text("推进", "Advance"), systemImage: "arrow.right")
                            .font(AppTheme.captionFont)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.success)
                    .controlSize(.mini)
                }

                if submission.type == .patent {
                    Menu {
                        ForEach(PatentStatus.allCases, id: \.self) { status in
                            Button(status.displayName) {
                                viewModel.updatePatentStatus(submission, status: status)
                            }
                        }
                    } label: {
                        Label(language.text("状态", "Status"), systemImage: "tag")
                            .font(AppTheme.captionFont)
                    }
                    .menuStyle(.borderlessButton)
                    .controlSize(.mini)
                }

                Button {
                    viewModel.selectedSubmissionId = submission.id
                } label: {
                    Label(language.text("日志", "Logs"), systemImage: "doc.text")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.secondary)
                .controlSize(.mini)

                Button {
                    viewModel.updateSubmissionStage(submission, stage: .rejected)
                } label: {
                    Label(language.text("拒绝", "Reject"), systemImage: "xmark")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.danger)
                .controlSize(.mini)

                Button(role: .destructive) {
                    viewModel.deleteSubmission(submission)
                } label: {
                    Label(language.text("删除", "Delete"), systemImage: "trash")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.textTertiary)
                .controlSize(.mini)
            }
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func metadataTags(for submission: Submission) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingXs) {
                if submission.type == .paper {
                    if submission.ccfGrade != .none {
                        compactTag(submission.ccfGrade.displayName, color: AppTheme.primary)
                    }
                    if submission.sciGrade != .none {
                        compactTag(submission.sciGrade.displayName, color: AppTheme.secondary)
                    }
                    if submission.isEI {
                        compactTag("EI", color: AppTheme.success)
                    }
                    if submission.isCorrespondingAuthor {
                        compactTag(language.text("通讯", "Corr."), color: AppTheme.warning)
                    }
                    if let authorOrder = submission.authorOrder {
                        compactTag(language.text("第 \(authorOrder) 作者", "Author \(authorOrder)"), color: AppTheme.textSecondary)
                    }
                    if !submission.authors.isEmpty {
                        compactTag(submission.authors, color: AppTheme.textSecondary)
                    }
                }

                if submission.type == .patent {
                    compactTag(submission.patentStatus.displayName, color: AppTheme.primary)
                    ForEach(submission.relatedStudents, id: \.self) { student in
                        compactTag(student, color: AppTheme.secondary)
                    }
                }
            }
        }
    }

    private func compactTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    // MARK: - Archive

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            Text(language.text("成果归档", "Archive"))
                .font(AppTheme.subtitleFont)
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.archivedSubmissions.isEmpty {
                Text(language.text("暂无归档成果", "No archived outcomes"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                ForEach(viewModel.archivedSubmissions) { submission in
                    archiveRow(submission)
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func archiveRow(_ submission: Submission) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(submission.name)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(submission.targetJournal.isEmpty ? language.text("未指定目标单位", "No target specified") : submission.targetJournal)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            stageTag(submission.stage)
            Text(submission.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
    }

    private func stageTag(_ stage: SubmissionStage) -> some View {
        Text(stage.displayName)
            .font(AppTheme.captionFont)
            .foregroundStyle(stage == .published ? AppTheme.success : AppTheme.danger)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, AppTheme.spacingXs)
            .background((stage == .published ? AppTheme.success : AppTheme.danger).opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Submission Log

    private var submissionLogSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            if let submission = viewModel.selectedSubmission {
                HStack {
                    Text(language.text("\(submission.name) - 推进日志", "\(submission.name) - Progress Logs"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button {
                        let markdown = viewModel.exportLogsAsMarkdown(for: submission)
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(markdown, forType: .string)
                    } label: {
                        Label(language.text("下载 MD", "Copy MD"), systemImage: "doc.on.doc")
                            .font(AppTheme.captionFont)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.secondary)
                    .controlSize(.small)
                    Button {
                        viewModel.selectedSubmissionId = nil
                    } label: {
                        Label(language.text("关闭", "Close"), systemImage: "xmark")
                            .font(AppTheme.captionFont)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textSecondary)
                    .controlSize(.small)
                }

                if viewModel.showNewLogForm {
                    newLogForm(for: submission)
                } else {
                    HStack {
                        Button {
                            viewModel.showNewLogForm = true
                        } label: {
                            Label(language.text("添加推进日志", "Add Progress Log"), systemImage: "plus")
                                .font(AppTheme.captionFont)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.secondary)
                        .controlSize(.small)

                        Button {
                            importAttachment(for: submission)
                        } label: {
                            Label(language.text("添加附件", "Add Attachment"), systemImage: "paperclip")
                                .font(AppTheme.captionFont)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppTheme.primary)
                        .controlSize(.small)
                    }
                }

                if !submission.attachments.isEmpty {
                    attachmentSection(for: submission)
                }

                if viewModel.selectedSubmissionLogs.isEmpty {
                    Text(language.text("暂无推进日志", "No progress logs"))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacingMd)
                } else {
                    ForEach(viewModel.selectedSubmissionLogs) { log in
                        logRow(log, submission: submission)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func newLogForm(for submission: Submission) -> some View {
        HStack(spacing: AppTheme.spacingSm) {
            TextField(language.text("日志内容", "Log Content"), text: $viewModel.newLogContent, axis: .vertical)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .font(AppTheme.bodyFont)
                .lineLimit(3...6)
            Button(language.text("添加", "Add")) {
                viewModel.addLog(to: submission)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.secondary)
            .controlSize(.small)
            .disabled(viewModel.newLogContent.trimmingCharacters(in: .whitespaces).isEmpty)
            Button(language.text("取消", "Cancel")) {
                viewModel.showNewLogForm = false
                viewModel.newLogContent = ""
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.textSecondary)
            .controlSize(.small)
        }
    }

    private func logRow(_ log: SubmissionLog, submission: Submission) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacingSm) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                Text(log.content)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
            Button(role: .destructive) {
                viewModel.deleteLog(log, from: submission)
            } label: {
                Label(language.text("删除", "Delete"), systemImage: "trash")
                    .font(AppTheme.captionFont)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.textTertiary)
            .controlSize(.mini)
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
    }

    private func attachmentSection(for submission: Submission) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(language.text("附件", "Attachments"))
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(submission.attachments) { attachment in
                Button {
                    viewModel.openAttachment(attachment)
                } label: {
                    HStack {
                        Image(systemName: "paperclip")
                        Text(attachment.originalFileName)
                            .lineLimit(1)
                        Spacer()
                        Text(attachment.createdAt.formatted("yyyy/MM/dd"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(AppTheme.spacingSm)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var targetLabelPlaceholder: String {
        switch viewModel.newOutcomeType {
        case .paper: return language.text("目标期刊 / 会议", "Target Journal / Conference")
        case .patent: return language.text("发明人", "Inventor")
        case .award: return language.text("奖项组织方", "Award Organizer")
        case .other: return language.text("目标单位", "Target Organization")
        }
    }

    private var identifierPlaceholder: String {
        switch viewModel.newOutcomeType {
        case .paper: return language.text("DOI / 稿件编号（选填）", "DOI / Manuscript ID (optional)")
        case .patent: return language.text("专利号 / 申请号（选填）", "Patent / Application No. (optional)")
        case .award: return language.text("奖项级别 / 届次（选填）", "Award level / edition (optional)")
        case .other: return language.text("编号 / 备注（选填）", "Identifier / Note (optional)")
        }
    }

    private func importAttachmentForDraft() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        let response = panel.runModal()
        AppDataStore.shared.restoreApplicationFocus()
        guard response == .OK else { return }
        panel.urls.forEach { viewModel.addPendingAttachment(from: $0) }
    }

    private func importAttachment(for submission: Submission) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        let response = panel.runModal()
        AppDataStore.shared.restoreApplicationFocus()
        guard response == .OK else { return }
        panel.urls.forEach { viewModel.attachFile(to: submission, from: $0) }
    }
}
