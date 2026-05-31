import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = OverviewViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLg) {
                headerSection
                    .fadeIn()

                researchPulseSection
                    .fadeIn(delay: 0.08)

                overviewColumns
                    .fadeIn(delay: 0.14)
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
                Text(language.text("科研工作台", "Research Desk"))
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

    private var overviewColumns: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            leftOverviewColumn
            rightOverviewColumn
        }
    }

    private var leftOverviewColumn: some View {
        VStack(spacing: AppTheme.spacingMd) {
            todayTimelinePanel
            tomorrowTimelinePanel
        }
        .frame(minWidth: 390, maxWidth: .infinity, alignment: .top)
        .layoutPriority(1)
    }

    private var rightOverviewColumn: some View {
        VStack(spacing: AppTheme.spacingMd) {
            BusyCalendarPanel(viewModel: viewModel)
            RecentMoodPanel()
        }
        .frame(width: 520, alignment: .top)
        .layoutPriority(0)
    }

    private var researchPulseSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .center, spacing: AppTheme.spacingMd) {
                VStack(alignment: .leading, spacing: 4) {
                Text(language.text("工作态势", "Work Pulse"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("今日任务、持续推进与成果负载。", "Today tasks, active work, and outcome load."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104, maximum: 160), spacing: AppTheme.spacingSm)], spacing: AppTheme.spacingSm) {
                WorkPulseStatTile(title: language.text("持续推进", "Active"), value: "\(viewModel.todaySnapshot.todayOpenTasks)", icon: "list.bullet.clipboard.fill", color: AppTheme.primary)
                WorkPulseStatTile(title: language.text("今天截止", "Due"), value: "\(viewModel.todaySnapshot.dueTodayTasks)", icon: "calendar.badge.exclamationmark", color: AppTheme.warning)
                WorkPulseStatTile(title: language.text("逾期未清", "Overdue"), value: "\(viewModel.todaySnapshot.inProgressTasks)", icon: "exclamationmark.triangle.fill", color: AppTheme.danger)
                WorkPulseStatTile(title: language.text("在研项目", "Projects"), value: "\(viewModel.workbenchStats.activeProjects)", icon: "folder.fill", color: AppTheme.primary)
                WorkPulseStatTile(title: language.text("指导课题", "Topics"), value: "\(viewModel.workbenchStats.activeTheses)", icon: "graduationcap.fill", color: AppTheme.secondary)
                WorkPulseStatTile(title: language.text("执行事务", "Affairs"), value: "\(viewModel.workbenchStats.activeAffairs)", icon: "tray.full.fill", color: AppTheme.accent)
                WorkPulseStatTile(title: language.text("7天截止", "7 Days"), value: "\(viewModel.workbenchStats.dueSoonTasks)", icon: "clock.badge.exclamationmark.fill", color: AppTheme.warning)
                WorkPulseStatTile(title: language.text("活跃成果", "Outcomes"), value: "\(viewModel.workbenchStats.activeSubmissions)", icon: "paperplane.fill", color: AppTheme.success)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppTheme.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 0.75)
                )
        )
    }

    private var todayTimelinePanel: some View {
        timelinePanel(
            title: language.text("今日时间线", "Today's Timeline"),
            items: viewModel.todayTimelineItems,
            emptyText: language.text("今天还没有明确任务或时间安排。可以把需要持续推进的任务标记为今天。", "No clear tasks or schedule yet. Mark active work as today.")
        )
    }

    private var tomorrowTimelinePanel: some View {
        timelinePanel(
            title: language.text("明日时间线", "Tomorrow's Timeline"),
            items: viewModel.tomorrowTimelineItems,
            emptyText: language.text("明天还没有明确的截止任务或时间安排。", "No dated tasks or schedule blocks for tomorrow yet.")
        )
    }

    private func timelinePanel(title: String, items: [OverviewViewModel.TimelineItem], emptyText: String) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(title)
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text(language.text("\(items.count) 项", "\(items.count) items"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Divider()
                    .background(AppTheme.divider)

                if items.isEmpty {
                    Text(emptyText)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AppTheme.spacingSm)
                } else {
                    VStack(spacing: AppTheme.spacingSm) {
                        ForEach(items) { item in
                            timelineRow(item)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func timelineRow(_ item: OverviewViewModel.TimelineItem) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacingSm) {
            Text(item.time?.formatted("HH:mm") ?? language.text("待定", "Anytime"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(timelineColor(item.color))
                .frame(width: 46, alignment: .leading)
                .padding(.top, 2)

            if item.taskId != nil {
                Button {
                    viewModel.completeTimelineTask(item)
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(item.isCompleted ? AppTheme.success : AppTheme.textSecondary)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            } else {
                Circle()
                    .fill(timelineColor(item.color))
                    .frame(width: 8, height: 8)
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: AppTheme.spacingXs) {
                    Text(item.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(item.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                        .strikethrough(item.isCompleted, color: AppTheme.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let badge = timelineBadge(for: item.tone) {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(timelineColor(item.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(timelineColor(item.color).opacity(0.12))
                            .clipShape(Capsule())
                            .fixedSize()
                            .padding(.top, 1)
                    }
                }
                Text(item.subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(AppTheme.spacingSm)
        .background(timelineBackground(for: item.tone, color: timelineColor(item.color)))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(timelineColor(item.color).opacity(item.tone == .normal ? 0.08 : 0.24), lineWidth: 0.75)
        )
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

    private func timelineBackground(for tone: OverviewViewModel.TimelineItem.ToneToken, color: Color) -> Color {
        switch tone {
        case .normal:
            return AppTheme.background
        case .active:
            return AppTheme.primary.opacity(0.08)
        case .dueToday:
            return AppTheme.warning.opacity(0.12)
        case .dueSoon:
            return AppTheme.secondary.opacity(0.10)
        case .overdue:
            return AppTheme.danger.opacity(0.13)
        case .schedule:
            return color.opacity(0.08)
        }
    }

    private func timelineBadge(for tone: OverviewViewModel.TimelineItem.ToneToken) -> String? {
        switch tone {
        case .normal, .schedule:
            return nil
        case .active:
            return language.text("持续", "Active")
        case .dueToday:
            return language.text("今日截止", "Due Today")
        case .dueSoon:
            return language.text("临近", "Soon")
        case .overdue:
            return language.text("逾期", "Overdue")
        }
    }
}

// MARK: - Helper Views

private struct WorkPulseStatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.spacingSm)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(color.opacity(0.16), lineWidth: 0.75)
        )
    }
}

private struct RecentMoodPanel: View {
    @EnvironmentObject private var store: AppDataStore
    private var language: AppLanguage { store.appLanguage }

    private var recentRecords: [MentalCareRecord] {
        Array(store.mentalCareRecords.sorted { $0.date > $1.date }.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("最近心情", "Recent Mood"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(language.text("\(recentRecords.count) 条", "\(recentRecords.count) records"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, AppTheme.spacingSm)
                    .padding(.vertical, 2)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            if recentRecords.isEmpty {
                Text(language.text("还没有心情记录。去“天气与心情”记录一次，工作台会在这里展示最近状态。", "No mood records yet. Add one in Mood & Weather to show recent status here."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(recentRecords) { record in
                        moodRow(record)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.55), lineWidth: 0.75)
        )
    }

    private func moodRow(_ record: MentalCareRecord) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Text(record.moodEmoji)
                .font(.system(size: 24))
                .frame(width: 34, height: 34)
                .background(moodColor(record.mood).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))

            VStack(alignment: .leading, spacing: 3) {
                Text(record.date.formatted("MM/dd"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(weatherLabel(record.weather))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            moodMetric(title: language.text("心情", "Mood"), value: "\(record.mood)", color: moodColor(record.mood))
            moodMetric(title: language.text("压力", "Stress"), value: "\(record.stressLevel)", color: AppTheme.warning)
            moodMetric(title: language.text("能量", "Energy"), value: "\(record.energyLevel)", color: AppTheme.success)
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func moodMetric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(width: 42)
    }

    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1...3: return AppTheme.danger
        case 4...7: return AppTheme.warning
        default: return AppTheme.success
        }
    }

    private func weatherLabel(_ key: String) -> String {
        switch key {
        case "sunny": return language.text("晴", "Sunny")
        case "cloudy": return language.text("多云", "Cloudy")
        case "overcast": return language.text("阴", "Overcast")
        case "rainy": return language.text("雨", "Rain")
        case "stormy": return language.text("雷雨", "Storm")
        case "foggy": return language.text("雾", "Fog")
        case "windy": return language.text("风", "Wind")
        case "snowy": return language.text("雪", "Snow")
        default: return key
        }
    }
}

private struct BusyCalendarPanel: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: OverviewViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(spacing: AppTheme.spacingSm) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("忙碌日历", "Load Calendar"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("分母与颜色按今天截止、逾期、持续三类负载判断。", "Total and color reflect due, overdue, and ongoing load."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    viewModel.changeBusyMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button {
                    viewModel.displayedBusyMonth = Date()
                } label: {
                    Text(language.text("今天", "Today"))
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button {
                    viewModel.changeBusyMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            Text(viewModel.displayedBusyMonth.formatted("yyyy年MM月"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primary)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(viewModel.busyMonthCalendar, id: \.self) { date in
                    BusyDayCellView(
                        date: date,
                        info: viewModel.busyInfo(for: date),
                        tasks: viewModel.busyTasks(for: date),
                        isCurrentMonth: Calendar.current.isDate(date, equalTo: viewModel.displayedBusyMonth, toGranularity: .month),
                        language: language,
                        color: color(for: viewModel.busyInfo(for: date).level)
                    )
                }
            }

            let todayInfo = viewModel.busyInfo(for: Date())
            HStack(spacing: AppTheme.spacingSm) {
                BusyFaceView(level: todayInfo.level, color: color(for: todayInfo.level))
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.text("今天：\(label(for: todayInfo.level))", "Today: \(label(for: todayInfo.level))"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("\(todayInfo.completedTasks)/\(todayInfo.totalTasks) 已完成 · 今 \(todayInfo.dueTasks) / 逾 \(todayInfo.overdueTasks) / 续 \(todayInfo.continuousTasks)", "\(todayInfo.completedTasks)/\(todayInfo.totalTasks) done · due \(todayInfo.dueTasks) / overdue \(todayInfo.overdueTasks) / ongoing \(todayInfo.continuousTasks)"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
            }
            .padding(AppTheme.spacingSm)
            .background(AppTheme.background.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.55), lineWidth: 0.75)
        )
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday // 1=周日, 2=周一,...
        let chineseSymbols = ["日", "一", "二", "三", "四", "五", "六"]
        let englishSymbols = ["S", "M", "T", "W", "T", "F", "S"]
        
        let symbols = language == .chinese ? chineseSymbols : englishSymbols
        // 根据 firstWeekday 重新排序
        let firstIndex = firstWeekday - 1
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    private func label(for level: OverviewViewModel.BusyLevel) -> String {
        switch level {
        case .quiet: return language.text("清闲", "Quiet")
        case .light: return language.text("轻量", "Light")
        case .steady: return language.text("稳定", "Steady")
        case .busy: return language.text("忙碌", "Busy")
        case .heavy: return language.text("偏满", "Heavy")
        case .packed: return language.text("爆满", "Packed")
        case .overloaded: return language.text("过载", "Overloaded")
        }
    }

    private func color(for level: OverviewViewModel.BusyLevel) -> Color {
        switch level {
        case .quiet: return AppTheme.textSecondary
        case .light: return AppTheme.success
        case .steady: return AppTheme.primary
        case .busy: return AppTheme.secondary
        case .heavy: return AppTheme.warning
        case .packed: return AppTheme.danger
        case .overloaded: return AppTheme.danger
        }
    }
}

private struct BusyDayCellView: View {
    let date: Date
    let info: OverviewViewModel.BusyDayInfo
    let tasks: [Task]
    let isCurrentMonth: Bool
    let language: AppLanguage
    let color: Color

    @State private var isShowingPopover = false
    @State private var pendingPopoverWorkItem: DispatchWorkItem?

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.5))
                Spacer(minLength: 0)
            }

            BusyFaceView(level: info.level, color: color)
                .frame(width: 26, height: 26)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    BusyLoadBadge(value: "\(info.completedTasks)/\(info.totalTasks)", color: AppTheme.primary, helpText: language.text("完成/总数", "Done / total"))
                    BusyLoadBadge(systemImage: "calendar", value: "\(info.dueTasks)", color: AppTheme.warning, helpText: language.text("今天截止", "Due today"))
                }

                HStack(spacing: 2) {
                    BusyLoadBadge(systemImage: "exclamationmark.triangle.fill", value: "\(info.overdueTasks)", color: AppTheme.danger, helpText: language.text("逾期", "Overdue"))
                    BusyLoadBadge(systemImage: "arrow.triangle.2.circlepath", value: "\(info.continuousTasks)", color: AppTheme.secondary, helpText: language.text("持续跟进", "Ongoing"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
        .background(color.opacity(isToday ? 0.16 : 0.09))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isToday ? AppTheme.primary : color.opacity(0.18), lineWidth: isToday ? 1.5 : 0.75)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .opacity(isCurrentMonth ? 1 : 0.48)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .onHover { hovering in
            if hovering {
                schedulePopover()
            } else {
                cancelScheduledPopover()
                isShowingPopover = false
            }
        }
        .popover(isPresented: $isShowingPopover, arrowEdge: .top) {
            BusyDayTaskPopover(date: date, info: info, tasks: tasks, language: language)
        }
        .onDisappear {
            cancelScheduledPopover()
        }
    }

    private func schedulePopover() {
        cancelScheduledPopover()
        let workItem = DispatchWorkItem {
            isShowingPopover = true
        }
        pendingPopoverWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: workItem)
    }

    private func cancelScheduledPopover() {
        pendingPopoverWorkItem?.cancel()
        pendingPopoverWorkItem = nil
    }
}

private struct BusyLoadBadge: View {
    var systemImage: String?
    let value: String
    let color: Color
    let helpText: String

    var body: some View {
        HStack(spacing: 2) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 7, weight: .bold))
            }
            Text(value)
                .font(.system(size: 8, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.62)
        .frame(maxWidth: .infinity, minHeight: 11)
        .help("\(helpText)：\(value)")
    }
}

private struct BusyDayTaskPopover: View {
    let date: Date
    let info: OverviewViewModel.BusyDayInfo
    let tasks: [Task]
    let language: AppLanguage

    private var completedTodayTasks: [Task] {
        sortedUnique(tasks.filter { $0.status == .completed && Calendar.current.isDate($0.updatedAt, inSameDayAs: date) })
    }

    private var dueTasks: [Task] {
        sortedUnique(tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        })
    }

    private var overdueTasks: [Task] {
        sortedUnique(tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < date.startOfDay && (task.status != .completed || Calendar.current.isDate(task.updatedAt, inSameDayAs: date))
        })
    }

    private var continuousTasks: [Task] {
        sortedUnique(tasks.filter { task in
            guard task.isToday && task.status != .completed else { return false }
            guard let dueDate = task.dueDate else { return true }
            return dueDate >= date.endOfDay
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingXs) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.success)

                Text(date.formatted(language == .chinese ? "M月d日 EEEE" : "EEE, MMM d"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(language.text("完成 \(info.completedTasks) · 当日 \(info.dueTasks) · 逾期 \(info.overdueTasks) · 持续 \(info.continuousTasks)", "\(info.completedTasks) done · \(info.dueTasks) due · \(info.overdueTasks) overdue · \(info.continuousTasks) ongoing"))
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textSecondary)

            Divider()
                .background(AppTheme.divider)

            if tasks.isEmpty {
                Text(language.text("这天还没有安排任务", "No tasks scheduled for this day"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 220, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    taskSection(title: language.text("今天做完", "Done Today"), icon: "checkmark.circle.fill", color: AppTheme.success, tasks: completedTodayTasks)
                    taskSection(title: language.text("今天截止", "Due Today"), icon: "calendar.badge.clock", color: AppTheme.warning, tasks: dueTasks)
                    taskSection(title: language.text("逾期待处理", "Overdue"), icon: "exclamationmark.triangle.fill", color: AppTheme.danger, tasks: overdueTasks)
                    taskSection(title: language.text("持续跟进", "Ongoing"), icon: "arrow.triangle.2.circlepath", color: AppTheme.secondary, tasks: continuousTasks)
                }
                .frame(width: 240, alignment: .leading)
            }
        }
        .padding(AppTheme.spacingSm)
        .frame(width: 260, alignment: .leading)
    }

    private func taskSection(title: String, icon: String, color: Color, tasks: [Task]) -> some View {
        Group {
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    HStack(spacing: AppTheme.spacingXs) {
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(color)
                        Text("\(title) \(tasks.count)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    ForEach(Array(tasks.prefix(4))) { task in
                        BusyDayTaskRow(task: task, language: language)
                    }

                    if tasks.count > 4 {
                        Text(language.text("还有 \(tasks.count - 4) 个", "\(tasks.count - 4) more"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
    }

    private func sortedUnique(_ tasks: [Task]) -> [Task] {
        var seen = Set<UUID>()
        return tasks
            .filter { task in
                if seen.contains(task.id) { return false }
                seen.insert(task.id)
                return true
            }
            .sorted { lhs, rhs in
                if lhs.status == .completed && rhs.status != .completed { return false }
                if lhs.status != .completed && rhs.status == .completed { return true }
                let lhsDue = lhs.dueDate ?? .distantFuture
                let rhsDue = rhs.dueDate ?? .distantFuture
                if lhsDue != rhsDue { return lhsDue < rhsDue }
                return lhs.updatedAt > rhs.updatedAt
            }
    }
}

private struct BusyDayTaskRow: View {
    let task: Task
    let language: AppLanguage

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingXs) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(task.status == .completed ? AppTheme.success : Color(hex: task.priority.color))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title.isEmpty ? language.text("未命名任务", "Untitled task") : task.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(task.status == .completed ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(2)

                Text("\(statusLabel) · \(task.ownerLabel)")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private var statusLabel: String {
        if task.status == .completed {
            return language.text("已完成 \(task.updatedAt.timeFormatted())", "Done \(task.updatedAt.timeFormatted())")
        }

        if let dueDate = task.dueDate {
            return language.text("截止 \(dueDate.timeFormatted())", "Due \(dueDate.timeFormatted())")
        }

        return task.status.displayName
    }
}

private struct BusyFaceView: View {
    let level: OverviewViewModel.BusyLevel
    let color: Color

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: size.width * 0.07, dy: size.height * 0.07)
            let lineWidth = max(1.35, size.width * 0.07)
            let ink = color.opacity(0.96)
            let cheekColor = Color.pink.opacity(level == .packed ? 0.12 : 0.16)

            context.fill(Path(ellipseIn: rect.offsetBy(dx: 0, dy: size.height * 0.035)), with: .color(color.opacity(0.12)))
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.24)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: size.width * 0.07, dy: size.height * 0.08)), with: .color(Color.white.opacity(0.2)))
            context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.72)), lineWidth: lineWidth)

            let highlight = CGRect(
                x: size.width * 0.28,
                y: size.height * 0.22,
                width: size.width * 0.16,
                height: size.height * 0.1
            )
            context.fill(Path(ellipseIn: highlight), with: .color(Color.white.opacity(0.62)))

            drawCheeks(in: &context, size: size, color: cheekColor)

            drawEyes(in: &context, size: size, ink: ink, lineWidth: lineWidth)
            context.stroke(mouthPath(size: size), with: .color(ink), lineWidth: lineWidth)

            for mark in stressMarks(size: size) {
                context.stroke(mark, with: .color(ink.opacity(0.82)), lineWidth: lineWidth * 0.75)
            }

            if level == .busy || level == .heavy || level == .packed || level == .overloaded {
                context.fill(sweatDrop(size: size), with: .color(Color.white.opacity(0.5)))
                context.stroke(sweatDrop(size: size), with: .color(color.opacity(0.82)), lineWidth: lineWidth * 0.65)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawCheeks(in context: inout GraphicsContext, size: CGSize, color: Color) {
        let cheekSize = CGSize(width: size.width * 0.12, height: size.height * 0.06)
        let left = CGRect(
            x: size.width * 0.25,
            y: size.height * 0.53,
            width: cheekSize.width,
            height: cheekSize.height
        )
        let right = CGRect(
            x: size.width * 0.62,
            y: size.height * 0.53,
            width: cheekSize.width,
            height: cheekSize.height
        )
        context.fill(Path(ellipseIn: left), with: .color(color))
        context.fill(Path(ellipseIn: right), with: .color(color))
    }

    private func drawEyes(in context: inout GraphicsContext, size: CGSize, ink: Color, lineWidth: CGFloat) {
        let left = CGPoint(x: size.width * 0.36, y: size.height * 0.41)
        let right = CGPoint(x: size.width * 0.64, y: size.height * 0.41)
        let eyeRadius = max(1.7, size.width * 0.06)

        switch level {
        case .quiet:
            context.stroke(closedEyePath(center: left, size: size), with: .color(ink), lineWidth: lineWidth * 0.9)
            context.stroke(closedEyePath(center: right, size: size), with: .color(ink), lineWidth: lineWidth * 0.9)
        case .light:
            drawDotEye(in: &context, center: left, radius: eyeRadius, ink: ink)
            drawDotEye(in: &context, center: right, radius: eyeRadius, ink: ink)
        case .steady:
            context.stroke(flatEyePath(center: left, size: size), with: .color(ink), lineWidth: lineWidth * 0.9)
            context.stroke(flatEyePath(center: right, size: size), with: .color(ink), lineWidth: lineWidth * 0.9)
        case .busy:
            drawDotEye(in: &context, center: left, radius: eyeRadius * 0.88, ink: ink)
            drawDotEye(in: &context, center: right, radius: eyeRadius * 0.88, ink: ink)
        case .heavy:
            drawDotEye(in: &context, center: left, radius: eyeRadius * 0.92, ink: ink)
            drawDotEye(in: &context, center: right, radius: eyeRadius * 0.92, ink: ink)
        case .packed, .overloaded:
            context.stroke(xEyePath(center: left, size: size), with: .color(ink), lineWidth: lineWidth * 0.86)
            context.stroke(xEyePath(center: right, size: size), with: .color(ink), lineWidth: lineWidth * 0.86)
        }
    }

    private func drawDotEye(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, ink: Color) {
        let eye = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2.15)
        context.fill(Path(ellipseIn: eye), with: .color(ink))
        let shine = CGRect(x: center.x - radius * 0.3, y: center.y - radius * 0.48, width: radius * 0.5, height: radius * 0.5)
        context.fill(Path(ellipseIn: shine), with: .color(Color.white.opacity(0.72)))
    }

    private func closedEyePath(center: CGPoint, size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: center.x - size.width * 0.075, y: center.y))
        path.addQuadCurve(
            to: CGPoint(x: center.x + size.width * 0.075, y: center.y),
            control: CGPoint(x: center.x, y: center.y + size.height * 0.045)
        )
        return path
    }

    private func flatEyePath(center: CGPoint, size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: center.x - size.width * 0.06, y: center.y))
        path.addLine(to: CGPoint(x: center.x + size.width * 0.06, y: center.y))
        return path
    }

    private func xEyePath(center: CGPoint, size: CGSize) -> Path {
        var path = Path()
        let delta = size.width * 0.06
        path.move(to: CGPoint(x: center.x - delta, y: center.y - delta))
        path.addLine(to: CGPoint(x: center.x + delta, y: center.y + delta))
        path.move(to: CGPoint(x: center.x + delta, y: center.y - delta))
        path.addLine(to: CGPoint(x: center.x - delta, y: center.y + delta))
        return path
    }

    private func mouthPath(size: CGSize) -> Path {
        var path = Path()
        switch level {
        case .quiet:
            path.move(to: CGPoint(x: size.width * 0.38, y: size.height * 0.59))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.62, y: size.height * 0.59),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.72)
            )
        case .light:
            path.move(to: CGPoint(x: size.width * 0.36, y: size.height * 0.57))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.57),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.75)
            )
        case .steady:
            path.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.62))
            path.addLine(to: CGPoint(x: size.width * 0.63, y: size.height * 0.62))
        case .busy:
            path.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.64))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.61),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.57)
            )
        case .heavy:
            path.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.62))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.62),
                control: CGPoint(x: size.width * 0.5, y: size.height * 0.52)
            )
        case .packed, .overloaded:
            path.move(to: CGPoint(x: size.width * 0.36, y: size.height * 0.64))
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.5, y: size.height * 0.64),
                control: CGPoint(x: size.width * 0.43, y: size.height * 0.54)
            )
            path.addQuadCurve(
                to: CGPoint(x: size.width * 0.64, y: size.height * 0.64),
                control: CGPoint(x: size.width * 0.57, y: size.height * 0.74)
            )
        }
        return path
    }

    private func sweatDrop(size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: size.width * 0.76, y: size.height * 0.31))
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.7, y: size.height * 0.48),
            control: CGPoint(x: size.width * 0.63, y: size.height * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.82, y: size.height * 0.45),
            control: CGPoint(x: size.width * 0.77, y: size.height * 0.55)
        )
        path.addQuadCurve(
            to: CGPoint(x: size.width * 0.76, y: size.height * 0.31),
            control: CGPoint(x: size.width * 0.86, y: size.height * 0.36)
        )
        return path
    }

    private func stressMarks(size: CGSize) -> [Path] {
        guard level == .busy || level == .heavy || level == .packed || level == .overloaded else { return [] }

        var marks: [Path] = []
        var left = Path()
        left.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.25))
        left.addQuadCurve(
            to: CGPoint(x: size.width * 0.21, y: size.height * 0.17),
            control: CGPoint(x: size.width * 0.22, y: size.height * 0.25)
        )
        marks.append(left)

        var right = Path()
        right.move(to: CGPoint(x: size.width * 0.72, y: size.height * 0.25))
        right.addQuadCurve(
            to: CGPoint(x: size.width * 0.79, y: size.height * 0.17),
            control: CGPoint(x: size.width * 0.78, y: size.height * 0.25)
        )
        marks.append(right)

        if level == .packed || level == .overloaded {
            var top = Path()
            top.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.2))
            top.addQuadCurve(
                to: CGPoint(x: size.width * 0.5, y: size.height * 0.1),
                control: CGPoint(x: size.width * 0.44, y: size.height * 0.15)
            )
            marks.append(top)
        }

        if level == .overloaded {
            var extra = Path()
            extra.move(to: CGPoint(x: size.width * 0.38, y: size.height * 0.14))
            extra.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.05))
            marks.append(extra)
        }

        return marks
    }
}

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

}
