import Foundation
import Combine

class MentalCareViewModel: ObservableObject {
    struct MentalCareStats {
        var recordDays: Int = 0
        var avgStress: Double = 0
        var avgEnergy: Double = 0
        var noteCount: Int = 0
    }

    @Published var timeRange: TimeRange = .weekly
    @Published var mood: Int = 3
    @Published var stressLevel: Int = 3
    @Published var energyLevel: Int = 3
    @Published var weather: String = "sunny"
    @Published var drainSource: String = ""
    @Published var selfCare: String = ""
    @Published var selfTalk: String = ""
    @Published var selectedDate: Date = Date()
    @Published var hasSelectedCalendarDate: Bool = false
    @Published var displayedMonth: Date = Date().startOfMonth
    @Published var stats: MentalCareStats = .init()

    private var store: AppDataStore { AppDataStore.shared }

    var todayRecord: MentalCareRecord? {
        let today = Date()
        return store.mentalCareRecords.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var selectedRecord: MentalCareRecord? {
        record(for: selectedDate)
    }

    var recentRecords: [MentalCareRecord] {
        store.mentalCareRecords.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    var moodOptions: [(Int, String, String)] {
        [
            (1, "😫", AppLanguage.storedPreference.text("糟糕", "Awful")),
            (2, "😟", AppLanguage.storedPreference.text("焦虑", "Anxious")),
            (3, "😕", AppLanguage.storedPreference.text("低落", "Low")),
            (4, "😐", AppLanguage.storedPreference.text("平稳", "Steady")),
            (5, "😬", AppLanguage.storedPreference.text("紧张", "Tense")),
            (6, "😠", AppLanguage.storedPreference.text("生气", "Annoyed")),
            (7, "😤", AppLanguage.storedPreference.text("愤怒", "Angry")),
            (8, "🙂", AppLanguage.storedPreference.text("不错", "Good")),
            (9, "😊", AppLanguage.storedPreference.text("轻松", "Relaxed")),
            (10, "🤩", AppLanguage.storedPreference.text("很好", "Great")),
            (11, "🥺", AppLanguage.storedPreference.text("委屈", "Hurt")),
            (12, "😑", AppLanguage.storedPreference.text("无语", "Speechless")),
            (13, "🥱", AppLanguage.storedPreference.text("困倦", "Sleepy")),
            (14, "😣", AppLanguage.storedPreference.text("烦躁", "Irritated")),
            (15, "😄", AppLanguage.storedPreference.text("开心", "Happy"))
        ]
    }

    var weatherOptions: [String] {
        ["sunny", "cloudy", "overcast", "rainy", "stormy", "foggy", "windy", "snowy"]
    }

    func weatherLabel(_ key: String) -> String {
        switch key {
        case "sunny": return AppLanguage.storedPreference.text("☀️ 晴", "☀️ Sunny")
        case "cloudy": return AppLanguage.storedPreference.text("⛅️ 多云", "⛅️ Cloudy")
        case "overcast": return AppLanguage.storedPreference.text("☁️ 阴", "☁️ Overcast")
        case "rainy": return AppLanguage.storedPreference.text("🌧️ 雨", "🌧️ Rain")
        case "stormy": return AppLanguage.storedPreference.text("⛈️ 雷雨", "⛈️ Storm")
        case "foggy": return AppLanguage.storedPreference.text("🌫️ 雾", "🌫️ Fog")
        case "windy": return AppLanguage.storedPreference.text("🌬️ 风", "🌬️ Wind")
        case "snowy": return AppLanguage.storedPreference.text("❄️ 雪", "❄️ Snow")
        default: return key
        }
    }

    var monthCalendar: [Date] {
        let calendar = Calendar.current
        let startOfMonth = displayedMonth.startOfMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leading = max(0, firstWeekday - calendar.firstWeekday)
        return (0..<(42)).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - leading, to: startOfMonth)
        }
    }

    func loadData() {
        loadForm(for: selectedDate)
        computeStats()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        hasSelectedCalendarDate = true
        displayedMonth = date.startOfMonth
        loadForm(for: date)
    }

    func changeMonth(by value: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    func loadForm(for date: Date) {
        if let record = record(for: date) {
            mood = record.mood
            stressLevel = record.stressLevel
            energyLevel = record.energyLevel
            weather = record.weather
            drainSource = record.drainSource
            selfCare = record.selfCare
            selfTalk = record.selfTalk
        } else {
            mood = 4
            stressLevel = 3
            energyLevel = 3
            weather = "sunny"
            drainSource = ""
            selfCare = ""
            selfTalk = ""
        }
    }

    func saveRecord() {
        if let idx = store.mentalCareRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            store.mentalCareRecords[idx].mood = mood
            store.mentalCareRecords[idx].stressLevel = stressLevel
            store.mentalCareRecords[idx].energyLevel = energyLevel
            store.mentalCareRecords[idx].weather = weather
            store.mentalCareRecords[idx].drainSource = drainSource
            store.mentalCareRecords[idx].selfCare = selfCare
            store.mentalCareRecords[idx].selfTalk = selfTalk
        } else {
            store.mentalCareRecords.append(
                MentalCareRecord(
                    date: selectedDate,
                    mood: mood,
                    stressLevel: stressLevel,
                    energyLevel: energyLevel,
                    weather: weather,
                    drainSource: drainSource,
                    selfCare: selfCare,
                    selfTalk: selfTalk
                )
            )
        }
        store.save()
        computeStats()
    }

    func clearTodayRecord() {
        guard let record = selectedRecord else { return }
        store.mentalCareRecords.removeAll { $0.id == record.id }
        store.save()
        loadForm(for: selectedDate)
        computeStats()
    }

    func computeStats() {
        let range = store.dateRange(for: timeRange)
        let filtered = store.mentalCareRecords.filter { $0.date >= range.lowerBound && $0.date <= range.upperBound }
        let uniqueDays = Set(filtered.map { Calendar.current.startOfDay(for: $0.date) })
        stats = MentalCareStats(
            recordDays: uniqueDays.count,
            avgStress: filtered.isEmpty ? 0 : Double(filtered.reduce(0) { $0 + $1.stressLevel }) / Double(filtered.count),
            avgEnergy: filtered.isEmpty ? 0 : Double(filtered.reduce(0) { $0 + $1.energyLevel }) / Double(filtered.count),
            noteCount: filtered.filter { $0.selfTalk.isNotEmpty || $0.drainSource.isNotEmpty || $0.selfCare.isNotEmpty }.count
        )
    }

    func record(for date: Date) -> MentalCareRecord? {
        store.mentalCareRecords.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
