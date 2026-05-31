import Foundation

private var appLanguage: AppLanguage { AppLanguage.storedPreference }

// MARK: - 打卡类型
enum CheckInType: String, Codable, CaseIterable {
    case work = "work"
    case leave = "leave"

    var displayName: String {
        switch self {
        case .work: return appLanguage.text("工作", "Work")
        case .leave: return appLanguage.text("请假", "Leave")
        }
    }
}

// MARK: - 请假类型
enum LeaveType: String, Codable, CaseIterable {
    case sick = "sick"
    case personal = "personal"
    case other = "other"

    var displayName: String {
        switch self {
        case .sick: return appLanguage.text("病假", "Sick Leave")
        case .personal: return appLanguage.text("事假", "Personal Leave")
        case .other: return appLanguage.text("其他", "Other")
        }
    }
}

// MARK: - 任务优先级
enum TaskPriority: String, Codable, CaseIterable {
    case urgentImportant = "urgent_important"
    case important = "important"
    case urgent = "urgent"
    case low = "low"

    var displayName: String {
        switch self {
        case .urgentImportant: return appLanguage.text("紧急且重要", "Urgent & Important")
        case .important: return appLanguage.text("重要不紧急", "Important, Not Urgent")
        case .urgent: return appLanguage.text("紧急不重要", "Urgent, Not Important")
        case .low: return appLanguage.text("不紧急不重要", "Low Priority")
        }
    }

    var shortName: String {
        switch self {
        case .urgentImportant: return "Q1"
        case .important: return "Q2"
        case .urgent: return "Q3"
        case .low: return "Q4"
        }
    }

    var color: String {
        switch self {
        case .urgentImportant: return "EF4444"
        case .important: return "F59E0B"
        case .urgent: return "3B82F6"
        case .low: return "6B7280"
        }
    }
}

// MARK: - 任务状态
enum TaskStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .notStarted: return appLanguage.text("未开始", "Not Started")
        case .inProgress: return appLanguage.text("进行中", "In Progress")
        case .completed: return appLanguage.text("已完成", "Completed")
        }
    }
}

// MARK: - 任务循环
enum TaskRecurrence: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .none: return appLanguage.text("不循环", "None")
        case .daily: return appLanguage.text("每天", "Daily")
        case .weekly: return appLanguage.text("每周", "Weekly")
        case .monthly: return appLanguage.text("每月", "Monthly")
        }
    }
}

// MARK: - 项目分类
enum ProjectCategory: String, Codable, CaseIterable {
    case horizontal = "horizontal"
    case vertical = "vertical"
    case thesis = "thesis"
    case publication = "publication"
    case teaching = "teaching"
    case studentMentoring = "student_mentoring"
    case service = "service"
    case grant = "grant"
    case health = "health"
    case other = "other"

    static var allCases: [ProjectCategory] {
        [.horizontal, .vertical]
    }

    var displayName: String {
        switch self {
        case .horizontal: return appLanguage.text("横向项目", "Horizontal Project")
        case .vertical: return appLanguage.text("纵向项目", "Vertical Project")
        case .thesis: return appLanguage.text("科研/课题", "Research / Topics")
        case .publication: return appLanguage.text("成果/投稿", "Outcomes / Submission")
        case .teaching: return appLanguage.text("教学/课程", "Teaching / Courses")
        case .studentMentoring: return appLanguage.text("学生指导", "Student Mentoring")
        case .service: return appLanguage.text("行政/服务", "Admin / Service")
        case .grant: return appLanguage.text("基金/经费", "Grants / Funding")
        case .health: return appLanguage.text("生活/健康", "Life / Health")
        case .other: return appLanguage.text("协作/其他", "Collaboration / Other")
        }
    }
}

// MARK: - 项目阶段
enum ProjectStage: String, Codable, CaseIterable {
    case ideation = "ideation"
    case planning = "planning"
    case inProgress = "in_progress"
    case reviewing = "reviewing"
    case completed = "completed"
    case paused = "paused"

    var displayName: String {
        switch self {
        case .ideation: return appLanguage.text("构思中", "Ideation")
        case .planning: return appLanguage.text("规划中", "Planning")
        case .inProgress: return appLanguage.text("执行中", "Executing")
        case .reviewing: return appLanguage.text("整理中", "Reviewing")
        case .completed: return appLanguage.text("已完成", "Completed")
        case .paused: return appLanguage.text("已暂停", "Paused")
        }
    }
}

