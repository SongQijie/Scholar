import SwiftUI

struct MentalCareView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = MentalCareViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                dashboardSection
                    .fadeIn(delay: 0.1)

                entryAndDetailSection
                    .fadeIn(delay: 0.15)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("天气与心情", "Mood & Weather"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("记录每日心情与天气状况", "Track daily mood and weather"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var dashboardSection: some View {
        GeometryReader { geometry in
            let summaryWidth = min(380, max(320, geometry.size.width * 0.31))

            HStack(alignment: .top, spacing: AppTheme.spacingLg) {
                ModernCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                        Text(language.text("统计概览", "Statistics"))
                            .font(AppTheme.subtitleFont)
                            .foregroundStyle(AppTheme.textPrimary)

                        Divider()
                            .background(AppTheme.divider)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: AppTheme.spacingSm),
                                GridItem(.flexible(), spacing: AppTheme.spacingSm)
                            ],
                            alignment: .leading,
                            spacing: AppTheme.spacingMd
                        ) {
                            StatCard(title: language.text("记录天数", "Recorded Days"), value: "\(viewModel.stats.recordDays)", icon: "calendar", color: AppTheme.primary)
                            StatCard(title: language.text("平均压力 · \(averageStressLabel)", "Avg Stress · \(averageStressLabel)"), value: String(format: "%.1f", viewModel.stats.avgStress), icon: "exclamationmark.triangle", color: AppTheme.warning)
                            StatCard(title: language.text("平均能量 · \(averageEnergyLabel)", "Avg Energy · \(averageEnergyLabel)"), value: String(format: "%.1f", viewModel.stats.avgEnergy), icon: "bolt.fill", color: AppTheme.secondary)
                            StatCard(title: language.text("写下记录", "Notes"), value: "\(viewModel.stats.noteCount)", icon: "text.quote", color: AppTheme.success)
                        }

                        Divider()
                            .background(AppTheme.divider)

                        selectedDetailCardContent
                    }
                }
                .frame(width: summaryWidth, height: geometry.size.height, alignment: .topLeading)

                calendarSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(height: 540)
    }

    private var selectedDetailCardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(language.text("详情", "Details"))
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

            if let record = viewModel.selectedRecord {
                HStack(spacing: AppTheme.spacingSm) {
                    Text(record.moodEmoji)
                        .font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(record.date.formatted("MM/dd")) · \(viewModel.weatherLabel(record.weather))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(language.text("压力 \(record.stressLevel) / 能量 \(record.energyLevel)", "Stress \(record.stressLevel) / Energy \(record.energyLevel)"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), alignment: .leading)], alignment: .leading, spacing: AppTheme.spacingXs) {
                    capsule(text: language.text("心情 \(moodLabel(for: record.mood))", "Mood \(moodLabel(for: record.mood))"), color: AppTheme.primary)
                    capsule(text: viewModel.weatherLabel(record.weather), color: AppTheme.secondary)
                    capsule(text: language.text("压力 \(record.stressLevel) · \(stressLabel(for: record.stressLevel))", "Stress \(record.stressLevel) · \(stressLabel(for: record.stressLevel))"), color: AppTheme.warning)
                    capsule(text: language.text("能量 \(record.energyLevel) · \(energyLabel(for: record.energyLevel))", "Energy \(record.energyLevel) · \(energyLabel(for: record.energyLevel))"), color: AppTheme.success)
                }

                Text(recordSummary(record))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(AppTheme.spacingSm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(AppTheme.surfaceElevated.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                            .stroke(AppTheme.border.opacity(0.65), lineWidth: 0.75)
                    )
            } else {
                HStack(spacing: AppTheme.spacingSm) {
                    Text("—")
                        .font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.text("未选择记录", "No record selected"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(language.text("点击日历中的日期查看当天状态。", "Click a calendar day to inspect that day's state."))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private var calendarDetailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Label(language.text("日历详情", "Calendar Detail"), systemImage: "calendar.badge.clock")
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(viewModel.selectedDate.formatted("MM/dd"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, AppTheme.spacingSm)
                    .padding(.vertical, 3)
                    .background(AppTheme.primary.opacity(0.10))
                    .clipShape(Capsule())
            }

            if viewModel.hasSelectedCalendarDate, let record = viewModel.selectedRecord {
                HStack(spacing: AppTheme.spacingMd) {
                    Text(record.moodEmoji)
                        .font(.system(size: 38))
                        .frame(width: 58, height: 58)
                        .background(AppTheme.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.date.formatted("yyyy/MM/dd"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(language.text("心情 \(moodLabel(for: record.mood))", "Mood: \(moodLabel(for: record.mood))"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), alignment: .leading)], alignment: .leading, spacing: AppTheme.spacingXs) {
                    capsule(text: viewModel.weatherLabel(record.weather), color: AppTheme.secondary)
                    capsule(text: language.text("压力 \(record.stressLevel) · \(stressLabel(for: record.stressLevel))", "Stress \(record.stressLevel) · \(stressLabel(for: record.stressLevel))"), color: AppTheme.warning)
                    capsule(text: language.text("能量 \(record.energyLevel) · \(energyLabel(for: record.energyLevel))", "Energy \(record.energyLevel) · \(energyLabel(for: record.energyLevel))"), color: AppTheme.success)
                }

                Text(recordSummary(record))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .background(AppTheme.divider)

                detailNoteBlock(
                    title: language.text("日记", "Journal"),
                    icon: "book.closed",
                    value: record.selfTalk,
                    emptyText: language.text("当天没有写日记。", "No journal entry for this day."),
                    color: AppTheme.primary
                )

                detailNoteBlock(
                    title: language.text("吐槽", "Rant"),
                    icon: "bubble.left.and.bubble.right",
                    value: record.drainSource,
                    emptyText: language.text("当天没有留下吐槽。", "No rant for this day."),
                    color: AppTheme.warning
                )
            } else if viewModel.hasSelectedCalendarDate {
                detailEmptyState(
                    icon: "calendar.badge.exclamationmark",
                    text: language.text("这一天还没有心情记录。", "No mood record for this day.")
                )
            } else {
                detailEmptyState(
                    icon: "calendar.badge.plus",
                    text: language.text("点击上方日历日期后，这里会显示当天状态、日记和吐槽。", "Select a calendar day to show its status, journal, and rant.")
                )
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacingMd)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.75), lineWidth: 0.75)
        )
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.displayedMonth.formatted("yyyy年MM月"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button {
                    viewModel.changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.mini)
                Button {
                    viewModel.selectDate(Date())
                } label: {
                    Text(language.text("今天", "Today"))
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.mini)
                Button {
                    viewModel.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.mini)
                Text(viewModel.selectedDate.formatted("MM/dd"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingSm), count: 7)
            LazyVGrid(columns: columns, spacing: AppTheme.spacingSm) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                ForEach(viewModel.monthCalendar, id: \.self) { date in
                    Button {
                        viewModel.selectDate(date)
                    } label: {
                        calendarDayCell(date)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func calendarDayCell(_ date: Date) -> some View {
        let record = viewModel.record(for: date)
        let isCurrentMonth = Calendar.current.isDate(date, equalTo: viewModel.displayedMonth, toGranularity: .month)
        let isToday = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
        let weatherSymbol = record.map { String(viewModel.weatherLabel($0.weather).prefix(2)) } ?? ""

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isCurrentMonth ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.5))
                Spacer()
                if record != nil {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 6, height: 6)
                }
            }

            if let record {
                Spacer(minLength: 0)

                Text(record.moodEmoji)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)

                Text(
                    language.text(
                        "\(weatherSymbol) · 压\(record.stressLevel) · 能\(record.energyLevel)",
                        "\(weatherSymbol) · S\(record.stressLevel) · E\(record.energyLevel)"
                    )
                )
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .background(isSelected ? AppTheme.primary.opacity(0.14) : isToday ? AppTheme.primary.opacity(0.08) : AppTheme.background)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(isSelected ? AppTheme.primary : isToday ? AppTheme.primary.opacity(0.5) : AppTheme.border.opacity(isCurrentMonth ? 1 : 0.45), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .opacity(isCurrentMonth ? 1 : 0.55)
    }

    private var journalFormSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            Text(language.text("今日记录", "Today's Entry"))
                .font(AppTheme.subtitleFont)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                Text(language.text("心情", "Mood"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingSm), count: 5),
                    alignment: .leading,
                    spacing: AppTheme.spacingSm
                ) {
                    ForEach(viewModel.moodOptions, id: \.0) { option in
                        Button {
                            viewModel.mood = option.0
                        } label: {
                            VStack(spacing: 2) {
                                Text(option.1)
                                    .font(.system(size: 22))
                                Text(option.2)
                                    .font(.system(size: 11))
                                    .foregroundStyle(viewModel.mood == option.0 ? AppTheme.primary : AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(viewModel.mood == option.0 ? AppTheme.primary.opacity(0.12) : AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                                    .stroke(viewModel.mood == option.0 ? AppTheme.primary : AppTheme.border, lineWidth: viewModel.mood == option.0 ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                Text(language.text("天气", "Weather"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    ForEach(viewModel.weatherOptions, id: \.self) { item in
                        Button {
                            viewModel.weather = item
                        } label: {
                            Text(viewModel.weatherLabel(item))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(viewModel.weather == item ? AppTheme.primary : AppTheme.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(viewModel.weather == item ? AppTheme.primary.opacity(0.12) : AppTheme.background)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.weather == item ? AppTheme.primary : AppTheme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            HStack(alignment: .top, spacing: AppTheme.spacingLg) {
                levelPicker(title: language.text("压力", "Stress"), selection: $viewModel.stressLevel, color: AppTheme.warning)
                levelPicker(title: language.text("能量", "Energy"), selection: $viewModel.energyLevel, color: AppTheme.secondary)
            }

            textArea(title: language.text("日记", "Journal"), prompt: language.text("今天发生了什么？", "What happened today?"), text: $viewModel.selfTalk)
            textArea(title: language.text("吐槽", "Rant"), prompt: language.text("想吐槽什么？", "What do you want to vent about?"), text: $viewModel.drainSource)

            HStack {
                Button(language.text("保存记录", "Save Entry")) {
                    viewModel.saveRecord()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)

                Button(language.text("清空当天", "Clear Today")) {
                    viewModel.clearTodayRecord()
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .tint(AppTheme.danger)

                Spacer()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var entryAndDetailSection: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingLg) {
            journalFormSection
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .layoutPriority(1)

            calendarDetailSection
                .frame(width: 390, alignment: .topLeading)
        }
    }

    private func levelPicker(title: String, selection: Binding<Int>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: AppTheme.spacingXs) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        selection.wrappedValue = level
                    } label: {
                        Text("\(level)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selection.wrappedValue == level ? color : AppTheme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(selection.wrappedValue == level ? color.opacity(0.14) : AppTheme.background)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selection.wrappedValue == level ? color : AppTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func textArea(title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

            TextField(prompt, text: text, axis: .vertical)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .lineLimit(5...8)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Text(value.isEmpty ? language.text("未填写", "Not filled") : value)
                .font(AppTheme.bodyFont)
                .foregroundStyle(value.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailNoteBlock(title: String, icon: String, value: String, emptyText: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            Text(value.isEmpty ? emptyText : value)
                .font(AppTheme.captionFont)
                .foregroundStyle(value.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.spacingSm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                .stroke(color.opacity(0.12), lineWidth: 0.75)
        )
    }

    private func detailEmptyState(icon: String, text: String) -> some View {
        VStack(spacing: AppTheme.spacingSm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.textTertiary)
            Text(text)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AppTheme.spacingLg)
        .frame(maxWidth: .infinity)
    }

    private func capsule(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var selectedMood: (emoji: String, label: String) {
        let option = viewModel.moodOptions.first { $0.0 == viewModel.mood } ?? (4, "😐", language.text("平稳", "Steady"))
        return (option.1, option.2)
    }

    private func moodLabel(for mood: Int) -> String {
        viewModel.moodOptions.first { $0.0 == mood }?.2 ?? language.text("未知", "Unknown")
    }

    private var averageStressLabel: String {
        viewModel.stats.recordDays == 0 ? language.text("暂无", "No Data") : stressLabel(for: viewModel.stats.avgStress)
    }

    private var averageEnergyLabel: String {
        viewModel.stats.recordDays == 0 ? language.text("暂无", "No Data") : energyLabel(for: viewModel.stats.avgEnergy)
    }

    private func stressLabel(for value: Int) -> String {
        stressLabel(for: Double(value))
    }

    private func stressLabel(for value: Double) -> String {
        switch value {
        case ..<1.5: return language.text("轻松", "Low")
        case ..<2.5: return language.text("较低", "Mild")
        case ..<3.5: return language.text("适中", "Moderate")
        case ..<4.5: return language.text("偏高", "High")
        default: return language.text("较高", "Very High")
        }
    }

    private func energyLabel(for value: Int) -> String {
        energyLabel(for: Double(value))
    }

    private func energyLabel(for value: Double) -> String {
        switch value {
        case ..<1.5: return language.text("疲惫", "Very Low")
        case ..<2.5: return language.text("偏低", "Low")
        case ..<3.5: return language.text("平稳", "Steady")
        case ..<4.5: return language.text("充足", "Good")
        default: return language.text("充沛", "High")
        }
    }

    private func recordSummary(_ record: MentalCareRecord) -> String {
        language.text(
            "当天心情为\(moodLabel(for: record.mood))，天气\(viewModel.weatherLabel(record.weather))。压力为 \(record.stressLevel) 分，属于\(stressLabel(for: record.stressLevel))水平；能量为 \(record.energyLevel) 分，整体状态\(energyLabel(for: record.energyLevel))。",
            "Mood was \(moodLabel(for: record.mood)) with \(viewModel.weatherLabel(record.weather)). Stress was \(record.stressLevel), which is \(stressLabel(for: record.stressLevel)); energy was \(record.energyLevel), which is \(energyLabel(for: record.energyLevel))."
        )
    }
}
