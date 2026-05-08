import Foundation
import Combine

class OverviewViewModel: ObservableObject {
    struct WorkbenchStats {
        var activeProjects: Int = 0
        var activeTheses: Int = 0
        var todayOpenTasks: Int = 0
        var dueTodayTasks: Int = 0
        var dueSoonTasks: Int = 0
        var overdueTasks: Int = 0
        var activeSubmissions: Int = 0
    }

    struct TimelineItem: Identifiable {
        var id = UUID()
        var time: Date?
        var title: String
        var subtitle: String
        var color: ColorToken
        var isCompleted: Bool

        enum ColorToken {
            case primary
            case warning
            case danger
            case success
            case secondary
        }
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
    }

    func refreshStats() {
        stats = store.computeOverviewStats(range: timeRange, date: selectedDate)
        todaySnapshot = store.computeTodaySnapshot()
        loadWorkbenchStats()
        loadTodayTimeline()
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
        todayTasks = store.tasks.filter(\.isToday)
        inProgressTasks = todayTasks.filter { $0.status == .inProgress }
    }

    func addTemporaryTask() {
        guard newTaskTitle.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
        let task = Task(title: newTaskTitle, status: .notStarted, isToday: true)
        store.tasks.append(task)
        store.save()
        newTaskTitle = ""
        showNewTaskField = false
        loadTodayTasks()
        refreshStats()
    }

    func startTask(_ task: Task) {
        if let idx = store.tasks.firstIndex(where: { $0.id == task.id }) {
            store.tasks[idx].status = .inProgress
            store.tasks[idx].startDate = Date()
            store.tasks[idx].updatedAt = Date()
            store.save()
        }
        loadTodayTasks()
        loadTodayTimeline()
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
        refreshStats()
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
        let activeTasks = store.tasks.filter { $0.status != .completed }
        workbenchStats = WorkbenchStats(
            activeProjects: store.projects.filter(\.isActive).count,
            activeTheses: store.thesisInfos.filter { $0.overallProgress < 1.0 }.count,
            todayOpenTasks: store.tasks.filter { $0.isToday && $0.status != .completed }.count,
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
        let taskItems = todayTasks.map { task in
            TimelineItem(
                time: task.dueDate,
                title: task.title,
                subtitle: ownerLabel(for: task),
                color: timelineColor(for: task),
                isCompleted: task.status == .completed
            )
        }

        let scheduleItems = todayScheduleBlocks.map { block in
            TimelineItem(
                time: block.startTime,
                title: block.taskTitle,
                subtitle: "时间安排",
                color: .secondary,
                isCompleted: block.endTime < Date()
            )
        }

        todayTimelineItems = (taskItems + scheduleItems)
            .sorted { left, right in
                switch (left.time, right.time) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return left.title.localizedStandardCompare(right.title) == .orderedAscending
                }
            }
    }

    private func ownerLabel(for task: Task) -> String {
        if let projectId = task.projectId, let project = store.projects.first(where: { $0.id == projectId }) {
            return "项目 · \(project.name)"
        }
        if let thesisId = task.thesisId, let thesis = store.thesisInfos.first(where: { $0.id == thesisId }) {
            return "课题 · \(thesis.title)"
        }
        return "临时任务"
    }

    private func timelineColor(for task: Task) -> TimelineItem.ColorToken {
        if task.status == .completed { return .success }
        if task.isOverdue { return .danger }
        switch task.priority {
        case .urgentImportant, .urgent:
            return .warning
        case .important:
            return .primary
        case .low:
            return .secondary
        }
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