// MARK: - 项目优先级
enum ProjectPriority: String, Codable, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .critical: return appLanguage.text("核心", "Critical")
        case .high: return appLanguage.text("高", "High")
        case .medium: return appLanguage.text("中", "Medium")
        case .low: return appLanguage.text("低", "Low")
        }
    }
}

// MARK: - 课题阶段
enum ThesisStage: String, Codable, CaseIterable {
    case literatureReview = "literature_review"
    case problemDefinition = "problem_definition"
    case schemeDesign = "scheme_design"
    case experiment = "experiment"
    case paperWriting = "paper_writing"
    case submissionPreparation = "submission_preparation"
    case submitted = "submitted"

    var displayName: String {
        switch self {
        case .literatureReview: return appLanguage.text("文献调研", "Literature Review")
        case .problemDefinition: return appLanguage.text("问题凝练", "Problem Definition")
        case .schemeDesign: return appLanguage.text("方案设计", "Scheme Design")
        case .experiment: return appLanguage.text("实验推进", "Experiment")
        case .paperWriting: return appLanguage.text("论文撰写", "Paper Writing")
        case .submissionPreparation: return appLanguage.text("投稿准备", "Submission Prep")
        case .submitted: return appLanguage.text("已投稿", "Submitted")
        }
    }
}

// MARK: - 章节状态
enum ChapterStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case revising = "revising"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .draft: return appLanguage.text("草稿", "Draft")
        case .revising: return appLanguage.text("修改中", "Revising")
        case .completed: return appLanguage.text("完成", "Completed")
        }
    }
}

// MARK: - 投稿阶段
enum SubmissionStage: String, Codable, CaseIterable {
    case preparing = "preparing"
    case writing = "writing"
    case submitted = "submitted"
    case underReview = "under_review"
    case revising = "revising"
    case accepted = "accepted"
    case published = "published"
    case rejected = "rejected"

    var displayName: String {
        switch self {
        case .preparing: return appLanguage.text("准备中", "Preparing")
        case .writing: return appLanguage.text("写作中", "Writing")
        case .submitted: return appLanguage.text("投稿中", "Submitted")
        case .underReview: return appLanguage.text("审稿中", "Under Review")
        case .revising: return appLanguage.text("修改中", "Revising")
        case .accepted: return appLanguage.text("已接收", "Accepted")
        case .published: return appLanguage.text("已发表", "Published")
        case .rejected: return appLanguage.text("已拒绝", "Rejected")
        }
    }

    var isActive: Bool {
        switch self {
        case .accepted, .published, .rejected: return false
        default: return true
        }
    }
}

// MARK: - 论文状态
enum PaperStatus: String, Codable, CaseIterable {
    case submitted = "submitted"
    case underReview = "under_review"
    case firstRound = "first_round"
    case secondRound = "second_round"
    case thirdRound = "third_round"
    case accepted = "accepted"

    var displayName: String {
        switch self {
        case .submitted: return appLanguage.text("投递", "Submitted")
        case .underReview: return appLanguage.text("审稿", "Under Review")
        case .firstRound: return appLanguage.text("一轮", "First Round")
        case .secondRound: return appLanguage.text("二轮", "Second Round")
        case .thirdRound: return appLanguage.text("三轮", "Third Round")
        case .accepted: return appLanguage.text("录用", "Accepted")
        }
    }
}

// MARK: - 专利状态
enum PatentStatus: String, Codable, CaseIterable {
    case fastPreliminary = "fast_preliminary"
    case submitted = "submitted"
    case accepted = "accepted"
    case published = "published"
    case authorized = "authorized"

    var displayName: String {
        switch self {
        case .fastPreliminary: return appLanguage.text("快速预审", "Fast Preliminary")
        case .submitted: return appLanguage.text("提交", "Submitted")
        case .accepted: return appLanguage.text("受理", "Accepted")
        case .published: return appLanguage.text("公开", "Published")
        case .authorized: return appLanguage.text("授权", "Authorized")
        }
    }
}

// MARK: - CCF 分级
enum CCFGrade: String, Codable, CaseIterable {
    case none = "none"
    case a = "a"
    case b = "b"
    case c = "c"

    var displayName: String {
        switch self {
        case .none: return appLanguage.text("未分级", "Unrated")
        case .a: return "CCF A"
        case .b: return "CCF B"
        case .c: return "CCF C"
        }
    }
}

// MARK: - SCI 分区
enum SCIGrade: String, Codable, CaseIterable {
    case none = "none"
    case q1 = "q1"
    case q2 = "q2"
    case q3 = "q3"
    case q4 = "q4"

