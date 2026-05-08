import Foundation
import Combine

class HealthViewModel: ObservableObject {
    enum WeightRange: String, CaseIterable {
        case week = "7天"
        case month = "1个月"
        case halfYear = "半年"
        case year = "1年"

        var displayName: String {
            switch self {
            case .week: return AppLanguage.storedPreference.text("7天", "7 Days")
            case .month: return AppLanguage.storedPreference.text("1个月", "1 Month")
            case .halfYear: return AppLanguage.storedPreference.text("半年", "6 Months")
            case .year: return AppLanguage.storedPreference.text("1年", "1 Year")
            }
        }

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .halfYear: return 180
            case .year: return 365
            }
        }
    }

    struct HealthStats {
        var completedHabits: Int = 0
        var activeHabitCount: Int = 0
        var totalCheckins: Int = 0
        var totalDurationMinutes: Int = 0
    }

    @Published var timeRange: TimeRange = .weekly
    @Published var showTodayView: Bool = false
    @Published var showNewHabitForm: Bool = false
    @Published var newHabitName: String = ""
    @Published var newHabitIcon: String = "🏃"
    @Published var newHabitRecordType: HealthRecordType = .checkin
    @Published var newHabitTargetValue: String = "1"
    @Published var showWeightForm: Bool = false
    @Published var weightValue: String = ""
    @Published var weightRange: WeightRange = .month
    @Published var stats: HealthStats = .init()

    private var store: AppDataStore { AppDataStore.shared }

    var activeHabits: [HealthHabit] {
        store.healthHabits.filter(\.isActive)
    }

    var latestWeight: Double? {
        store.healthRecords
            .filter { $0.weightValue != nil }
            .sorted { $0.date > $1.date }
            .first?.weightValue
    }

    var weightRecordsForChart: [HealthRecord] {
        let start = Calendar.current.date(byAdding: .day, value: -weightRange.days + 1, to: Date()) ?? Date()
        return store.healthRecords
            .filter { $0.weightValue != nil && $0.date >= start.startOfDay }
            .sorted { $0.date < $1.date }
    }

    var allowedHabitRecordTypes: [HealthRecordType] {
        [.checkin, .count]
    }

    func loadData() {
        computeStats()
    }

    func addHabit() {
        guard newHabitName.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let habit = HealthHabit(
            name: newHabitName.trimmingCharacters(in: .whitespaces),
            icon: newHabitIcon,
            recordType: newHabitRecordType,
            targetValue: Double(newHabitTargetValue) ?? 1
        )
        store.healthHabits.append(habit)
        store.save()
        newHabitName = ""
        newHabitIcon = "🏃"
        newHabitRecordType = .checkin
        newHabitTargetValue = "1"
        showNewHabitForm = false
        computeStats()
    }

    func toggleHabitActive(_ habit: HealthHabit) {
        if let idx = store.healthHabits.firstIndex(where: { $0.id == habit.id }) {
            store.healthHabits[idx].isActive.toggle()
            store.save()
            computeStats()
        }
    }

    func deleteHabit(_ habit: HealthHabit) {
        store.healthHabits.removeAll { $0.id == habit.id }
        store.healthRecords.removeAll { $0.habitId == habit.id }
        store.save()
        computeStats()
    }

    func addWeightRecord() {
        guard let weight = Double(weightValue), weight > 0 else { return }
        store.healthRecords.append(HealthRecord(habitId: UUID(), date: Date(), weightValue: weight))
        store.save()
        weightValue = ""
        showWeightForm = false
        computeStats()
    }

    func deleteWeightRecord(_ record: HealthRecord) {
        store.healthRecords.removeAll { $0.id == record.id }
        store.save()
        computeStats()
    }

    func addCheckin(for habit: HealthHabit) {
        guard !isHabitCompletedToday(habit) else { return }
        store.healthRecords.append(HealthRecord(habitId: habit.id, date: Date()))
        store.save()
        computeStats()
    }

    func incrementCount(for habit: HealthHabit) {
        if let idx = todayRecords(for: habit).sorted(by: { $0.date > $1.date }).first.flatMap({ record in
            store.healthRecords.firstIndex(where: { $0.id == record.id })
        }) {
            store.healthRecords[idx].countValue = (store.healthRecords[idx].countValue ?? 0) + 1
            store.healthRecords[idx].date = Date()
        } else {
            store.healthRecords.append(HealthRecord(habitId: habit.id, date: Date(), countValue: 1))
        }
        store.save()
        computeStats()
    }

    func toggleDuration(for habit: HealthHabit) {
        if let idx = openDurationRecordIndex(for: habit) {
            let start = store.healthRecords[idx].timeValue ?? store.healthRecords[idx].date
            store.healthRecords[idx].durationValue = Date().timeIntervalSince(start) / 60
            store.healthRecords[idx].date = Date()
        } else {
            store.healthRecords.append(HealthRecord(habitId: habit.id, date: Date(), timeValue: Date(), durationValue: nil))
        }
        store.save()
        computeStats()
    }

    func quickTimeRecord(for habit: HealthHabit) {
        store.healthRecords.append(HealthRecord(habitId: habit.id, date: Date(), timeValue: Date()))
        store.save()
        computeStats()
    }

    func isHabitCompletedToday(_ habit: HealthHabit) -> Bool {
        !todayRecords(for: habit).isEmpty
    }

    func todayRecords(for habit: HealthHabit) -> [HealthRecord] {
        let range = Date().startOfDay..<Date().endOfDay
        return store.healthRecords.filter { $0.habitId == habit.id && $0.date >= range.lowerBound && $0.date <= range.upperBound }
    }

    func openDurationRecordIndex(for habit: HealthHabit) -> Int? {
        store.healthRecords.firstIndex {
            $0.habitId == habit.id &&
            Calendar.current.isDateInToday($0.date) &&
            $0.timeValue != nil &&
            $0.durationValue == nil
        }
    }

    func habitStatusText(_ habit: HealthHabit) -> String {
        let records = todayRecords(for: habit)
        switch habit.recordType {
        case .checkin:
            return records.isEmpty ? AppLanguage.storedPreference.text("未打卡", "Not checked in") : AppLanguage.storedPreference.text("已打卡", "Checked in")
        case .count:
            return AppLanguage.storedPreference.text("今日 \(records.reduce(0) { $0 + ($1.countValue ?? 0) }) 次", "\(records.reduce(0) { $0 + ($1.countValue ?? 0) }) today")
        case .duration:
            let minutes = Int(records.compactMap(\.durationValue).reduce(0, +))
            return minutes == 0 ? AppLanguage.storedPreference.text("未记录", "No record") : AppLanguage.storedPreference.text("今日 \(minutes) 分钟", "\(minutes) min today")
        case .time:
            return records.last?.timeValue?.timeFormatted("HH:mm") ?? AppLanguage.storedPreference.text("未记录", "No record")
        case .text:
            return AppLanguage.storedPreference.text("文本记录", "Text entry")
        }
    }

    func primaryActionTitle(for habit: HealthHabit) -> String {
        switch habit.recordType {
        case .checkin: return isHabitCompletedToday(habit) ? AppLanguage.storedPreference.text("已完成", "Done") : AppLanguage.storedPreference.text("打卡", "Check In")
        case .count: return "+1"
        case .duration: return openDurationRecordIndex(for: habit) == nil ? AppLanguage.storedPreference.text("开始", "Start") : AppLanguage.storedPreference.text("结束", "End")
        case .time: return AppLanguage.storedPreference.text("记录现在", "Record Now")
        case .text: return AppLanguage.storedPreference.text("记录", "Record")
        }
    }

    func triggerPrimaryAction(for habit: HealthHabit) {
        if habit.recordType == .count {
            incrementCount(for: habit)
        } else {
            addCheckin(for: habit)
        }
    }

    func computeStats() {
        let range = store.dateRange(for: timeRange)
        let records = store.healthRecords.filter { $0.date >= range.lowerBound && $0.date <= range.upperBound }
        stats = HealthStats(
            completedHabits: activeHabits.filter { isHabitCompletedToday($0) }.count,
            activeHabitCount: activeHabits.count,
            totalCheckins: records.filter { $0.countValue != nil || ($0.timeValue == nil && $0.durationValue == nil && $0.weightValue == nil && $0.mealType == nil) }.count,
            totalDurationMinutes: Int(records.compactMap(\.durationValue).reduce(0, +))
        )
    }
}
