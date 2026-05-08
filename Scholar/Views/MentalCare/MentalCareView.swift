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

                journalFormSection
                    .fadeIn(delay: 0.15)

                calendarDetailSection
                    .fadeIn(delay: 0.2)
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
        HStack(alignment: .top, spacing: AppTheme.spacingLg) {
            ModernCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                    Text(language.text("统计概览", "Statistics"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Divider()
                        .background(AppTheme.divider)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: AppTheme.spacingMd) {
                        StatCard(
                            title: language.text("记录天数", "Recorded Days"),
                            value: "\(viewModel.stats.recordDays)",
                            icon: "calendar",
                            color: AppTheme.primary
                        )

                        StatCard(
                            title: language.text("平均压力", "Avg Stress"),
                            value: String(format: "%.1f", viewModel.stats.avgStress),
                            icon: "exclamationmark.triangle",
                            color: AppTheme.warning
                        )

                        StatCard(
                            title: language.text("平均能量", "Avg Energy"),
                            value: String(format: "%.1f", viewModel.stats.avgEnergy),
                            icon: "bolt.fill",
                            color: AppTheme.secondary
                        )

                        StatCard(
                            title: language.text("写下记录", "Notes"),
                            value: "\(viewModel.stats.noteCount)",
                            icon: "text.quote",
                            color: AppTheme.success
                        )
                    }

                    Divider()
                        .background(AppTheme.divider)

                    selectedDetailCardContent
                }
            }
            .frame(width: 280, alignment: .topLeading)

            calendarSection
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
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

                HStack(spacing: AppTheme.spacingSm) {
                    capsule(text: language.text("心情 \(moodLabel(for: record.mood))", "Mood \(moodLabel(for: record.mood))"), color: AppTheme.primary)
                    capsule(text: viewModel.weatherLabel(record.weather), color: AppTheme.secondary)
                }
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
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var calendarDetailSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text(language.text("日历详情", "Calendar Detail"))
                .font(AppTheme.subtitleFont)
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.hasSelectedCalendarDate, let record = viewModel.selectedRecord {
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

                HStack(spacing: AppTheme.spacingSm) {
                    capsule(text: language.text("心情 \(moodLabel(for: record.mood))", "Mood \(moodLabel(for: record.mood))"), color: AppTheme.primary)
                    capsule(text: viewModel.weatherLabel(record.weather), color: AppTheme.secondary)
                    capsule(text: language.text("压力 \(record.stressLevel)", "Stress \(record.stressLevel)"), color: AppTheme.warning)
                    capsule(text: language.text("能量 \(record.energyLevel)", "Energy \(record.energyLevel)"), color: AppTheme.success)
                }
            } else if viewModel.hasSelectedCalendarDate {
                Text(language.text("这一天还没有心情记录。", "No mood record for this day."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(language.text("点击上方日历日期后，这里会显示当天心情、天气、压力和能量。", "Click a calendar day above to show mood, weather, stress, and energy here."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
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
                .controlSize(.mini)
                Button {
                    viewModel.selectDate(Date())
                } label: {
                    Text(language.text("今天", "Today"))
                        .font(AppTheme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                Button {
                    viewModel.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
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
                Text(record.moodEmoji)
                    .font(.system(size: 16))
                Text(weatherSymbol)
                    .font(.system(size: 11))
                Text(language.text("压\(record.stressLevel) 能\(record.energyLevel)", "S\(record.stressLevel) E\(record.energyLevel)"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
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

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 66, maximum: 76))], alignment: .leading, spacing: AppTheme.spacingSm) {
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
                            .frame(width: 66, height: 58)
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

            HStack(alignment: .top, spacing: AppTheme.spacingMd) {
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
                                    .frame(width: 58)
                                    .background(viewModel.weather == item ? AppTheme.primary.opacity(0.12) : AppTheme.background)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(viewModel.weather == item ? AppTheme.primary : AppTheme.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                levelPicker(title: language.text("压力", "Stress"), selection: $viewModel.stressLevel, color: AppTheme.warning)
                levelPicker(title: language.text("能量", "Energy"), selection: $viewModel.energyLevel, color: AppTheme.secondary)
            }

            HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                textArea(title: language.text("日记", "Journal"), prompt: language.text("今天发生了什么？", "What happened today?"), text: $viewModel.selfTalk)
                textArea(title: language.text("吐槽", "Rant"), prompt: language.text("想吐槽什么？", "What do you want to vent about?"), text: $viewModel.drainSource)
            }

            HStack {
                Button(language.text("保存记录", "Save Entry")) {
                    viewModel.saveRecord()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button(language.text("清空当天", "Clear Today")) {
                    viewModel.clearTodayRecord()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.danger)

                Spacer()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
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
                }
            }
        }
        .frame(width: 160, alignment: .leading)
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
}
