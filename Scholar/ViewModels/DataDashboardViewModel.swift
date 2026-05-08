import Foundation
import Combine

struct KPIData {
    var activeProjects: Int = 0
    var activeTopics: Int = 0
    var openTasks: Int = 0
    var dueSoonTasks: Int = 0
    var completedTasks: Int = 0
    var submissionActions: Int = 0
    var habitCompletionRate: Double = 0
    var mentalCareCount: Int = 0
    var activeSubmissions: Int = 0
}

struct ModuleCoverageItem {
    var moduleName: String
    var hasData: Bool
    var recordCount: Int
    var coverageRate: Double
}

class DataDashboardViewModel: ObservableObject {
    @Published var timeRange: TimeRange = .weekly
    @Published var kpiData: KPIData = .init()
    @Published var moduleCoverage: [ModuleCoverageItem] = []
    @Published var highlights: [String] = []

    private var store: AppDataStore { AppDataStore.shared }
    private var language: AppLanguage { AppLanguage.storedPreference }

    func loadData() {
        computeKPI()
        computeModuleCoverage()
        computeHighlights()
    }

    func computeKPI() {
        let dr = store.dateRange(for: timeRange)
        var kpi = KPIData()

        let activeTasks = store.tasks.filter { $0.status != .completed }
        kpi.activeProjects = store.projects.filter(\.isActive).count
        kpi.activeTopics = store.thesisInfos.filter { $0.overallProgress < 1.0 }.count
        kpi.openTasks = activeTasks.count
        kpi.dueSoonTasks = activeTasks
            .filter { $0.dueDate != nil && $0.dueDate! >= Date() && $0.dueDate! <= Date().addingTimeInterval(7 * 24 * 60 * 60) }
            .count

        kpi.completedTasks = store.tasks
            .filter { $0.status == .completed && $0.updatedAt >= dr.lowerBound && $0.updatedAt <= dr.upperBound }
            .count

        kpi.submissionActions = store.submissions
            .flatMap { $0.logs }
            .filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            .count

        let activeHabits = store.healthHabits.filter(\.isActive)
        if !activeHabits.isEmpty {
            let completed = activeHabits.filter { habit in
                store.healthRecords.contains { $0.habitId == habit.id && $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            }.count
            kpi.habitCompletionRate = Double(completed) / Double(activeHabits.count)
        }

        kpi.mentalCareCount = store.mentalCareRecords
            .filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            .count

        kpi.activeSubmissions = store.submissions.filter(\.isActive).count
        kpiData = kpi
    }

    func computeModuleCoverage() {
        let dr = store.dateRange(for: timeRange)
        let daysCount = max(1, Calendar.current.dateComponents([.day], from: dr.lowerBound, to: dr.upperBound).day ?? 1)

        let projectActivityCount = store.tasks
            .filter { $0.updatedAt >= dr.lowerBound && $0.updatedAt <= dr.upperBound }
            .count + store.projects.filter { $0.updatedAt >= dr.lowerBound && $0.updatedAt <= dr.upperBound }.count
        let topicActivityCount = store.thesisInfos
            .filter { thesis in
                thesis.logs.contains { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
                || store.tasks.contains { $0.thesisId == thesis.id && $0.updatedAt >= dr.lowerBound && $0.updatedAt <= dr.upperBound }
            }
            .count
        let submissionCount = store.submissions
            .filter { $0.createdAt >= dr.lowerBound && $0.createdAt <= dr.upperBound }
            .count
        let healthCount = store.healthRecords
            .filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            .count
        let mentalCareCount = store.mentalCareRecords
            .filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            .count

        moduleCoverage = [
            ModuleCoverageItem(
                moduleName: language.text("项目管理", "Projects"),
                hasData: projectActivityCount > 0,
                recordCount: projectActivityCount,
                coverageRate: min(1.0, Double(projectActivityCount) / Double(daysCount))
            ),
            ModuleCoverageItem(
                moduleName: language.text("课题管理", "Topics"),
                hasData: topicActivityCount > 0,
                recordCount: topicActivityCount,
                coverageRate: min(1.0, Double(topicActivityCount) / Double(daysCount))
            ),
            ModuleCoverageItem(
                moduleName: language.text("成果管理", "Submissions"),
                hasData: submissionCount > 0,
                recordCount: submissionCount,
                coverageRate: min(1.0, Double(submissionCount) / Double(daysCount))
            ),
            ModuleCoverageItem(
                moduleName: language.text("生活与健康", "Health"),
                hasData: healthCount > 0,
                recordCount: healthCount,
                coverageRate: min(1.0, Double(healthCount) / Double(daysCount))
            ),
            ModuleCoverageItem(
                moduleName: language.text("天气与心情", "Mood & Weather"),
                hasData: mentalCareCount > 0,
                recordCount: mentalCareCount,
                coverageRate: min(1.0, Double(mentalCareCount) / Double(daysCount))
            )
        ]
    }

    func computeHighlights() {
        var items: [String] = []

        if kpiData.activeProjects > 0 {
            items.append(language.text("当前有 \(kpiData.activeProjects) 条活跃项目线", "\(kpiData.activeProjects) active project workstreams"))
        }

        if kpiData.completedTasks > 0 {
            items.append(language.text("已完成 \(kpiData.completedTasks) 个任务", "\(kpiData.completedTasks) tasks completed"))
        }

        let dr = store.dateRange(for: timeRange)
        let mentalCareDates = store.mentalCareRecords
            .filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
            .map { Calendar.current.startOfDay(for: $0.date) }
            .sorted()
        let consecutiveDays = countConsecutiveDays(from: mentalCareDates)
        if consecutiveDays >= 2 {
            items.append(language.text("连续 \(consecutiveDays) 天记录了天气与心情", "Recorded mood & weather for \(consecutiveDays) consecutive days"))
        } else if kpiData.mentalCareCount > 0 {
            items.append(language.text("记录了 \(kpiData.mentalCareCount) 次天气与心情", "Recorded mood & weather \(kpiData.mentalCareCount) times"))
        }

        if kpiData.habitCompletionRate > 0 {
            items.append(language.text("生活习惯完成率为 \(Int(kpiData.habitCompletionRate * 100))%", "Habit completion rate is \(Int(kpiData.habitCompletionRate * 100))%"))
        }

        if kpiData.submissionActions > 0 {
            items.append(language.text("成果提交流程推进了 \(kpiData.submissionActions) 次", "Submission workflow advanced \(kpiData.submissionActions) times"))
        }

        let dueSoonTasks = store.tasks
            .filter { $0.status != .completed && $0.dueDate != nil && $0.dueDate! >= Date() && $0.dueDate! <= Date().addingTimeInterval(7 * 24 * 60 * 60) }
            .count
        if dueSoonTasks > 0 {
            items.append(language.text("未来 7 天有 \(dueSoonTasks) 个任务即将到期", "\(dueSoonTasks) tasks are due within the next 7 days"))
        }

        highlights = Array(items.prefix(5))
    }

    private func countConsecutiveDays(from sortedDates: [Date]) -> Int {
        guard !sortedDates.isEmpty else { return 0 }
        var count = 1
        let calendar = Calendar.current
        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}
