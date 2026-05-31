import SwiftUI
import AppKit

struct SubmissionView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = SubmissionViewModel()
    @State private var submissionToDelete: Submission?
    @State private var showDeleteSubmissionConfirmation = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                statisticsSection
                    .fadeIn(delay: 0.1)

                achievementBoard
                    .fadeIn(delay: 0.15)

                archiveSection
                    .fadeIn(delay: 0.2)

            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
        .alert(language.text("删除成果", "Delete Achievement"), isPresented: $showDeleteSubmissionConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let submission = submissionToDelete {
                    viewModel.deleteSubmission(submission)
                }
                submissionToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个成果吗？此操作不可撤销。", "Delete this achievement? This cannot be undone."))
        }
    }

    private func confirmDeleting(_ submission: Submission) {
        submissionToDelete = submission
        showDeleteSubmissionConfirmation = true
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("成果管理", "Achievements"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理论文、专利、奖项等成果", "Manage papers, patents, awards and more"))
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
                        title: language.text("成果总数", "Total"),
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
                        title: language.text("已拒绝", "Rejected"),
                        value: "\(viewModel.stats.rejectedCount)",
                        icon: "xmark.octagon.fill",
                        color: AppTheme.danger
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("论文录用", "Accepted Papers"),
                        value: "\(viewModel.stats.acceptedPapers)",
                        icon: "doc.text.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("专利授权", "Authorized Patents"),
                        value: "\(viewModel.stats.authorizedPatents)",
                        icon: "doc.badge.gearshape.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("奖项", "Awards"),
                        value: "\(viewModel.stats.awards)",
                        icon: "trophy.fill",
                        color: AppTheme.warning
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("其他", "Others"),
                        value: "\(viewModel.stats.otherAchievements)",
                        icon: "star.fill",
                        color: AppTheme.textSecondary
                    )
                    .hoverScale(1.02)
                }
                .padding(.vertical, AppTheme.spacingXs)
            }
        }
    }

    // MARK: - Achievement Board

    private var achievementBoard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("成果看板", "Achievement Board"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.showNewSubmissionForm.toggle()
                } label: {
                    Label(language.text("添加成果", "Add Achievement"), systemImage: "plus")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .controlSize(.small)
            }

            if viewModel.showNewSubmissionForm {
                newSubmissionForm
            }

            VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                // 论文列表
                paperSection

                // 专利列表
                patentSection
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: - Paper Section

    private var paperSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(language.text("论文", "Papers"))
                .font(AppTheme.bodyFont)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.paperSubmissions.isEmpty {
                Text(language.text("暂无进行中的论文", "No active papers"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                VStack(spacing: AppTheme.spacingXs) {
                    ForEach(viewModel.paperSubmissions) { submission in
                        paperListRow(submission)
                    }
                }
            }
        }
    }

    private func paperListRow(_ submission: Submission) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.primary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(spacing: AppTheme.spacingMd) {
                    Text(submission.name)
                        .font(AppTheme.bodyFont)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    typeChip(submission.type)

                    if !submission.personalRank.isEmpty {
                        infoChip(language.text("本人排名 \(submission.personalRank)", "Rank \(submission.personalRank)"), color: AppTheme.secondary)
                    }

                    if submission.isCorrespondingAuthor {
                        infoChip(language.text("通讯", "Corresponding"), color: AppTheme.success)
                    }

                    if submission.authorOrder == 1 {
                        infoChip(language.text("第一作者", "First Author"), color: AppTheme.accent)
                    }

                    if let submissionDate = submission.submissionDate {
                        Label(submissionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    if let acceptanceDate = submission.acceptanceDate {
                        Label(acceptanceDate.formatted(date: .abbreviated, time: .omitted), systemImage: "checkmark.seal")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Spacer(minLength: AppTheme.spacingMd)

                    paperStatusMenu(for: submission)

                    if submission.paperStatus == .accepted {
                        Button {
                            viewModel.archiveSubmission(submission)
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.success)
                        .controlSize(.mini)
                    }

                    Button(role: .destructive) {
                        confirmDeleting(submission)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.textTertiary)
                    .controlSize(.mini)
                }

                HStack(spacing: AppTheme.spacingMd) {
                    if !submission.targetJournal.isEmpty {
                        Label(submission.targetJournal, systemImage: "book")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    if submission.ccfGrade != .none {
                        Label("CCF: \(submission.ccfGrade.displayName)", systemImage: "star")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    if submission.sciGrade != .none {
                        Label("SCI: \(submission.sciGrade.displayName)", systemImage: "globe")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    if submission.isEI {
                        infoChip("EI", color: AppTheme.warning)
                    }

                    if !submission.targetIdentifier.isEmpty {
                        Label(submission.targetIdentifier, systemImage: "number")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(1)
                    }

                    if !submission.authors.isEmpty {
                        Label(submission.authors, systemImage: "person.3")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(1)
                    }
                }

                if !submission.summary.isEmpty {
                    Text(submission.summary)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, AppTheme.spacingMd)
            .padding(.vertical, AppTheme.spacingSm)
        }
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
    }

    // MARK: - Patent Section

    private var patentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(language.text("专利", "Patents"))
                .font(AppTheme.bodyFont)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.patentSubmissions.isEmpty {
                Text(language.text("暂无进行中的专利", "No active patents"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                VStack(spacing: AppTheme.spacingXs) {
                    ForEach(viewModel.patentSubmissions) { submission in
                        patentListRow(submission)
                    }
                }
            }
        }
    }

    private func patentListRow(_ submission: Submission) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            HStack(spacing: AppTheme.spacingMd) {
                Text(submission.name)
                    .font(AppTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                typeChip(submission.type)

                if !submission.personalRank.isEmpty {
                    infoChip(language.text("本人排名 \(submission.personalRank)", "Rank \(submission.personalRank)"), color: AppTheme.secondary)
                }

                if !submission.targetIdentifier.isEmpty {
                    Label(submission.targetIdentifier, systemImage: "number")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                if let submissionDate = submission.submissionDate {
                    Label(submissionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                if let acceptanceDate = submission.acceptanceDate {
                    Label(acceptanceDate.formatted(date: .abbreviated, time: .omitted), systemImage: "checkmark.seal")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                }

                if !submission.relatedStudents.isEmpty {
                    Label(submission.relatedStudents.joined(separator: ", "), systemImage: "person.3")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppTheme.spacingMd)

                patentStatusMenu(for: submission)

                if submission.patentStatus == .authorized {
                    Button {
                        viewModel.archiveSubmission(submission)
                    } label: {
                        Image(systemName: "archivebox")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.success)
                    .controlSize(.mini)
                }

                Button(role: .destructive) {
                    confirmDeleting(submission)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.textTertiary)
                .controlSize(.mini)
            }

            HStack(spacing: AppTheme.spacingMd) {
                if !submission.targetJournal.isEmpty {
                    Label(submission.targetJournal, systemImage: "person")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                if !submission.collaborators.isEmpty {
                    Label(submission.collaborators, systemImage: "building.2")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
    }

    // MARK: - New Submission Form

    private var newSubmissionForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack(alignment: .bottom, spacing: AppTheme.spacingMd) {
                formField(language.text("成果名称", "Achievement Name"), text: $viewModel.newSubmissionName)
                    .frame(maxWidth: .infinity)

                if viewModel.newOutcomeType == .award || viewModel.newOutcomeType == .other {
                    formField(language.text("本人排名", "My Rank"), text: $viewModel.newPersonalRank)
                        .frame(width: 150)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("成果类型", "Achievement Type"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("成果类型", "Achievement Type"), selection: $viewModel.newOutcomeType) {
                        ForEach(ResearchOutcomeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .workspaceSegmented()
                }
                .frame(width: 340)
            }

            if viewModel.newOutcomeType == .paper {
                // 论文特定字段
                Divider()

                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(language.text("本人排名", "My Rank"), text: $viewModel.newPersonalRank)
                        .frame(width: 150)
                    formField(language.text("作者（按论文顺序填写）", "Authors (order)"), text: $viewModel.newAuthors)
                        .frame(minWidth: 260)

                    Toggle(language.text("是否通讯", "Corresponding"), isOn: $viewModel.newIsCorrespondingAuthor)
                        .toggleStyle(.checkbox)
                    Toggle(language.text("第一作者", "First Author"), isOn: firstAuthorBinding)
                        .toggleStyle(.checkbox)

                    Spacer()
                }
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

                formField(language.text("合作单位", "Collaborators"), text: $viewModel.newCollaborators)

                // 第二行：目标期刊会议，DOI，论文状态
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(targetLabelPlaceholder, text: $viewModel.newTargetJournal)
                        .frame(minWidth: 220)
                    formField(identifierPlaceholder, text: $viewModel.newTargetIdentifier)
                        .frame(minWidth: 220)
                    VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                        Text(language.text("论文状态", "Paper Status"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        Picker(language.text("论文状态", "Paper Status"), selection: $viewModel.newPaperStatus) {
                            ForEach(PaperStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .workspaceControl()
                    }
                    .frame(width: 180)
                }

                // 第三行：CCF分区，SCI分区，投递日期，录用日期
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let dateWidth: CGFloat = 150
                    let segmentedWidth = max(180, (availableWidth - dateWidth * 2 - AppTheme.spacingSm * 3) / 2)

                    HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                            Text(language.text("CCF分区", "CCF Grade"))
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                            Picker("", selection: $viewModel.newCCFGrade) {
                                ForEach(CCFGrade.allCases, id: \.self) { grade in
                                    Text(grade.displayName).tag(grade)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .workspaceSegmented()
                        }
                        .frame(width: segmentedWidth)

                        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                            Text(language.text("SCI分区", "SCI Grade"))
                                .font(AppTheme.captionFont)
                                .foregroundStyle(AppTheme.textSecondary)
                            Picker("", selection: $viewModel.newSCIGrade) {
                                ForEach(SCIGrade.allCases, id: \.self) { grade in
                                    Text(grade.displayName).tag(grade)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .workspaceSegmented()
                        }
                        .frame(width: segmentedWidth)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.text("投递日期", "Submission Date"))
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { viewModel.newSubmissionDate ?? Date() },
                                    set: { viewModel.newSubmissionDate = $0 }
                                ),
                                displayedComponents: [.date]
                            )
                            .font(AppTheme.bodyFont)
                            .labelsHidden()
                            .workspaceControl()
                        }
                        .frame(width: dateWidth)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.text("录用日期", "Acceptance Date"))
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { viewModel.newAcceptanceDate ?? Date() },
                                    set: { viewModel.newAcceptanceDate = $0 }
                                ),
                                displayedComponents: [.date]
                            )
                            .font(AppTheme.bodyFont)
                            .labelsHidden()
                            .workspaceControl()
                        }
                        .frame(width: dateWidth)
                    }
                }
                .frame(height: 58)

                // 第四行：成果简介
                multilineField(language.text("成果简介", "Summary"), text: $viewModel.newSubmissionSummary)
            }

            if viewModel.newOutcomeType == .patent {
                Divider()

                // 专利特定字段
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(language.text("本人排名", "My Rank"), text: $viewModel.newPersonalRank)
                        .frame(width: 150)
                    formField(targetLabelPlaceholder, text: $viewModel.newTargetJournal)
                }

                // 第二行：专利号和合作单位
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(identifierPlaceholder, text: $viewModel.newTargetIdentifier)
                    formField(language.text("合作单位", "Collaborators"), text: $viewModel.newCollaborators)
                }

                // 第三行：专利状态，递交日期，授权日期，关联学生
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                        Text(language.text("专利状态", "Patent Status"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        Picker(language.text("专利状态", "Patent Status"), selection: $viewModel.newPatentStatus) {
                            ForEach(PatentStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .workspaceControl()
                    }
                    .frame(width: 150)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text("递交日期", "Submission Date"))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.newSubmissionDate ?? Date() },
                                set: { viewModel.newSubmissionDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .font(AppTheme.bodyFont)
                        .labelsHidden()
                    }
                    .frame(width: 160)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text("授权日期", "Authorization Date"))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.newAcceptanceDate ?? Date() },
                                set: { viewModel.newAcceptanceDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .font(AppTheme.bodyFont)
                        .labelsHidden()
                    }
                    .frame(width: 160)

                    formField(language.text("关联学生（逗号分隔）", "Related Students (comma-separated)"), text: $viewModel.newRelatedStudents)
                }
            }

            if viewModel.newOutcomeType == .award {
                Divider()

                // 奖项特定字段
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(targetLabelPlaceholder, text: $viewModel.newTargetJournal)
                    formField(language.text("几等奖", "Award Level"), text: $viewModel.newAwardLevel)
                }

                // 第三行：颁发机构、合作单位和获得日期并列
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(identifierPlaceholder, text: $viewModel.newTargetIdentifier)
                    formField(language.text("合作者 / 单位", "Collaborators"), text: $viewModel.newCollaborators)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text("获得日期", "Obtained Date"))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.newAcceptanceDate ?? Date() },
                                set: { viewModel.newAcceptanceDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .font(AppTheme.bodyFont)
                        .labelsHidden()
                    }
                    .frame(width: 170)
                }
            }

            if viewModel.newOutcomeType == .other {
                Divider()

                // 其他成果特定字段
                formField(targetLabelPlaceholder, text: $viewModel.newTargetJournal)

                // 第二行：编号备注、合作者和获得日期并列
                HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                    formField(identifierPlaceholder, text: $viewModel.newTargetIdentifier)
                    formField(language.text("合作者 / 单位", "Collaborators"), text: $viewModel.newCollaborators)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text("获得日期", "Obtained Date"))
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.newAcceptanceDate ?? Date() },
                                set: { viewModel.newAcceptanceDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .font(AppTheme.bodyFont)
                        .labelsHidden()
                    }
                    .frame(width: 170)
                }
            }

            Divider()

            // 附件
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

            // 按钮
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
                    resetForm()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.textSecondary)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func resetForm() {
        viewModel.newSubmissionName = ""
        viewModel.newOutcomeType = .paper
        viewModel.newPersonalRank = ""
        viewModel.newTargetJournal = ""
        viewModel.newTargetIdentifier = ""
        viewModel.newCollaborators = ""
        viewModel.newAwardLevel = ""
        viewModel.newSubmissionSummary = ""
        viewModel.newCCFGrade = .none
        viewModel.newSCIGrade = .none
        viewModel.newIsEI = false
        viewModel.newIsCorrespondingAuthor = false
        viewModel.newAuthors = ""
        viewModel.newAuthorOrder = ""
        viewModel.newPatentStatus = .submitted
        viewModel.newPaperStatus = .submitted
        viewModel.newRelatedStudents = ""
        viewModel.newSubmissionDate = nil
        viewModel.newAcceptanceDate = nil
        viewModel.pendingAttachmentURLs = []
    }

    // MARK: - Archive Section

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("成果归档", "Archive"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                // 筛选控件
                HStack(spacing: AppTheme.spacingSm) {
                    Picker(language.text("类型", "Type"), selection: $viewModel.archiveFilterType) {
                        Text(language.text("全部", "All")).tag(nil as ResearchOutcomeType?)
                        ForEach(ResearchOutcomeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(Optional.some(type))
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    Picker(language.text("年份", "Year"), selection: $viewModel.archiveFilterYear) {
                        Text(language.text("全部", "All")).tag(nil as Int?)
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text("\(year)").tag(Optional.some(year))
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)

                    if viewModel.archiveFilterYear != nil {
                        Picker(language.text("月份", "Month"), selection: $viewModel.archiveFilterMonth) {
                            Text(language.text("全部", "All")).tag(nil as Int?)
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)").tag(Optional.some(month))
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.small)
                    }
                }
            }

            if viewModel.archivedSubmissions.isEmpty {
                Text(language.text("暂无归档成果", "No archived achievements"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                VStack(spacing: AppTheme.spacingXs) {
                    ForEach(viewModel.archivedSubmissions) { submission in
                        archiveRow(submission)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func archiveRow(_ submission: Submission) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            switch submission.type {
            case .paper:
                compactPaperArchiveRow(submission)
            case .patent:
                compactPatentArchiveRow(submission)
            case .award, .other:
                compactAwardOtherArchiveRow(submission)
            }
        }
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
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
                    .padding(AppTheme.spacingMd)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var formColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 260), spacing: AppTheme.spacingSm, alignment: .top)]
    }

    private var compactFormColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 170), spacing: AppTheme.spacingSm, alignment: .top)]
    }

    private var firstAuthorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.newAuthorOrder == "1" },
            set: { viewModel.newAuthorOrder = $0 ? "1" : "" }
        )
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

    private func paperStatusMenu(for submission: Submission) -> some View {
        Menu {
            ForEach(PaperStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    viewModel.updatePaperStatus(submission, status: status)
                }
            }
        } label: {
            Text(submission.paperStatus.displayName)
                .font(AppTheme.captionFont)
                .padding(.horizontal, AppTheme.spacingSm)
                .padding(.vertical, 4)
                .background(AppTheme.primary.opacity(0.12))
                .foregroundStyle(AppTheme.primary)
                .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    private func patentStatusMenu(for submission: Submission) -> some View {
        Menu {
            ForEach(PatentStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    viewModel.updatePatentStatus(submission, status: status)
                }
            }
        } label: {
            Text(submission.patentStatus.displayName)
                .font(AppTheme.captionFont)
                .padding(.horizontal, AppTheme.spacingSm)
                .padding(.vertical, 4)
                .background(AppTheme.secondary.opacity(0.12))
                .foregroundStyle(AppTheme.secondary)
                .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    @ViewBuilder
    private func compactPaperArchiveRow(_ submission: Submission) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Text(submission.name)
                .font(AppTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            typeChip(submission.type)

            if !submission.personalRank.isEmpty {
                infoChip(language.text("本人排名 \(submission.personalRank)", "Rank \(submission.personalRank)"), color: AppTheme.secondary)
            }

            if submission.isCorrespondingAuthor {
                infoChip(language.text("通讯", "Corresponding"), color: AppTheme.success)
            }
            if submission.authorOrder == 1 {
                infoChip(language.text("第一作者", "First Author"), color: AppTheme.accent)
            }
            if let submissionDate = submission.submissionDate {
                Label(submissionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            if let acceptanceDate = submission.acceptanceDate {
                Label(acceptanceDate.formatted(date: .abbreviated, time: .omitted), systemImage: "checkmark.seal")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer(minLength: AppTheme.spacingMd)
            unarchiveButtonIfNeeded(submission)
        }

        HStack(spacing: AppTheme.spacingMd) {
            if !submission.targetJournal.isEmpty {
                Label(submission.targetJournal, systemImage: "book")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            infoChip(submission.paperStatus.displayName, color: AppTheme.primary)
            if submission.ccfGrade != .none {
                Label("CCF: \(submission.ccfGrade.displayName)", systemImage: "star")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            if submission.sciGrade != .none {
                Label("SCI: \(submission.sciGrade.displayName)", systemImage: "globe")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            if !submission.targetIdentifier.isEmpty {
                Label(submission.targetIdentifier, systemImage: "number")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
            if !submission.authors.isEmpty {
                Label(submission.authors, systemImage: "person.3")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func compactPatentArchiveRow(_ submission: Submission) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Text(submission.name)
                .font(AppTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            typeChip(submission.type)
            if !submission.personalRank.isEmpty {
                infoChip(language.text("本人排名 \(submission.personalRank)", "Rank \(submission.personalRank)"), color: AppTheme.secondary)
            }
            if !submission.targetIdentifier.isEmpty {
                Label(submission.targetIdentifier, systemImage: "number")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            if let submissionDate = submission.submissionDate {
                Label(submissionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            if let acceptanceDate = submission.acceptanceDate {
                Label(acceptanceDate.formatted(date: .abbreviated, time: .omitted), systemImage: "checkmark.seal")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            if !submission.relatedStudents.isEmpty {
                Label(submission.relatedStudents.joined(separator: ", "), systemImage: "person.3")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppTheme.spacingMd)
            infoChip(submission.patentStatus.displayName, color: AppTheme.secondary)
            unarchiveButtonIfNeeded(submission)
        }

        HStack(spacing: AppTheme.spacingMd) {
            if !submission.targetJournal.isEmpty {
                Label(submission.targetJournal, systemImage: "person")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            if !submission.collaborators.isEmpty {
                Label(submission.collaborators, systemImage: "building.2")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func compactAwardOtherArchiveRow(_ submission: Submission) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Text(submission.name)
                .font(AppTheme.bodyFont)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
            typeChip(submission.type)
            if !submission.personalRank.isEmpty {
                infoChip(language.text("本人排名 \(submission.personalRank)", "Rank \(submission.personalRank)"), color: AppTheme.secondary)
            }
            if !submission.collaborators.isEmpty {
                Label(submission.collaborators, systemImage: "person.2")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            if let acceptanceDate = submission.acceptanceDate {
                Label(acceptanceDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer(minLength: AppTheme.spacingMd)
            unarchiveButtonIfNeeded(submission)
        }

        HStack(spacing: AppTheme.spacingMd) {
            if !submission.targetJournal.isEmpty {
                Label(submission.targetJournal, systemImage: submission.type == .award ? "trophy" : "doc.text")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            if submission.type == .award, !submission.awardLevel.isEmpty {
                infoChip(submission.awardLevel, color: AppTheme.warning)
            }
            if !submission.targetIdentifier.isEmpty {
                Label(submission.targetIdentifier, systemImage: submission.type == .award ? "building.2" : "number")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func unarchiveButtonIfNeeded(_ submission: Submission) -> some View {
        HStack(spacing: AppTheme.spacingXs) {
            if submission.isArchived {
                Button {
                    viewModel.unarchiveSubmission(submission)
                } label: {
                    Image(systemName: "tray.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.secondary)
                .controlSize(.mini)
            }

            Button(role: .destructive) {
                confirmDeleting(submission)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.textTertiary)
            .controlSize(.mini)
        }
    }

    private func infoChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func typeChip(_ type: ResearchOutcomeType) -> some View {
        infoChip(type.displayName, color: type == .award ? AppTheme.warning : type == .paper ? AppTheme.primary : type == .patent ? AppTheme.secondary : AppTheme.textSecondary)
    }

    private var targetLabelPlaceholder: String {
        switch viewModel.newOutcomeType {
        case .paper: return language.text("目标期刊 / 会议", "Target Journal / Conference")
        case .patent: return language.text("发明人", "Inventor")
        case .award: return language.text("奖项类别", "Award Category")
        case .other: return language.text("内容", "Content")
        }
    }

    private var identifierPlaceholder: String {
        switch viewModel.newOutcomeType {
        case .paper: return language.text("DOI / 稿件编号（选填）", "DOI / Manuscript ID (optional)")
        case .patent: return language.text("专利号 / 申请号（选填）", "Patent / Application No. (optional)")
        case .award: return language.text("颁发机构（选填）", "Issuing Authority (optional)")
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
