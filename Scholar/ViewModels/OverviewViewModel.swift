import Foundation
import Combine

class OverviewViewModel: ObservableObject {
    struct WorkbenchStats {
        var activeProjects: Int = 0
        var activeTheses: Int = 0
        var activeAffairs: Int = 0
        var todayOpenTasks: Int = 0
        var dueTodayTasks: Int = 0
        var dueSoonTasks: Int = 0
        var overdueTasks: Int = 0
        var activeSubmissions: Int = 0
    }

    struct TimelineItem: Identifiable {
        var id = UUID()
        var taskId: UUID?
        var time: Date?
        var title: String
        var subtitle: String
        var color: ColorToken
        var tone: ToneToken
        var isCompleted: Bool

        enum ColorToken {
            case primary
            case warning
            case danger
            case success
            case secondary
        }

        enum ToneToken {
            case normal
            case active
            case dueToday
            case dueSoon
            case overdue
            case schedule
        }
    }

    struct BusyDayInfo {
        var date: Date
        var totalTasks: Int
        var completedTasks: Int
        var dueTasks: Int = 0
        var overdueTasks: Int = 0
        var continuousTasks: Int = 0

        var completionRate: Double {
            guard totalTasks > 0 else { return 0 }
            return Double(completedTasks) / Double(totalTasks)
        }

        var loadSummary: Int {
            totalTasks
        }

        var level: BusyLevel {
            switch loadSummary {
            case 0:
                return .quiet
            case 1...2:
                return .light
            case 3...4:
                return .steady
            case 5...6:
                return .busy
            case 7...8:
                return .heavy
            case 9...11:
                return .packed
            default:
                return .overloaded
            }
        }
    }

    enum BusyLevel {
        case quiet
        case light
        case steady
        case busy
        case heavy
        case packed
        case overloaded
    }

    @Published var selectedDate: Date = Date()
    @Published var timeRange: TimeRange = .weekly
    @Published var focusTimerState: FocusTimerState = .idle
    @Published var focusElapsedSeconds: TimeInterval = 0
    @Published var focusStartTime: Date?
    @Published var currentFocusTaskTitle: String = ""
    @Published var focusTheme: String = "科研"
    @Published var focusNotes: String = ""
    @Published var newTaskTitle: String = ""
    @Published var showNewTaskField: Bool = false

    @Published var stats: AppDataStore.OverviewStats = .init()
    @Published var todaySnapshot: AppDataStore.TodaySnapshot = .init()
    @Published var todayCheckIns: [CheckInRecord] = []
    @Published var todayLeaves: [CheckInRecord] = []
    @Published var todayWorkDuration: TimeInterval = 0
    @Published var ongoingWorkSession: CheckInRecord?
    @Published var todayTasks: [Task] = []
    @Published var inProgressTasks: [Task] = []
    @Published var todayFocusSessions: [FocusSession] = []
    @Published var todayScheduleBlocks: [ScheduleBlock] = []
    @Published var workbenchStats: WorkbenchStats = .init()
    @Published var todayTimelineItems: [TimelineItem] = []
    @Published var tomorrowTimelineItems: [TimelineItem] = []
    @Published var displayedBusyMonth: Date = Date()

    private var timer: Timer?
    private var store: AppDataStore { AppDataStore.shared }

    func loadData() {
        stats = store.computeOverviewStats(range: timeRange, date: selectedDate)
        todaySnapshot = store.computeTodaySnapshot()
        loadTodayCheckIns()
        loadTodayTasks()
        loadTodayFocusSessions()
        loadTodayScheduleBlocks()
        loadWorkbenchStats()
        loadTodayTimeline()
        loadTomorrowTimeline()
    }

    func refreshStats() {
        stats = store.computeOverviewStats(range: timeRange, date: selectedDate)
        todaySnapshot = store.computeTodaySnapshot()
        loadWorkbenchStats()
        loadTodayTimeline()
        loadTomorrowTimeline()
    }

