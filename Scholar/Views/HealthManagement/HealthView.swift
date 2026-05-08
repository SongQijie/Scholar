import SwiftUI

struct HealthView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = HealthViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                summarySection
                    .fadeIn(delay: 0.1)

                contentSection
                    .fadeIn(delay: 0.15)
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: viewModel.timeRange) {
            viewModel.computeStats()
        }
        .onChange(of: viewModel.weightRange) {
            viewModel.computeStats()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("生活与健康", "Health"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("记录习惯打卡与体重变化", "Track habits and weight changes"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Picker(language.text("时间范围", "Time Range"), selection: $viewModel.timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .workspaceSegmented()
            .frame(width: 220)
        }
    }

    private var summarySection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("习惯概览", "Habit Overview"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "heart.fill")
                        .foregroundStyle(AppTheme.danger)
                }

                Divider()
                    .background(AppTheme.divider)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingMd) {
                        StatCard(
                            title: language.text("活跃习惯", "Active Habits"),
                            value: "\(viewModel.stats.activeHabitCount)",
                            icon: "bolt.fill",
                            color: AppTheme.primary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("今日完成", "Done Today"),
                            value: "\(viewModel.stats.completedHabits)",
                            icon: "checkmark.circle.fill",
                            color: AppTheme.success
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("本期打卡", "Check-ins"),
                            value: "\(viewModel.stats.totalCheckins)",
                            icon: "calendar.badge.checkmark",
                            color: AppTheme.accent
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("累计时长", "Duration"),
                            value: language.text("\(viewModel.stats.totalDurationMinutes)分", "\(viewModel.stats.totalDurationMinutes) min"),
                            icon: "timer",
                            color: AppTheme.secondary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("最近体重", "Latest Weight"),
                            value: latestWeightText,
                            icon: "scalemass.fill",
                            color: AppTheme.warning
                        )
                        .hoverScale(1.02)
                    }
                    .padding(.vertical, AppTheme.spacingXs)
                }
            }
        }
    }

    private var contentSection: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            VStack(spacing: AppTheme.spacingMd) {
                habitsSection
                habitsLibrarySection
            }
                .frame(maxWidth: .infinity, alignment: .top)

            weightSection
                .frame(width: 420, alignment: .top)
        }
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("今日打卡", "Today's Habits"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button {
                    viewModel.showNewHabitForm.toggle()
                } label: {
                    Label(viewModel.showNewHabitForm ? language.text("收起", "Collapse") : language.text("新增习惯", "New Habit"), systemImage: viewModel.showNewHabitForm ? "chevron.up" : "plus")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .controlSize(.small)
            }

            if viewModel.showNewHabitForm {
                newHabitForm
            }

            if viewModel.activeHabits.isEmpty {
                emptyStateCard(
                    title: language.text("还没有活跃习惯", "No active habits"),
                    message: language.text("先加 1 到 3 个你每天真的会点的习惯。", "Start with 1 to 3 habits you will actually check every day.")
                )
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112, maximum: 122), spacing: AppTheme.spacingSm)], alignment: .leading, spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.activeHabits) { habit in
                        habitCard(for: habit)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var newHabitForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                TextField(language.text("图标", "Icon"), text: $viewModel.newHabitIcon)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .frame(width: 72)

                TextField(language.text("习惯名称", "Habit Name"), text: $viewModel.newHabitName)
                    .textFieldStyle(WorkspaceTextFieldStyle())
            }

            HStack(spacing: AppTheme.spacingSm) {
                Picker(language.text("记录方式", "Record Type"), selection: $viewModel.newHabitRecordType) {
                    ForEach(viewModel.allowedHabitRecordTypes, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .workspaceSegmented()

                TextField(targetPlaceholder, text: $viewModel.newHabitTargetValue)
                    .textFieldStyle(WorkspaceTextFieldStyle())
                    .frame(width: 120)
            }

            HStack {
                Button(language.text("添加", "Add")) {
                    viewModel.addHabit()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .controlSize(.small)

                Button(language.text("取消", "Cancel")) {
                    viewModel.showNewHabitForm = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()
            }
        }
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func habitCard(for habit: HealthHabit) -> some View {
        Button {
            viewModel.triggerPrimaryAction(for: habit)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(alignment: .top) {
                    Text(habit.icon)
                        .font(.system(size: 26))
                    Spacer()
                    Text(viewModel.primaryActionTitle(for: habit))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(actionColor(for: habit))
                }

                Spacer(minLength: 2)

                Text(habit.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(viewModel.habitStatusText(habit))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    habitTag(habit.recordType.displayName, color: AppTheme.secondary)
                    if habit.recordType == .count {
                        habitTag(language.text("目标 \(targetText(for: habit))", "Target \(targetText(for: habit))"), color: AppTheme.textSecondary)
                    }
                }
                .lineLimit(1)
            }
            .frame(width: 112, height: 112, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(habit.recordType == .checkin && viewModel.isHabitCompletedToday(habit))
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(viewModel.isHabitCompletedToday(habit) ? AppTheme.success.opacity(0.45) : AppTheme.border, lineWidth: 1)
        )
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("体重记录", "Weight"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button {
                    viewModel.showWeightForm.toggle()
                } label: {
                    Label(viewModel.showWeightForm ? language.text("收起", "Collapse") : language.text("记录体重", "Log Weight"), systemImage: viewModel.showWeightForm ? "chevron.up" : "plus")
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Picker(language.text("范围", "Range"), selection: $viewModel.weightRange) {
                ForEach(HealthViewModel.WeightRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .workspaceSegmented()

            if viewModel.showWeightForm {
                HStack(spacing: AppTheme.spacingSm) {
                    TextField(language.text("体重 kg", "Weight kg"), text: $viewModel.weightValue)
                        .textFieldStyle(WorkspaceTextFieldStyle())

                    Button(language.text("保存", "Save")) {
                        viewModel.addWeightRecord()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                    .controlSize(.small)
                }
            }

            if viewModel.weightRecordsForChart.isEmpty {
                emptyStateCard(
                    title: language.text("还没有体重记录", "No weight records"),
                    message: language.text("记录几次后，这里会自动生成趋势线。", "After a few entries, a trend line will appear here automatically.")
                )
            } else {
                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    Text(language.text("当前 \(latestWeightText)", "Current \(latestWeightText)"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    WeightTrendChart(records: viewModel.weightRecordsForChart)
                        .frame(height: 180)

                    VStack(spacing: AppTheme.spacingXs) {
                        ForEach(viewModel.weightRecordsForChart.reversed()) { record in
                            weightRecordRow(record)
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

    private var habitsLibrarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack {
                Text(language.text("习惯设置", "Habit Settings"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(language.text("\(allHabits.count) 项", "\(allHabits.count) items"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            if allHabits.isEmpty {
                Text(language.text("暂无习惯", "No habits yet"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingSm) {
                        ForEach(allHabits) { habit in
                            compactHabitSetting(habit)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func compactHabitSetting(_ habit: HealthHabit) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            HStack(spacing: AppTheme.spacingXs) {
                Text(habit.icon)
                Text(habit.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.spacingXs) {
                Button(habit.isActive ? language.text("停用", "Disable") : language.text("启用", "Enable")) {
                    viewModel.toggleHabitActive(habit)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(language.text("删", "Del")) {
                    viewModel.deleteHabit(habit)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(AppTheme.danger)
            }
        }
        .padding(AppTheme.spacingSm)
        .frame(width: 132, alignment: .leading)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func weightRecordRow(_ record: HealthRecord) -> some View {
        HStack {
            Text(record.date.formatted("MM/dd"))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            Text(record.weightValue.map { String(format: "%.1f kg", $0) } ?? "--")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Button(language.text("删除", "Delete")) {
                viewModel.deleteWeightRecord(record)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .tint(AppTheme.danger)
        }
        .padding(.vertical, 2)
    }

    private func emptyStateCard(title: String, message: String) -> some View {
        VStack(spacing: AppTheme.spacingXs) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(message)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingLg)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func habitTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func actionColor(for habit: HealthHabit) -> Color {
        if habit.recordType == .checkin && viewModel.isHabitCompletedToday(habit) {
            return AppTheme.success
        }
        return AppTheme.primary
    }

    private func targetText(for habit: HealthHabit) -> String {
        switch habit.recordType {
        case .count:
            return "\(Int(habit.targetValue))次"
        case .checkin:
            return "完成"
        default:
            return "\(Int(habit.targetValue))次"
        }
    }

    private func todayRecordSummary(for habit: HealthHabit) -> String {
        let records = viewModel.todayRecords(for: habit)
        guard !records.isEmpty else { return "" }

        switch habit.recordType {
        case .count:
            return records
                .compactMap(\.countValue)
                .map(String.init)
                .joined(separator: " / ")
        case .checkin:
            return records.last?.date.timeFormatted("HH:mm") ?? ""
        default:
            return ""
        }
    }

    private var allHabits: [HealthHabit] {
        AppDataStore.shared.healthHabits.sorted { $0.createdAt > $1.createdAt }
    }

    private var latestWeightText: String {
        guard let weight = viewModel.latestWeight else { return "--" }
        return String(format: "%.1f kg", weight)
    }

    private var targetPlaceholder: String {
        switch viewModel.newHabitRecordType {
        case .count:
            return "目标次数"
        case .duration:
            return "目标分钟"
        default:
            return "目标"
        }
    }
}

private struct WeightTrendChart: View {
    let records: [HealthRecord]

    var body: some View {
        GeometryReader { proxy in
            let points = records.compactMap { record -> (date: Date, value: Double)? in
                guard let weight = record.weightValue else { return nil }
                return (record.date, weight)
            }

            if points.isEmpty {
                Color.clear
            } else {
                let values = points.map(\.value)
                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 0
                let span = max(maxValue - minValue, 0.4)
                let width = max(proxy.size.width, 1)
                let height = max(proxy.size.height, 1)

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .fill(AppTheme.background)

                    VStack {
                        Spacer()
                        HStack {
                            Text(points.first?.date.formatted("MM/dd") ?? "")
                            Spacer()
                            Text(points.last?.date.formatted("MM/dd") ?? "")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.horizontal, AppTheme.spacingSm)
                        .padding(.bottom, AppTheme.spacingSm)
                    }

                    Path { path in
                        for (index, point) in points.enumerated() {
                            let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                            let normalized = (point.value - minValue) / span
                            let y = height - 24 - CGFloat(normalized) * (height - 44)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let normalized = (point.value - minValue) / span
                        let y = height - 24 - CGFloat(normalized) * (height - 44)

                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f kg", maxValue))
                        Spacer()
                        Text(String(format: "%.1f kg", minValue))
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, AppTheme.spacingSm)
                    .padding(.leading, AppTheme.spacingSm)
                }
            }
        }
    }
}
