import Foundation

struct Achievement: Codable, Identifiable, Hashable {
    var id: UUID
    var category: AchievementCategory
    var name: String
    var tier: AchievementTier
    var requirement: String
    var currentValue: Int
    var targetValue: Int
    var isUnlocked: Bool
    var unlockedAt: Date?

    init(id: UUID = UUID(), category: AchievementCategory = .execution, name: String = "", tier: AchievementTier = .beginner, requirement: String = "", currentValue: Int = 0, targetValue: Int = 1, isUnlocked: Bool = false, unlockedAt: Date? = nil) {
        self.id = id; self.category = category; self.name = name; self.tier = tier; self.requirement = requirement; self.currentValue = currentValue; self.targetValue = targetValue; self.isUnlocked = isUnlocked; self.unlockedAt = unlockedAt
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }

    var displayName: String {
        switch name {
        case "完成今日任务": return AppLanguage.storedPreference.text("完成今日任务", "Finish Today's Tasks")
        case "清空逾期任务": return AppLanguage.storedPreference.text("清空逾期任务", "Clear Overdue Tasks")
        case "周完成10个任务": return AppLanguage.storedPreference.text("周完成10个任务", "10 Tasks in a Week")
        case "今日主线明确": return AppLanguage.storedPreference.text("今日主线明确", "Today's Thread Set")
        case "月完成50个任务": return AppLanguage.storedPreference.text("月完成50个任务", "50 Tasks in a Month")
        case "任务系统稳定": return AppLanguage.storedPreference.text("任务系统稳定", "Stable Task System")
        case "完成第一个里程碑": return AppLanguage.storedPreference.text("完成第一个里程碑", "First Milestone")
        case "章节进度>0": return AppLanguage.storedPreference.text("章节进度>0", "Chapter Started")
        case "写作1000字": return AppLanguage.storedPreference.text("写作1000字", "Write 1,000 Words")
        case "形成第一条研究日志": return AppLanguage.storedPreference.text("形成第一条研究日志", "First Research Log")
        case "创建第一个投稿": return AppLanguage.storedPreference.text("创建第一个投稿", "First Submission")
        case "完成5个里程碑": return AppLanguage.storedPreference.text("完成5个里程碑", "Five Milestones")
        case "完成一个章节": return AppLanguage.storedPreference.text("完成一个章节", "Complete One Chapter")
        case "累计写作10000字": return AppLanguage.storedPreference.text("累计写作10000字", "Write 10,000 Words")
        case "投稿进入审稿": return AppLanguage.storedPreference.text("投稿进入审稿", "Under Review")
        case "研究主线推进过半": return AppLanguage.storedPreference.text("研究主线推进过半", "Research Over Halfway")
        case "完成所有里程碑": return AppLanguage.storedPreference.text("完成所有里程碑", "All Milestones Done")
        case "完成所有章节": return AppLanguage.storedPreference.text("完成所有章节", "All Chapters Done")
        case "累计写作50000字": return AppLanguage.storedPreference.text("累计写作50000字", "Write 50,000 Words")
        case "成果被接收": return AppLanguage.storedPreference.text("成果被接收", "Outcome Accepted")
        case "研究主线完成": return AppLanguage.storedPreference.text("研究主线完成", "Research Completed")
        case "记录心理健康": return AppLanguage.storedPreference.text("记录心理健康", "Mental Health Logs")
        case "记录饮食": return AppLanguage.storedPreference.text("记录饮食", "Meal Logs")
        case "记录体重": return AppLanguage.storedPreference.text("记录体重", "Weight Logs")
        case "完成一个习惯": return AppLanguage.storedPreference.text("完成一个习惯", "Finish a Habit")
        case "连续7天心理记录": return AppLanguage.storedPreference.text("连续7天心理记录", "7-Day Mental Logs")
        case "连续7天饮食记录": return AppLanguage.storedPreference.text("连续7天饮食记录", "7-Day Meal Logs")
        case "运动5次": return AppLanguage.storedPreference.text("运动5次", "Exercise 5 Times")
        case "所有习惯打卡": return AppLanguage.storedPreference.text("所有习惯打卡", "All Habits Done")
        case "连续30天心理记录": return AppLanguage.storedPreference.text("连续30天心理记录", "30-Day Mental Logs")
        case "连续30天饮食记录": return AppLanguage.storedPreference.text("连续30天饮食记录", "30-Day Meal Logs")
        case "累计运动50次": return AppLanguage.storedPreference.text("累计运动50次", "Exercise 50 Times")
        case "连续30天所有习惯": return AppLanguage.storedPreference.text("连续30天所有习惯", "30 Days of All Habits")
        case "写下感恩": return AppLanguage.storedPreference.text("写下感恩", "Write Gratitude")
        case "平均压力<3": return AppLanguage.storedPreference.text("平均压力<3", "Avg Stress < 3")
        case "所有成就解锁": return AppLanguage.storedPreference.text("所有成就解锁", "Unlock Everything")
        default: return name
        }
    }
}
