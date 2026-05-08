import Foundation
import Combine

// MARK: - Achievement ViewModel
class AchievementViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var timeRange: TimeRange = .weekly
    @Published var selectedCategory: AchievementCategory? = nil
    @Published var stats: AchievementSummaryStats = .init()

    // MARK: - Stats

    struct AchievementSummaryStats {
        var totalUnlocked: Int = 0
        var totalAchievements: Int = 0
        var overallProgress: Double = 0
        var executionUnlocked: Int = 0
        var researchUnlocked: Int = 0
        var recoveryUnlocked: Int = 0
        var supportUnlocked: Int = 0
    }

    // MARK: - Store

    private var store: AppDataStore { AppDataStore.shared }

    // MARK: - Computed Properties

    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return store.achievements.filter { $0.category == category }
        }
        return store.achievements
    }

    var achievementsByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: store.achievements, by: \.category)
    }

    var achievementsByTier: [AchievementTier: [Achievement]] {
        Dictionary(grouping: store.achievements, by: \.tier)
    }

    // MARK: - Default Achievements

    static let defaultAchievements: [Achievement] = {

        // MARK: 执行系统
        let execution: [Achievement] = [
            // 初阶
            Achievement(category: .execution, name: "完成今日任务", tier: .beginner, requirement: "累计完成3个任务", targetValue: 3),
            Achievement(category: .execution, name: "清空逾期任务", tier: .beginner, requirement: "没有未完成的逾期任务", targetValue: 1),
            // 进阶
            Achievement(category: .execution, name: "周完成10个任务", tier: .intermediate, requirement: "本周完成10个任务", targetValue: 10),
            Achievement(category: .execution, name: "今日主线明确", tier: .intermediate, requirement: "当天至少有3个今日任务", targetValue: 3),
            // 高阶
            Achievement(category: .execution, name: "月完成50个任务", tier: .advanced, requirement: "本月完成50个任务", targetValue: 50),
            Achievement(category: .execution, name: "任务系统稳定", tier: .advanced, requirement: "累计完成100个任务", targetValue: 100),
        ]

        // MARK: 科研推进 (15)
        let research: [Achievement] = [
            // 初阶 (5)
            Achievement(category: .research, name: "完成第一个里程碑", tier: .beginner, requirement: "完成1个里程碑", targetValue: 1),
            Achievement(category: .research, name: "章节进度>0", tier: .beginner, requirement: "有1个章节进度大于0", targetValue: 1),
            Achievement(category: .research, name: "写作1000字", tier: .beginner, requirement: "累计写作1000字", targetValue: 1000),
            Achievement(category: .research, name: "形成第一条研究日志", tier: .beginner, requirement: "添加1条研究日志", targetValue: 1),
            Achievement(category: .research, name: "创建第一个投稿", tier: .beginner, requirement: "创建1个投稿记录", targetValue: 1),
            // 进阶 (5)
            Achievement(category: .research, name: "完成5个里程碑", tier: .intermediate, requirement: "完成5个里程碑", targetValue: 5),
            Achievement(category: .research, name: "完成一个章节", tier: .intermediate, requirement: "有1个章节标记为完成", targetValue: 1),
            Achievement(category: .research, name: "累计写作10000字", tier: .intermediate, requirement: "累计写作10000字", targetValue: 10000),
            Achievement(category: .research, name: "投稿进入审稿", tier: .intermediate, requirement: "有1个投稿进入审稿阶段", targetValue: 1),
            Achievement(category: .research, name: "研究主线推进过半", tier: .intermediate, requirement: "研究主线总体进度超过50%", targetValue: 50),
            // 高阶 (5)
            Achievement(category: .research, name: "完成所有里程碑", tier: .advanced, requirement: "完成全部里程碑", targetValue: 1),
            Achievement(category: .research, name: "完成所有章节", tier: .advanced, requirement: "完成全部章节", targetValue: 1),
            Achievement(category: .research, name: "累计写作50000字", tier: .advanced, requirement: "累计写作50000字", targetValue: 50000),
            Achievement(category: .research, name: "成果被接收", tier: .advanced, requirement: "有1个成果被接收", targetValue: 1),
            Achievement(category: .research, name: "研究主线完成", tier: .advanced, requirement: "研究主线总体进度达到100%", targetValue: 100),
        ]

        // MARK: 身心恢复 (12)
        let recovery: [Achievement] = [
            // 初阶 (4)
            Achievement(category: .recovery, name: "记录心理健康", tier: .beginner, requirement: "累计记录心理健康3天", targetValue: 3),
            Achievement(category: .recovery, name: "记录饮食", tier: .beginner, requirement: "累计记录饮食3天", targetValue: 3),
            Achievement(category: .recovery, name: "记录体重", tier: .beginner, requirement: "累计记录体重3天", targetValue: 3),
            Achievement(category: .recovery, name: "完成一个习惯", tier: .beginner, requirement: "累计完成习惯打卡3次", targetValue: 3),
            // 进阶 (4)
            Achievement(category: .recovery, name: "连续7天心理记录", tier: .intermediate, requirement: "连续7天记录心理健康", targetValue: 7),
            Achievement(category: .recovery, name: "连续7天饮食记录", tier: .intermediate, requirement: "连续7天记录饮食", targetValue: 7),
            Achievement(category: .recovery, name: "运动5次", tier: .intermediate, requirement: "累计运动5次", targetValue: 5),
            Achievement(category: .recovery, name: "所有习惯打卡", tier: .intermediate, requirement: "当天所有活跃习惯全部打卡", targetValue: 1),
            // 高阶 (4)
            Achievement(category: .recovery, name: "连续30天心理记录", tier: .advanced, requirement: "连续30天记录心理健康", targetValue: 30),
            Achievement(category: .recovery, name: "连续30天饮食记录", tier: .advanced, requirement: "连续30天记录饮食", targetValue: 30),
            Achievement(category: .recovery, name: "累计运动50次", tier: .advanced, requirement: "累计运动50次", targetValue: 50),
            Achievement(category: .recovery, name: "连续30天所有习惯", tier: .advanced, requirement: "连续30天所有活跃习惯全部打卡", targetValue: 30),
        ]

        // MARK: 心理维护 (4)
        let support: [Achievement] = [
            // 初阶 (1)
            Achievement(category: .support, name: "写下感恩", tier: .beginner, requirement: "累计3天写下感恩", targetValue: 3),
            // 进阶 (1)
            Achievement(category: .support, name: "平均压力<3", tier: .intermediate, requirement: "心理健康平均压力值低于3", targetValue: 1),
            // 高阶 (1)
            Achievement(category: .support, name: "所有成就解锁", tier: .advanced, requirement: "解锁全部其他成就", targetValue: 1),
        ]

        return execution + research + recovery + support
    }()

    // MARK: - Load Data

    func loadData() {
        removeDeprecatedAchievements()
        if store.achievements.isEmpty {
            store.achievements = Self.defaultAchievements
            store.save()
        }
        computeStats()
    }

    // MARK: - Compute Stats

    func computeStats() {
        let all = store.achievements
        let unlocked = all.filter(\.isUnlocked)

        stats = AchievementSummaryStats(
            totalUnlocked: unlocked.count,
            totalAchievements: all.count,
            overallProgress: all.isEmpty ? 0 : unlocked.count > 0
                ? Double(unlocked.count) / Double(all.count)
                : 0,
            executionUnlocked: unlocked.filter { $0.category == .execution }.count,
            researchUnlocked: unlocked.filter { $0.category == .research }.count,
            recoveryUnlocked: unlocked.filter { $0.category == .recovery }.count,
            supportUnlocked: unlocked.filter { $0.category == .support }.count
        )
    }

    // MARK: - Refresh Achievements

    func refreshAchievements() {
        // 预计算常用数据
        let completedTasks = store.tasks.filter { $0.status == .completed }
        let completedTaskCount = completedTasks.count
        let overdueOpenTasks = store.tasks.filter(\.isOverdue).count
        let todayTaskCount = store.tasks.filter(\.isToday).count

        // 本周完成的任务
        let weekRange = Date().startOfWeek..<Date().endOfWeek
        let weeklyCompletedTasks = completedTasks.filter { $0.updatedAt >= weekRange.lowerBound && $0.updatedAt <= weekRange.upperBound }.count

        // 本月完成的任务
        let monthRange = Date().startOfMonth..<Date().endOfMonth
        let monthlyCompletedTasks = completedTasks.filter { $0.updatedAt >= monthRange.lowerBound && $0.updatedAt <= monthRange.upperBound }.count

        // 科研数据
        var allMilestones: [Milestone] = []
        var allChapters: [Chapter] = []
        var totalWordCount = 0
        var thesisOverallProgress: Double = 0
        for thesis in store.thesisInfos {
            allMilestones.append(contentsOf: thesis.milestones)
            allChapters.append(contentsOf: thesis.chapters)
            totalWordCount += thesis.logs.reduce(0) { $0 + $1.wordCount }
            thesisOverallProgress = max(thesisOverallProgress, thesis.overallProgress)
        }
        let completedMilestones = allMilestones.filter(\.isCompleted).count
        let totalMilestones = allMilestones.count
        let chaptersWithProgress = allChapters.filter { $0.progress > 0 }.count
        let completedChapters = allChapters.filter { $0.status == .completed }.count
        let totalChapters = allChapters.count
        let thesisLogsCount = store.thesisInfos.reduce(0) { $0 + $1.logs.count }
        let submissionCount = store.submissions.count
        let underReviewCount = store.submissions.filter { $0.stage == .underReview }.count
        let acceptedCount = store.submissions.filter { $0.stage == .accepted }.count

        // 身心恢复数据
        let mentalDates = Set(store.mentalCareRecords.map { Calendar.current.startOfDay(for: $0.date) })
        let mentalDatesSorted = mentalDates.sorted()
        let maxConsecutiveMental = maxConsecutiveDays(from: mentalDatesSorted)

        let dietDates = Set(store.healthRecords
            .filter { $0.mealType != nil }
            .map { Calendar.current.startOfDay(for: $0.date) })
        let dietDatesSorted = dietDates.sorted()
        let maxConsecutiveDiet = maxConsecutiveDays(from: dietDatesSorted)

        let weightDates = Set(store.healthRecords
            .filter { $0.weightValue != nil }
            .map { Calendar.current.startOfDay(for: $0.date) })

        let habitCheckinCount = store.healthRecords.filter { record in
            store.healthHabits.contains(where: { $0.id == record.habitId })
        }.count

        let exerciseCount = store.healthRecords.filter { $0.durationValue != nil && $0.durationValue! > 0 }.count

        let activeHabits = store.healthHabits.filter(\.isActive)
        let allHabitsCompletedToday: Bool = {
            guard !activeHabits.isEmpty else { return false }
            let todayRange = Date().startOfDay..<Date().endOfDay
            return activeHabits.allSatisfy { habit in
                store.healthRecords.contains { $0.habitId == habit.id && $0.date >= todayRange.lowerBound && $0.date <= todayRange.upperBound }
            }
        }()

        // 连续N天所有习惯打卡
        let consecutiveAllHabits = computeConsecutiveAllHabitsDays(activeHabits: activeHabits)

        // 心理维护数据
        let gratitudeDates = Set(store.mentalCareRecords
            .filter { $0.gratitude.trimmingCharacters(in: .whitespaces).isNotEmpty }
            .map { Calendar.current.startOfDay(for: $0.date) })

        let avgStressBelow3: Bool = {
            guard !store.mentalCareRecords.isEmpty else { return false }
            let avg = Double(store.mentalCareRecords.reduce(0) { $0 + $1.stressLevel }) / Double(store.mentalCareRecords.count)
            return avg < 3.0
        }()

        // 遍历所有成就，更新 currentValue 和 isUnlocked
        for i in 0..<store.achievements.count {
            var achievement = store.achievements[i]
            let newValue: Int

            switch (achievement.category, achievement.name) {

            // MARK: 执行系统
            case (.execution, "完成今日任务"):
                newValue = completedTaskCount
            case (.execution, "清空逾期任务"):
                newValue = overdueOpenTasks == 0 ? 1 : 0
            case (.execution, "周完成10个任务"):
                newValue = weeklyCompletedTasks
            case (.execution, "今日主线明确"):
                newValue = todayTaskCount
            case (.execution, "月完成50个任务"):
                newValue = monthlyCompletedTasks
            case (.execution, "任务系统稳定"):
                newValue = completedTaskCount

            // MARK: 科研推进
            case (.research, "完成第一个里程碑"):
                newValue = completedMilestones
            case (.research, "章节进度>0"):
                newValue = chaptersWithProgress
            case (.research, "写作1000字"):
                newValue = totalWordCount
            case (.research, "形成第一条研究日志"):
                newValue = thesisLogsCount
            case (.research, "创建第一个投稿"):
                newValue = submissionCount
            case (.research, "完成5个里程碑"):
                newValue = completedMilestones
            case (.research, "完成一个章节"):
                newValue = completedChapters
            case (.research, "累计写作10000字"):
                newValue = totalWordCount
            case (.research, "投稿进入审稿"):
                newValue = underReviewCount
            case (.research, "研究主线推进过半"):
                newValue = Int(thesisOverallProgress * 100)
            case (.research, "完成所有里程碑"):
                newValue = (totalMilestones > 0 && completedMilestones == totalMilestones) ? 1 : 0
            case (.research, "完成所有章节"):
                newValue = (totalChapters > 0 && completedChapters == totalChapters) ? 1 : 0
            case (.research, "累计写作50000字"):
                newValue = totalWordCount
            case (.research, "成果被接收"):
                newValue = acceptedCount
            case (.research, "研究主线完成"):
                newValue = Int(thesisOverallProgress * 100)

            // MARK: 身心恢复
            case (.recovery, "记录心理健康"):
                newValue = mentalDates.count
            case (.recovery, "记录饮食"):
                newValue = dietDates.count
            case (.recovery, "记录体重"):
                newValue = weightDates.count
            case (.recovery, "完成一个习惯"):
                newValue = habitCheckinCount
            case (.recovery, "连续7天心理记录"):
                newValue = maxConsecutiveMental
            case (.recovery, "连续7天饮食记录"):
                newValue = maxConsecutiveDiet
            case (.recovery, "运动5次"):
                newValue = exerciseCount
            case (.recovery, "所有习惯打卡"):
                newValue = allHabitsCompletedToday ? 1 : 0
            case (.recovery, "连续30天心理记录"):
                newValue = maxConsecutiveMental
            case (.recovery, "连续30天饮食记录"):
                newValue = maxConsecutiveDiet
            case (.recovery, "累计运动50次"):
                newValue = exerciseCount
            case (.recovery, "连续30天所有习惯"):
                newValue = consecutiveAllHabits

            // MARK: 心理维护
            case (.support, "写下感恩"):
                newValue = gratitudeDates.count
            case (.support, "平均压力<3"):
                newValue = avgStressBelow3 ? 1 : 0
            case (.support, "所有成就解锁"):
                // 除自身外所有成就均已解锁
                let otherUnlocked = store.achievements.enumerated()
                    .filter { $0.offset != i && $0.element.name != "所有成就解锁" }
                    .allSatisfy { $0.element.isUnlocked }
                newValue = otherUnlocked ? 1 : 0

            default:
                newValue = achievement.currentValue
            }

            achievement.currentValue = newValue

            if newValue >= achievement.targetValue && !achievement.isUnlocked {
                achievement.isUnlocked = true
                achievement.unlockedAt = Date()
            }

            store.achievements[i] = achievement
        }

        store.save()
        computeStats()
    }

    // MARK: - Private Helpers

    private func removeDeprecatedAchievements() {
        let deprecatedNames: Set<String> = [
            "早起打卡",
            "专注30分钟",
            "连续7天早起",
            "累计专注10小时",
            "连续30天早起",
            "累计专注100小时",
            "累计专注500小时"
        ]
        let originalCount = store.achievements.count
        store.achievements.removeAll { deprecatedNames.contains($0.name) }

        let existingNames = Set(store.achievements.map(\.name))
        let missingDefaults = Self.defaultAchievements.filter { !existingNames.contains($0.name) }
        if !missingDefaults.isEmpty {
            store.achievements.append(contentsOf: missingDefaults)
        }

        if store.achievements.count != originalCount || !missingDefaults.isEmpty {
            store.save()
        }
    }

    /// 计算从最近日期往回的最大连续天数
    private func maxConsecutiveDays(from sortedDates: [Date]) -> Int {
        guard !sortedDates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var maxStreak = 1
        var currentStreak = 1

        for i in (1..<sortedDates.count).reversed() {
            let diff = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        // 检查连续到今天
        let today = calendar.startOfDay(for: Date())
        if let lastDate = sortedDates.last {
            let daysDiff = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysDiff > 1 {
                // 不连续到今天，只返回历史最大连续
                return maxStreak
            }
        }

        return maxStreak
    }

    /// 计算连续N天所有活跃习惯全部打卡的天数
    private func computeConsecutiveAllHabitsDays(activeHabits: [HealthHabit]) -> Int {
        guard !activeHabits.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 找到最早的打卡日期
        let allRecordDates = Set(store.healthRecords
            .filter { record in activeHabits.contains(where: { $0.id == record.habitId }) }
            .map { calendar.startOfDay(for: $0.date) })

        guard !allRecordDates.isEmpty else { return 0 }

        let sortedDates = allRecordDates.sorted()
        guard let earliest = sortedDates.first else { return 0 }

        // 从今天往回逐天检查
        var consecutiveDays = 0
        var checkDate = today

        while checkDate >= earliest {
            let allCompleted = activeHabits.allSatisfy { habit in
                store.healthRecords.contains { $0.habitId == habit.id && calendar.isDate($0.date, inSameDayAs: checkDate) }
            }
            if allCompleted {
                consecutiveDays += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = calendar.startOfDay(for: prev)
            } else {
                break
            }
        }

        return consecutiveDays
    }
}
