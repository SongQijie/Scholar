import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = OverviewViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                todayTimelineSection
                    .fadeIn(delay: 0.08)

                researchPulseSection
                    .fadeIn(delay: 0.1)

                workbenchSection
                    .fadeIn(delay: 0.18)

                overviewColumns
                    .fadeIn(delay: 0.22)
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("教师工作台", "Faculty Desk"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(formattedHeaderDate)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.primary)
                Text(Date().formatted("yyyy/MM/dd"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.spacingMd)
            .padding(.vertical, AppTheme.spacingSm)
            .background(AppTheme.surfaceElevated)
            .clipShape(Capsule())
        }
    }

    private var workbenchSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AppTheme.spacingLg) {
                focusSummaryCard
                rhythmCard
            }

            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                focusSummaryCard
                rhythmCard
            }
        }
    }

    private var focusSummaryCard: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("今天先推进什么", "Today's Focus"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Badge(text: language.text("今日", "Today"), style: .success)
                }

                Divider()
                    .background(AppTheme.divider)

                VStack(spacing: AppTheme.spacingMd) {
                    InfoRow(
                        icon: "list.bullet.clipboard.fill",
                        iconColor: AppTheme.primary,
                        title: language.text("今日待推进", "Open Today"),
                        value: "\(viewModel.workbenchStats.todayOpenTasks)"
                    )

                    InfoRow(
                        icon: "calendar.badge.exclamationmark",
                        iconColor: AppTheme.warning,
                        title: language.text("今天截止", "Due Today"),
                        value: "\(viewModel.workbenchStats.dueTodayTasks)"
                    )

                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: AppTheme.danger,
                        title: language.text("已经逾期", "Overdue"),
                        value: "\(viewModel.workbenchStats.overdueTasks)"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rhythmCard: some View {
        GradientCard(
            gradient: LinearGradient(
                colors: [AppTheme.primary.opacity(0.15), AppTheme.secondary.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            borderColor: AppTheme.primary.opacity(0.2)
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("当前节奏判断", "Rhythm Check"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(AppTheme.primary)
                        .font(.title3)
                }

                Divider()
                    .background(AppTheme.primary.opacity(0.2))

                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    Text(workbenchStatusTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)

                    Text(workbenchStatusDetail)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var overviewColumns: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                leftOverviewColumn
                rightOverviewColumn
            }

            VStack(spacing: AppTheme.spacingMd) {
                leftOverviewColumn
                rightOverviewColumn
            }
        }
    }

    private var leftOverviewColumn: some View {
        VStack(spacing: AppTheme.spacingMd) {
            TodaySnapshotView(snapshot: viewModel.todaySnapshot)
            TodayExecutionView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var rightOverviewColumn: some View {
        VStack(spacing: AppTheme.spacingMd) {
            TodayScheduleView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var researchPulseSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("工作态势", "Work Pulse"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()
                }

                Divider()
                    .background(AppTheme.divider)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingMd) {
                        StatCard(
                            title: language.text("在研项目", "Active Projects"),
                            value: "\(viewModel.workbenchStats.activeProjects)",
                            icon: "folder.fill",
                            color: AppTheme.primary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("指导课题", "Mentored Topics"),
                            value: "\(viewModel.workbenchStats.activeTheses)",
                            icon: "doc.text.fill",
                            color: AppTheme.secondary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("7天内截止", "Due in 7 Days"),
                            value: "\(viewModel.workbenchStats.dueSoonTasks)",
                            icon: "calendar.badge.exclamationmark",
                            color: AppTheme.warning
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("活跃成果", "Active Outcomes"),
                            value: "\(viewModel.workbenchStats.activeSubmissions)",
                            icon: "paperplane.fill",
                            color: AppTheme.accent
                        )
                        .hoverScale(1.02)

                    }
                    .padding(.vertical, AppTheme.spacingXs)
                }
            }
        }
    }

    private var todayTimelineSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("今天的大概时间线", "Today's Timeline"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(language.text("\(viewModel.todayTimelineItems.count) 项", "\(viewModel.todayTimelineItems.count) items"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Divider()
                    .background(AppTheme.divider)

                if viewModel.todayTimelineItems.isEmpty {
                    Text(language.text("今天还没有明确的任务或时间安排。可以先在项目、教学或课题任务里标记“今日推进”，再回到这里看一天的节奏。", "No clear tasks or schedule yet. Mark project, teaching, or topic tasks as today's work, then come back to see the day shape up."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppTheme.spacingSm)
                } else {
                    VStack(spacing: AppTheme.spacingSm) {
                        ForEach(viewModel.todayTimelineItems.prefix(8)) { item in
                            timelineRow(item)
                        }
                    }
                }
            }
        }
    }

    private func timelineRow(_ item: OverviewViewModel.TimelineItem) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Text(item.time?.formatted("HH:mm") ?? language.text("待定", "Anytime"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(timelineColor(item.color))
                .frame(width: 52, alignment: .leading)

            Circle()
                .fill(timelineColor(item.color))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(item.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                    .strikethrough(item.isCompleted, color: AppTheme.textTertiary)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func timelineColor(_ token: OverviewViewModel.TimelineItem.ColorToken) -> Color {
        switch token {
        case .primary: return AppTheme.primary
        case .warning: return AppTheme.warning
        case .danger: return AppTheme.danger
        case .success: return AppTheme.success
        case .secondary: return AppTheme.secondary
        }
    }
}

// MARK: - Helper Views

private struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))

            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, AppTheme.spacingXs)
    }
}

// MARK: - ViewModel Extensions

extension OverviewView {
    private var formattedHeaderDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .chinese ? "zh_CN" : "en_US")
        formatter.dateFormat = language == .chinese ? "yyyy年MM月dd日 EEEE" : "EEEE, MMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var workbenchStatusTitle: String {
        if viewModel.workbenchStats.overdueTasks > 0 {
            return language.text("先处理逾期", "Clear Overdue First")
        }
        if viewModel.workbenchStats.todayOpenTasks == 0 {
            return language.text("先定今日主线", "Pick Today's Thread")
        }
        if viewModel.workbenchStats.dueTodayTasks > 0 {
            return language.text("今天有截止点", "Deadline Day")
        }
        return language.text("按时间线推进", "Follow the Timeline")
    }

    private var workbenchStatusDetail: String {
        if viewModel.workbenchStats.overdueTasks > 0 {
            return language.text("建议先清掉逾期任务，再安排新的推进。", "Clear overdue items before adding more work.")
        }
        if viewModel.workbenchStats.todayOpenTasks == 0 {
            return language.text("从科研、教学或课题里挑 1-3 个任务标记为今日推进。", "Pick 1-3 research, teaching, or topic tasks and mark them for today.")
        }
        if viewModel.workbenchStats.dueTodayTasks > 0 {
            return language.text("优先处理今天截止的任务，再推进非截止事项。", "Handle today's due items before non-deadline work.")
        }
        return language.text("保持少量任务，按上午/下午/晚上分段推进。", "Keep the list small and move through morning, afternoon, and evening.")
    }

}