    var busyMonthCalendar: [Date] {
        let calendar = Calendar.current
        let startOfMonth = displayedBusyMonth.startOfMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leading = max(0, firstWeekday - calendar.firstWeekday)
        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - leading, to: startOfMonth)
        }
    }

    func changeBusyMonth(by value: Int) {
        displayedBusyMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedBusyMonth) ?? displayedBusyMonth
    }

    func busyInfo(for date: Date) -> BusyDayInfo {
        let calendar = Calendar.current
        if date.startOfDay < Date().startOfDay,
           let snapshot = store.busySnapshot(for: date) {
            let dueTasks = snapshot.dueTasks ?? snapshot.totalTasks
            let overdueTasks = snapshot.overdueTasks ?? 0
            let continuousTasks = snapshot.continuousTasks ?? 0
            return BusyDayInfo(
                date: snapshot.date,
                totalTasks: dueTasks + overdueTasks,
                completedTasks: snapshot.completedTasks,
                dueTasks: dueTasks,
                overdueTasks: overdueTasks,
                continuousTasks: continuousTasks
            )
        }

        let breakdown = store.busyTaskBreakdown(for: date, includeTodayFlag: calendar.isDateInToday(date))
        return BusyDayInfo(
            date: date,
            totalTasks: breakdown.denominatorCount,
            completedTasks: breakdown.completedTodayCount,
            dueTasks: breakdown.dueTasks.count,
            overdueTasks: breakdown.overdueTasks.count,
            continuousTasks: breakdown.continuousTasks.count
        )
    }

    func busyTasks(for date: Date) -> [Task] {
        store.busyTasks(for: date, includeTodayFlag: Calendar.current.isDateInToday(date))
    }

    // MARK: - Check-in
    private func loadTodayCheckIns() {
        let today = Date()
        let start = today.startOfDay
        let end = today.endOfDay
        todayCheckIns = store.checkInRecords.filter { $0.date >= start && $0.date <= end && $0.type == .work }
        todayLeaves = store.checkInRecords.filter { $0.date >= start && $0.date <= end && $0.type == .leave }
        todayWorkDuration = todayCheckIns.reduce(0) { $0 + $1.duration }
        ongoingWorkSession = todayCheckIns.first(where: \.isOngoing)
    }

    func startWork() {
        let record = CheckInRecord(date: Date(), type: .work, startTime: Date())
        store.checkInRecords.append(record)
        store.save()
        loadTodayCheckIns()
        refreshStats()
    }

    func endWork() {
        guard let idx = store.checkInRecords.firstIndex(where: \.isOngoing),
              let start = store.checkInRecords[idx].startTime else { return }
        store.checkInRecords[idx].endTime = Date()
        store.checkInRecords[idx].duration = Date().timeIntervalSince(start)
        store.save()
        loadTodayCheckIns()
        refreshStats()
    }

    func closeAllOngoingWork() {
        for i in store.checkInRecords.indices where store.checkInRecords[i].isOngoing {
            if let start = store.checkInRecords[i].startTime {
                store.checkInRecords[i].endTime = Date()
                store.checkInRecords[i].duration = Date().timeIntervalSince(start)
            }
        }
        store.save()
        loadTodayCheckIns()
        refreshStats()
    }

    func takeLeave(type: LeaveType) {
        let record = CheckInRecord(date: Date(), type: .leave, leaveType: type)
        store.checkInRecords.append(record)
        store.save()
        loadTodayCheckIns()
    }

    func clearTodayLeaves() {
        store.checkInRecords.removeAll { todayLeaves.contains($0) }
        store.save()
        loadTodayCheckIns()
    }

    // MARK: - Tasks
    private func loadTodayTasks() {
        todayTasks = store.tasks.filter { $0.isToday && $0.status != .completed }
        inProgressTasks = todayTasks
    }

    func addTemporaryTask() {
        guard newTaskTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let task = Task(title: newTaskTitle, isToday: true)
        store.tasks.append(task)
        store.save()
        newTaskTitle = ""
        showNewTaskField = false
        loadTodayTasks()
        refreshStats()
    }

    func startTask(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].startDate = Date()
            store.tasks[idx].updatedAt = Date()
            store.save()
        }
        loadTodayTasks()
        loadTodayTimeline()
        loadTomorrowTimeline()
        refreshStats()
    }

    func endTask(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].status = .completed
            store.tasks[idx].completionRate = 100
            store.tasks[idx].updatedAt = Date()
            store.save()
        }
        loadTodayTasks()
        loadTodayTimeline()
        loadTomorrowTimeline()
        refreshStats()
    }

    func completeTimelineTask(_ item: TimelineItem) {
        guard let taskId = item.taskId,
              let task = store.tasks.first(where: { $0.id == taskId }) else { return }
        endTask(task)
    }

    // MARK: - Focus Timer
    func startFocusTimer() {
        focusTimerState = .running
        focusStartTime = Date()
        focusElapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.focusElapsedSeconds += 1
        }
    }

    func pauseFocusTimer() {
        focusTimerState = .paused
        timer?.invalidate(); timer = nil
    }

    func resumeFocusTimer() {
        focusTimerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.focusElapsedSeconds += 1
        }
    }

    func endFocusTimer() {
        timer?.invalidate(); timer = nil
        focusTimerState = .idle
        let session = FocusSession(date: Date(), startTime: focusStartTime ?? Date(), endTime: Date(), duration: focusElapsedSeconds, taskTitle: currentFocusTaskTitle, theme: focusTheme, notes: focusNotes)
        store.focusSessions.append(session)
        if let start = focusStartTime, focusElapsedSeconds > 0 {
            let block = ScheduleBlock(date: Date(), startTime: start, endTime: Date(), taskTitle: currentFocusTaskTitle)
            store.scheduleBlocks.append(block)
        }
        store.save()
        focusElapsedSeconds = 0; focusStartTime = nil; currentFocusTaskTitle = ""; focusNotes = ""
        loadTodayFocusSessions()
        loadTodayScheduleBlocks()
        refreshStats()
    }

    func abandonFocusTimer() {
        timer?.invalidate(); timer = nil
        focusTimerState = .idle; focusElapsedSeconds = 0; focusStartTime = nil
    }

    func addManualFocus(durationMinutes: Int, taskTitle: String) {
        let now = Date()
        let start = now.addingTimeInterval(-Double(durationMinutes * 60))
        let session = FocusSession(date: now, startTime: start, endTime: now, duration: Double(durationMinutes * 60), taskTitle: taskTitle, theme: focusTheme, notes: focusNotes, isManual: true)
        store.focusSessions.append(session)
        store.save()
        loadTodayFocusSessions()
        refreshStats()
    }

    private func loadTodayFocusSessions() {
        let range = Date().startOfDay..<Date().endOfDay
        todayFocusSessions = store.focusSessions.filter { $0.date >= range.lowerBound && $0.date <= range.upperBound }.sorted { $0.startTime > $1.startTime }
    }

    private func loadTodayScheduleBlocks() {
        let range = Date().startOfDay..<Date().endOfDay
        todayScheduleBlocks = store.scheduleBlocks.filter { $0.date >= range.lowerBound && $0.date <= range.upperBound }.sorted { $0.startTime < $1.startTime }
    }

    private func loadWorkbenchStats() {
        let now = Date()
        let todayRange = now.startOfDay..<now.endOfDay
        let soon = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let activeProjectIds = Set(store.projects.filter { !$0.isArchived }.map(\.id))
        let activeThesisIds = Set(store.thesisInfos.filter { !$0.isArchived }.map(\.id))
        let activeAffairIds = Set(store.affairs.filter { !$0.isArchived }.map(\.id))
        let activeTasks = store.tasks.filter { task in
            guard task.status != .completed else { return false }
            if let projectId = task.projectId { return activeProjectIds.contains(projectId) }
            if let thesisId = task.thesisId { return activeThesisIds.contains(thesisId) }
            if let affairId = task.affairId { return activeAffairIds.contains(affairId) }
            return true
        }
        workbenchStats = WorkbenchStats(
            activeProjects: store.projects.filter(\.isActive).count,
            activeTheses: store.thesisInfos.filter { !$0.isArchived && $0.overallProgress < 1.0 }.count,
            activeAffairs: store.affairs.filter { !$0.isArchived }.count,
            todayOpenTasks: activeTasks.filter(\.isToday).count,
            dueTodayTasks: activeTasks.filter { task in
                task.dueDate.map { todayRange.contains($0) } ?? false
            }.count,
            dueSoonTasks: activeTasks.filter { task in
                guard let due = task.dueDate else { return false }
                return due > now && due <= soon
            }.count,
            overdueTasks: activeTasks.filter(\.isOverdue).count,
            activeSubmissions: store.submissions.filter(\.isActive).count
        )
    }

    private func loadTodayTimeline() {
        let now = Date()
        let targetDate = now
        let todayRange = now.startOfDay..<now.endOfDay
        let timelineTasks = activeTimelineTasks().filter { task in
            guard task.status != .completed else { return false }
            guard let dueDate = task.dueDate else { return task.isToday }
            return task.isToday || dueDate < now || todayRange.contains(dueDate)
        }

        let taskItems = timelineTasks.map { task in
            TimelineItem(
                taskId: task.id,
                time: task.dueDate,
                title: timelineTitle(for: task, targetDate: targetDate),
                subtitle: ownerLabel(for: task),
                color: timelineColor(for: task),
                tone: timelineTone(for: task, targetDate: targetDate),
                isCompleted: task.status == .completed
            )
        }

        let scheduleItems = todayScheduleBlocks.map { block in
            TimelineItem(
                time: block.startTime,
                title: block.taskTitle,
                subtitle: "时间安排",
                color: .secondary,
                tone: .schedule,
                isCompleted: block.endTime < Date()
            )
        }

        todayTimelineItems = (taskItems + scheduleItems)
            .sorted(by: timelineSort)
    }

    private func loadTomorrowTimeline() {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowRange = tomorrow.startOfDay..<tomorrow.endOfDay

        let taskItems = activeTimelineTasks()
            .filter { task in
                guard task.status != .completed else { return false }
                guard let dueDate = task.dueDate else { return false }
                return tomorrowRange.contains(dueDate)
            }
            .map { task in
                TimelineItem(
                    taskId: task.id,
                    time: task.dueDate,
                    title: timelineTitle(for: task, targetDate: tomorrow),
                    subtitle: ownerLabel(for: task),
                    color: timelineColor(for: task),
                    tone: timelineTone(for: task, targetDate: tomorrow),
                    isCompleted: task.status == .completed
                )
            }

        let scheduleItems = store.scheduleBlocks
            .filter { tomorrowRange.contains($0.date) }
            .map { block in
                TimelineItem(
                    time: block.startTime,
                    title: block.taskTitle,
                    subtitle: "时间安排",
                    color: .secondary,
                    tone: .schedule,
                    isCompleted: false
                )
            }

        tomorrowTimelineItems = (taskItems + scheduleItems)
            .sorted(by: timelineSort)
    }

    private func timelineSort(_ left: TimelineItem, _ right: TimelineItem) -> Bool {
        switch (left.time, right.time) {
        case let (l?, r?): return l < r
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return left.title.localizedStandardCompare(right.title) == .orderedAscending
        }
    }

    private func timelineTitle(for task: Task, targetDate: Date) -> String {
        guard let dueDate = task.dueDate,
              !Calendar.current.isDate(dueDate, inSameDayAs: targetDate) else {
            return task.title
        }
        return "\(task.title)（DDL \(dueDate.formatted("MM/dd"))）"
    }

    private func ownerLabel(for task: Task) -> String {
        if let projectId = task.projectId, let project = store.projects.first(where: { $0.id == projectId }) {
            return "项目 · \(project.name)"
        }
        if let thesisId = task.thesisId, let thesis = store.thesisInfos.first(where: { $0.id == thesisId }) {
            return "课题 · \(thesis.title)"
        }
        if let affairId = task.affairId, let affair = store.affairs.first(where: { $0.id == affairId }) {
            return "事务 · \(affair.title)"
        }
        return "临时任务"
    }

    private func activeTimelineTasks() -> [Task] {
        let activeProjectIds = Set(store.projects.filter { !$0.isArchived }.map(\.id))
        let activeThesisIds = Set(store.thesisInfos.filter { !$0.isArchived }.map(\.id))
        let activeAffairIds = Set(store.affairs.filter { !$0.isArchived }.map(\.id))
        return store.tasks.filter { task in
            if let projectId = task.projectId { return activeProjectIds.contains(projectId) }
            if let thesisId = task.thesisId { return activeThesisIds.contains(thesisId) }
            if let affairId = task.affairId { return activeAffairIds.contains(affairId) }
            return true
        }
    }

    private func timelineColor(for task: Task) -> TimelineItem.ColorToken {
        if task.status == .completed { return .success }
        if task.isOverdue { return .danger }
        if let dueDate = task.dueDate, Calendar.current.isDateInToday(dueDate) { return .warning }
        if task.isDueWithin7Days { return .warning }
        if task.isToday { return .primary }
        switch task.priority {
        case .urgentImportant, .urgent:
            return .warning
        case .important:
            return .primary
        case .low:
            return .secondary
        }
    }

    private func timelineTone(for task: Task, targetDate: Date) -> TimelineItem.ToneToken {
        if task.isOverdue { return .overdue }
        if let dueDate = task.dueDate, Calendar.current.isDate(dueDate, inSameDayAs: targetDate) {
            return Calendar.current.isDateInToday(dueDate) ? .dueToday : .dueSoon
        }
        if task.isToday { return .active }
        if task.isDueWithin7Days { return .dueSoon }
        return .normal
    }

    var focusTimerDisplay: String {
        let h = Int(focusElapsedSeconds) / 3600
        let m = (Int(focusElapsedSeconds) % 3600) / 60
        let s = Int(focusElapsedSeconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    var todayFocusMinutes: Int {
        todayFocusSessions.reduce(0) { $0 + Int($1.duration) / 60 }
    }

    var dateRangeString: String {
        switch timeRange {
        case .daily: return Date().formatted("yyyy/MM/dd")
        case .weekly: return store.weekRangeString()
        case .monthly: return store.monthRangeString()
        }
    }

    deinit { timer?.invalidate() }
}