    var displayName: String {
        switch self {
        case .none: return appLanguage.text("未分区", "Unranked")
        case .q1: return appLanguage.text("一区", "Q1")
        case .q2: return appLanguage.text("二区", "Q2")
        case .q3: return appLanguage.text("三区", "Q3")
        case .q4: return appLanguage.text("四区", "Q4")
        }
    }
}

// MARK: - 成果类型
enum ResearchOutcomeType: String, Codable, CaseIterable {
    case paper = "paper"
    case patent = "patent"
    case award = "award"
    case other = "other"

    var displayName: String {
        switch self {
        case .paper: return appLanguage.text("论文", "Paper")
        case .patent: return appLanguage.text("专利", "Patent")
        case .award: return appLanguage.text("奖项", "Award")
        case .other: return appLanguage.text("其他", "Other")
        }
    }
}

// MARK: - 健康记录类型
enum HealthRecordType: String, Codable, CaseIterable {
    case time = "time"
    case duration = "duration"
    case checkin = "checkin"
    case count = "count"
    case text = "text"

    var displayName: String {
        switch self {
        case .time: return appLanguage.text("时间", "Time")
        case .duration: return appLanguage.text("时长", "Duration")
        case .checkin: return appLanguage.text("打卡", "Check-in")
        case .count: return appLanguage.text("次数", "Count")
        case .text: return appLanguage.text("文字", "Text")
        }
    }
}

// MARK: - 餐次
enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return appLanguage.text("早餐", "Breakfast")
        case .lunch: return appLanguage.text("午餐", "Lunch")
        case .dinner: return appLanguage.text("晚餐", "Dinner")
        case .snack: return appLanguage.text("加餐", "Snack")
        }
    }
}

// MARK: - 沟通方式
enum CommunicationMethod: String, Codable, CaseIterable {
    case faceToFace = "face_to_face"
    case email = "email"
    case video = "video"
    case phone = "phone"
    case instantMessage = "instant_message"

    var displayName: String {
        switch self {
        case .faceToFace: return appLanguage.text("面对面", "Face to Face")
        case .email: return appLanguage.text("邮件", "Email")
        case .video: return appLanguage.text("视频", "Video")
        case .phone: return appLanguage.text("电话", "Phone")
        case .instantMessage: return appLanguage.text("即时通讯", "Instant Message")
        }
    }
}

// MARK: - 沟通状态
enum CommunicationStatus: String, Codable, CaseIterable {
    case completed = "completed"
    case pending = "pending"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .completed: return appLanguage.text("已完成", "Completed")
        case .pending: return appLanguage.text("待跟进", "Pending")
        case .cancelled: return appLanguage.text("已取消", "Cancelled")
        }
    }
}

// MARK: - 追踪状态
enum TrackingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case reminded = "reminded"
    case resolved = "resolved"

    var displayName: String {
        switch self {
        case .pending: return appLanguage.text("待核对", "Pending Review")
        case .reminded: return appLanguage.text("需提醒", "Needs Reminder")
        case .resolved: return appLanguage.text("已落实", "Resolved")
        }
    }
}

// MARK: - 成就分类
enum AchievementCategory: String, Codable, CaseIterable {
    case execution = "execution"
    case research = "research"
    case recovery = "recovery"
    case support = "support"

    var displayName: String {
        switch self {
        case .execution: return appLanguage.text("执行系统", "Execution")
        case .research: return appLanguage.text("科研推进", "Research")
        case .recovery: return appLanguage.text("身心恢复", "Recovery")
        case .support: return appLanguage.text("支持体系", "Support")
        }
    }

    var color: String {
        switch self {
        case .execution: return "8B5CF6"
        case .research: return "10B981"
        case .recovery: return "EC4899"
        case .support: return "3B82F6"
        }
    }
}

// MARK: - 成就等级
enum AchievementTier: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .beginner: return appLanguage.text("初阶", "Beginner")
        case .intermediate: return appLanguage.text("进阶", "Intermediate")
        case .advanced: return appLanguage.text("高阶", "Advanced")
        }
    }
}

// MARK: - 时间范围
enum TimeRange: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily: return appLanguage.text("每日", "Daily")
        case .weekly: return appLanguage.text("每周", "Weekly")
        case .monthly: return appLanguage.text("每月", "Monthly")
        }
    }
}

// MARK: - 专注状态
enum FocusTimerState {
    case idle
    case running
    case paused
}
