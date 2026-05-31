import Foundation
import Combine
import AppKit

class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var checkInRecords: [CheckInRecord] = []
    @Published var projects: [Project] = []
    @Published var affairs: [Affair] = []
    @Published var tasks: [Task] = []
    @Published var focusSessions: [FocusSession] = []
    @Published var scheduleBlocks: [ScheduleBlock] = []
    @Published var thesisInfos: [ThesisInfo] = []
    @Published var submissions: [Submission] = []
    @Published var healthHabits: [HealthHabit] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var mentalCareRecords: [MentalCareRecord] = []
    @Published var achievements: [Achievement] = []
    @Published var busyDaySnapshots: [BusyDaySnapshot] = []
    @Published var workspaceURL: URL?
    @Published var lastErrorMessage: String = ""
    @Published var appDisplayName: String
    @Published var appLanguage: AppLanguage

    private let workspaceFolderName = "ScholarData"
    private let dataFileExtension = "json"
    private let backupFileName = "workspace_backup.json"
    private let bookmarkKey = "Scholar.SelectedWorkspaceBookmark"
    private let workspacePathKey = "Scholar.SelectedWorkspacePath"
    private let appDisplayNameKey = "Scholar.AppDisplayName"
    private var activeSecurityScopedWorkspaceURL: URL?
    private var isAccessingSecurityScopedWorkspace = false
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let storedName = UserDefaults.standard.string(forKey: appDisplayNameKey)
        if let storedName, ["SQJ", "Research Flow", "PhDMasterWorkspace", "Workspace", "Schola"].contains(storedName) {
            appDisplayName = "Scholar"
            UserDefaults.standard.set("Scholar", forKey: appDisplayNameKey)
        } else {
            appDisplayName = storedName ?? "Scholar"
        }
        appLanguage = AppLanguage.storedPreference
        resetInMemoryData()
        restorePersistedWorkspaceIfAvailable()
    }

    deinit {
        stopAccessingActiveWorkspace()
    }

    struct AppData: Codable {
        var checkInRecords: [CheckInRecord]
        var projects: [Project]
        var affairs: [Affair]?
        var tasks: [Task]
        var focusSessions: [FocusSession]
        var scheduleBlocks: [ScheduleBlock]
        var thesisInfos: [ThesisInfo]
        var submissions: [Submission]
        var healthHabits: [HealthHabit]
        var healthRecords: [HealthRecord]
        var mentalCareRecords: [MentalCareRecord]
        var achievements: [Achievement]
        var busyDaySnapshots: [BusyDaySnapshot]?
    }

    struct BusyDaySnapshot: Codable, Identifiable, Hashable {
        var id: String { dayKey }
        var dayKey: String
        var date: Date
        var totalTasks: Int
        var completedTasks: Int
        var dueTasks: Int?
        var overdueTasks: Int?
        var continuousTasks: Int?
        var workloadTasks: Int?
        var updatedAt: Date
    }

    struct BusyDayBreakdown {
        var dueTasks: [Task]
        var overdueTasks: [Task]
        var continuousTasks: [Task]
        var completedTodayTasks: [Task]

        var denominatorTasks: [Task] {
            uniqueTasks(dueTasks + overdueTasks)
        }

        var workloadTasks: [Task] {
            uniqueTasks(dueTasks + overdueTasks + continuousTasks)
        }

        var allDisplayTasks: [Task] {
            uniqueTasks(completedTodayTasks + dueTasks + overdueTasks + continuousTasks)
        }

        var denominatorCount: Int {
            dueTasks.count + overdueTasks.count + continuousTasks.count
        }

        var workloadCount: Int {
            denominatorCount
        }

        var completedTodayCount: Int {
            completedTodayTasks.count
        }

        private func uniqueTasks(_ tasks: [Task]) -> [Task] {
            var seen = Set<UUID>()
            return tasks.filter { task in
                if seen.contains(task.id) { return false }
                seen.insert(task.id)
                return true
            }
        }
    }

    struct WorkspaceStorageInfo {
        var displayPath: String
        var dataFormat: String
        var dataVersion: String
    }

    var hasSelectedWorkspace: Bool {
        workspaceURL != nil
    }

    var workspaceName: String {
        workspaceURL?.lastPathComponent ?? appLanguage.text("未选择", "Not Selected")
    }

    func updateAppDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        appDisplayName = trimmed.isEmpty ? "Scholar" : trimmed
        UserDefaults.standard.set(appDisplayName, forKey: appDisplayNameKey)
    }

    func updateAppLanguage(_ language: AppLanguage) {
        appLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
    }

    var storageInfo: WorkspaceStorageInfo {
        WorkspaceStorageInfo(
            displayPath: workspaceURL?.path ?? appLanguage.text("启动后请选择一个 workspace 文件夹", "Choose a workspace folder after launch"),
            dataFormat: appLanguage.text("ScholarData 分类目录 + JSON 分片", "ScholarData categorized JSON shards"),
            dataVersion: "v4"
        )
    }

    var defaultBackupFileName: String {
        backupFileName
    }

    func selectWorkspaceWithPanel() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = appLanguage.text("选择 Workspace", "Choose Workspace")
        panel.message = appLanguage.text(
            "请选择一个用于保存科研数据与附件的 workspace 文件夹。",
            "Choose a workspace folder for research data and attachments."
        )

        let response = panel.runModal()
        restoreApplicationFocus()
        guard response == .OK, let url = panel.url else { return false }
        return activateWorkspace(url)
    }

    @discardableResult
    func activateWorkspace(_ url: URL) -> Bool {
        do {
            beginAccessingWorkspace(url)
            try FileManager.default.createDirectory(at: workspaceDataRoot(for: url), withIntermediateDirectories: true)
            workspaceURL = url
            try persistWorkspaceBookmark(for: url)
            load()
            restoreApplicationFocus()
            return true
        } catch {
            workspaceURL = nil
            stopAccessingActiveWorkspace()
            lastErrorMessage = appLanguage.text(
                "无法启用 workspace：\(error.localizedDescription)",
                "Unable to activate the workspace: \(error.localizedDescription)"
            )
            return false
        }
    }

    func save() {
        guard let root = activeDataRoot else { return }
        do {
            updateBusySnapshot(for: Date())
            finalizePastBusySnapshots()
            let buckets = dataBuckets(for: appDataSnapshot())
            for bucket in buckets {
                let encoded = try encoder.encode(bucket.payload)
                let target = root.appendingPathComponent(bucket.relativePath).appendingPathExtension(dataFileExtension)
                try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                if let existing = try? Data(contentsOf: target), existing == encoded {
                    continue
                }
                try encoded.write(to: target, options: .atomic)
            }
            lastErrorMessage = ""
        } catch {
            lastErrorMessage = appLanguage.text(
                "保存失败：\(error.localizedDescription)",
                "Save failed: \(error.localizedDescription)"
            )
        }
    }

    func load() {
        guard let root = activeDataRoot else {
            resetInMemoryData()
            return
        }

        do {
            let decoded = try loadAppData(from: root)
            applyAppData(decoded)
            lastErrorMessage = ""
        } catch {
            lastErrorMessage = appLanguage.text(
                "读取 workspace 失败：\(error.localizedDescription)",
                "Failed to load the workspace: \(error.localizedDescription)"
            )
            resetInMemoryData()
        }
    }

    func clearAll() {
        resetInMemoryData()
        save()
    }

    func exportWorkspaceBundle() -> Data? {
        try? encoder.encode(appDataSnapshot())
    }

    func importWorkspaceBundle(_ data: Data) -> Bool {
        guard let decoded = decodeWorkspaceBundle(data) else {
            return false
        }

        applyAppData(decoded)
        save()
        return true
    }

    func importLegacyJSON(_ jsonData: Data) -> Bool {
        guard let decoded = try? decoder.decode(AppData.self, from: jsonData) else { return false }
        applyAppData(decoded)
        save()
        return true
    }

    func importAttachment(from sourceURL: URL, for submissionID: UUID) -> FileAttachment? {
        guard let attachmentsRoot = activeAttachmentsRoot else { return nil }
        do {
            let submissionFolder = attachmentsRoot.appendingPathComponent(submissionID.uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: submissionFolder, withIntermediateDirectories: true)

            let ext = sourceURL.pathExtension
            let storedFileName = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
            let targetURL = submissionFolder.appendingPathComponent(storedFileName)

            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)

            return FileAttachment(
                originalFileName: sourceURL.lastPathComponent,
                storedFileName: storedFileName,
                relativePath: "attachments/submissions/\(submissionID.uuidString)/\(storedFileName)",
                fileExtension: ext
            )
        } catch {
            lastErrorMessage = appLanguage.text(
                "附件导入失败：\(error.localizedDescription)",
                "Attachment import failed: \(error.localizedDescription)"
            )
            return nil
        }
    }

    func attachmentURL(for attachment: FileAttachment) -> URL? {
        activeDataRoot?.appendingPathComponent(attachment.relativePath)
    }

    private var activeDataRoot: URL? {
        workspaceURL.map { workspaceDataRoot(for: $0) }
    }

    private var activeAttachmentsRoot: URL? {
        activeDataRoot?.appendingPathComponent(StoragePath.attachmentsSubmissions, isDirectory: true)
    }

    private func workspaceDataRoot(for workspace: URL) -> URL {
        workspace.appendingPathComponent(workspaceFolderName, isDirectory: true)
    }

    private func appDataSnapshot() -> AppData {
        AppData(
            checkInRecords: checkInRecords,
            projects: projects,
            affairs: affairs,
            tasks: tasks,
            focusSessions: focusSessions,
            scheduleBlocks: scheduleBlocks,
            thesisInfos: thesisInfos,
            submissions: submissions,
            healthHabits: healthHabits,
            healthRecords: healthRecords,
            mentalCareRecords: mentalCareRecords,
            achievements: achievements,
            busyDaySnapshots: busyDaySnapshots
        )
    }

    private func applyAppData(_ decoded: AppData) {
        checkInRecords = decoded.checkInRecords
        projects = decoded.projects
        affairs = decoded.affairs ?? []
        tasks = decoded.tasks
        focusSessions = decoded.focusSessions
        scheduleBlocks = decoded.scheduleBlocks
        thesisInfos = decoded.thesisInfos
        submissions = decoded.submissions
        healthHabits = decoded.healthHabits
        healthRecords = decoded.healthRecords
        mentalCareRecords = decoded.mentalCareRecords
        achievements = decoded.achievements
        busyDaySnapshots = decoded.busyDaySnapshots ?? []
        finalizePastBusySnapshots()
    }

    private func resetInMemoryData() {
        checkInRecords = []
        projects = []
        affairs = []
        tasks = []
        focusSessions = []
        scheduleBlocks = []
        thesisInfos = []
        submissions = []
        healthHabits = []
        healthRecords = []
        mentalCareRecords = []
        achievements = []
        busyDaySnapshots = []
    }

    private func dataBuckets(for data: AppData) -> [(relativePath: String, payload: AnyEncodable)] {
        let groupedTasks = groupedTasksByStorageArea(data.tasks)
        return [
            (StoragePath.checkins, AnyEncodable(data.checkInRecords)),
            (StoragePath.projects, AnyEncodable(data.projects)),
            (StoragePath.affairs, AnyEncodable(data.affairs ?? [])),
            (StoragePath.projectTasks, AnyEncodable(groupedTasks.projectTasks)),
            (StoragePath.thesisTasks, AnyEncodable(groupedTasks.thesisTasks)),
            (StoragePath.affairTasks, AnyEncodable(groupedTasks.affairTasks)),
            (StoragePath.todoTasks, AnyEncodable(groupedTasks.todoTasks)),
            (StoragePath.focusSessions, AnyEncodable(data.focusSessions)),
            (StoragePath.scheduleBlocks, AnyEncodable(data.scheduleBlocks)),
            (StoragePath.thesisInfos, AnyEncodable(data.thesisInfos)),
            (StoragePath.submissions, AnyEncodable(data.submissions)),
            (StoragePath.healthHabits, AnyEncodable(data.healthHabits)),
            (StoragePath.healthRecords, AnyEncodable(data.healthRecords)),
            (StoragePath.mentalCareRecords, AnyEncodable(data.mentalCareRecords)),
            (StoragePath.achievements, AnyEncodable(data.achievements)),
            (StoragePath.busyDaySnapshots, AnyEncodable(data.busyDaySnapshots ?? []))
        ]
    }

    private func loadAppData(from root: URL) throws -> AppData {
        let tasks = try [
            readArray([Task].self, from: root, relativePath: StoragePath.projectTasks),
            readArray([Task].self, from: root, relativePath: StoragePath.thesisTasks),
            readArray([Task].self, from: root, relativePath: StoragePath.affairTasks),
            readArray([Task].self, from: root, relativePath: StoragePath.todoTasks)
        ].flatMap { $0 }

        return AppData(
            checkInRecords: try readArray([CheckInRecord].self, from: root, relativePath: StoragePath.checkins),
            projects: try readArray([Project].self, from: root, relativePath: StoragePath.projects),
            affairs: try readArray([Affair].self, from: root, relativePath: StoragePath.affairs),
            tasks: tasks,
            focusSessions: try readArray([FocusSession].self, from: root, relativePath: StoragePath.focusSessions),
            scheduleBlocks: try readArray([ScheduleBlock].self, from: root, relativePath: StoragePath.scheduleBlocks),
            thesisInfos: try readArray([ThesisInfo].self, from: root, relativePath: StoragePath.thesisInfos),
            submissions: try readArray([Submission].self, from: root, relativePath: StoragePath.submissions),
            healthHabits: try readArray([HealthHabit].self, from: root, relativePath: StoragePath.healthHabits),
            healthRecords: try readArray([HealthRecord].self, from: root, relativePath: StoragePath.healthRecords),
            mentalCareRecords: try readArray([MentalCareRecord].self, from: root, relativePath: StoragePath.mentalCareRecords),
            achievements: try readArray([Achievement].self, from: root, relativePath: StoragePath.achievements),
            busyDaySnapshots: try readArray([BusyDaySnapshot].self, from: root, relativePath: StoragePath.busyDaySnapshots)
        )
    }

    private func groupedTasksByStorageArea(_ tasks: [Task]) -> (
        projectTasks: [Task],
        thesisTasks: [Task],
        affairTasks: [Task],
        todoTasks: [Task]
    ) {
        (
            projectTasks: tasks.filter { $0.projectId != nil && $0.thesisId == nil && $0.affairId == nil },
            thesisTasks: tasks.filter { $0.thesisId != nil && $0.projectId == nil && $0.affairId == nil },
            affairTasks: tasks.filter { $0.affairId != nil && $0.projectId == nil && $0.thesisId == nil },
            todoTasks: tasks.filter { $0.projectId == nil && $0.thesisId == nil && $0.affairId == nil }
        )
    }

    private func readArray<T: Decodable>(_ type: [T].Type, from root: URL, relativePath: String) throws -> [T] {
        let preferredURL = root.appendingPathComponent(relativePath).appendingPathExtension(dataFileExtension)

        if FileManager.default.fileExists(atPath: preferredURL.path) {
            let raw = try Data(contentsOf: preferredURL)
            let decoded = try decodeStoredPayload(raw)
            return try decoder.decode([T].self, from: decoded)
        }

        return []
    }

    private func decodeWorkspaceBundle(_ data: Data) -> AppData? {
        try? decoder.decode(AppData.self, from: data)
    }

    private func decodeStoredPayload(_ data: Data) throws -> Data {
        if (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }
        throw NSError(domain: "AppDataStore", code: 10, userInfo: [NSLocalizedDescriptionKey: "数据内容不是有效的 JSON"])
    }

    private func persistWorkspaceBookmark(for url: URL) throws {
        let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        let defaults = UserDefaults.standard
        defaults.set(bookmark, forKey: bookmarkKey)
        defaults.set(url.path, forKey: workspacePathKey)
        defaults.synchronize()
    }

    private func restorePersistedWorkspaceIfAvailable() {
        guard
            let url = restoreURLFromBookmark() ?? restoreURLFromStoredPath()
        else {
            return
        }

        do {
            beginAccessingWorkspace(url)
            try FileManager.default.createDirectory(at: workspaceDataRoot(for: url), withIntermediateDirectories: true)
            workspaceURL = url
            try persistWorkspaceBookmark(for: url)
            load()
            lastErrorMessage = ""
        } catch {
            workspaceURL = nil
            stopAccessingActiveWorkspace()
            lastErrorMessage = appLanguage.text(
                "无法恢复上次的 workspace，请重新选择。",
                "Unable to restore the previous workspace. Please choose it again."
            )
            removePersistedWorkspaceReference()
        }
    }

    private func restoreURLFromBookmark() -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }

        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withoutUI, .withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) {
            return url
        }

        isStale = false
        return try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    private func restoreURLFromStoredPath() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: workspacePathKey),
              !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func removePersistedWorkspaceReference() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: bookmarkKey)
        defaults.removeObject(forKey: workspacePathKey)
        defaults.synchronize()
    }

    private func beginAccessingWorkspace(_ url: URL) {
        if activeSecurityScopedWorkspaceURL?.path == url.path {
            return
        }
        stopAccessingActiveWorkspace()
        activeSecurityScopedWorkspaceURL = url
        isAccessingSecurityScopedWorkspace = url.startAccessingSecurityScopedResource()
    }

    private func stopAccessingActiveWorkspace() {
        if isAccessingSecurityScopedWorkspace {
            activeSecurityScopedWorkspaceURL?.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedWorkspaceURL = nil
        isAccessingSecurityScopedWorkspace = false
    }

    func restoreApplicationFocus() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
            window?.makeKeyAndOrderFront(nil)
            window?.orderFrontRegardless()
        }
    }

    func prepareForTextInput() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
            window?.makeKeyAndOrderFront(nil)
        }
    }

    private enum StoragePath {
        static let checkins = "overview/checkins"
        static let projects = "projects/projects"
        static let projectTasks = "projects/tasks"
        static let affairs = "affairs/affairs"
        static let affairTasks = "affairs/tasks"
        static let focusSessions = "focus/focus_sessions"
        static let scheduleBlocks = "focus/schedule_blocks"
        static let thesisInfos = "thesis/thesis_infos"
        static let thesisTasks = "thesis/tasks"
        static let submissions = "outcomes/submissions"
        static let healthHabits = "health/health_habits"
        static let healthRecords = "health/health_records"
        static let mentalCareRecords = "mental/mental_care_records"
        static let achievements = "milestones/achievements"
        static let busyDaySnapshots = "overview/busy_day_snapshots"
        static let todoTasks = "todos/tasks"
        static let attachmentsSubmissions = "attachments/submissions"
    }

    // MARK: - Date Range Helpers
    func dateRange(for range: TimeRange, from date: Date = Date()) -> Range<Date> {
        switch range {
        case .daily: return date.startOfDay..<date.endOfDay
        case .weekly: return date.startOfWeek..<date.endOfWeek
        case .monthly: return date.startOfMonth..<date.endOfMonth
        }
    }

    func weekRangeString(from date: Date = Date()) -> String {
        "\(date.startOfWeek.formatted("yyyy-MM-dd")) ~ \(date.endOfWeek.formatted("yyyy-MM-dd"))"
    }

    func monthRangeString(from date: Date = Date()) -> String {
        "\(date.startOfMonth.formatted("yyyy-MM-dd")) ~ \(date.endOfMonth.formatted("yyyy-MM-dd"))"
    }

    // MARK: - Statistics
    struct OverviewStats {
        var focusMinutes: Int = 0
        var checkInMinutes: Int = 0
        var habitCompletionRate: Double = 0
        var mentalCareCount: Int = 0
        var completedTasks: Int = 0
        var newSubmissions: Int = 0
        var focusSessionCount: Int = 0
        var checkInCount: Int = 0
        var timeBlockCount: Int = 0
        var timeBlockMinutes: Int = 0
    }

    func computeOverviewStats(range: TimeRange, date: Date = Date()) -> OverviewStats {
        let dr = dateRange(for: range, from: date)
        var s = OverviewStats()
        s.focusMinutes = focusSessions.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }.reduce(0) { $0 + Int($1.duration) / 60 }
        s.focusSessionCount = focusSessions.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }.count
        s.checkInMinutes = checkInRecords.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound && $0.type == .work }.reduce(0) { $0 + Int($1.duration) / 60 }
        s.checkInCount = checkInRecords.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound && $0.type == .work }.count
        let activeHabits = healthHabits.filter(\.isActive)
        if !activeHabits.isEmpty {
            let completed = activeHabits.filter { h in healthRecords.contains { $0.habitId == h.id && $0.date >= dr.lowerBound && $0.date <= dr.upperBound } }.count
            s.habitCompletionRate = Double(completed) / Double(activeHabits.count)
        }
        s.mentalCareCount = mentalCareRecords.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }.count
        s.completedTasks = tasks.filter { $0.status == .completed && $0.updatedAt >= dr.lowerBound && $0.updatedAt <= dr.upperBound }.count
        s.newSubmissions = submissions.filter { $0.createdAt >= dr.lowerBound && $0.createdAt <= dr.upperBound }.count
        let blocks = scheduleBlocks.filter { $0.date >= dr.lowerBound && $0.date <= dr.upperBound }
        s.timeBlockCount = blocks.count
        s.timeBlockMinutes = blocks.reduce(0) { $0 + Int($1.endTime.timeIntervalSince($1.startTime)) / 60 }
        return s
    }

    func busySnapshot(for date: Date) -> BusyDaySnapshot? {
        busyDaySnapshots.first { $0.dayKey == Self.dayKey(for: date) }
    }

    func busyTaskCounts(for date: Date, includeTodayFlag: Bool) -> (totalTasks: Int, completedTasks: Int) {
        let breakdown = busyTaskBreakdown(for: date, includeTodayFlag: includeTodayFlag)
        return (breakdown.denominatorCount, breakdown.completedTodayCount)
    }

    func busyTasks(for date: Date, includeTodayFlag: Bool) -> [Task] {
        busyTaskBreakdown(for: date, includeTodayFlag: includeTodayFlag).allDisplayTasks
    }

    func busyTaskBreakdown(for date: Date, includeTodayFlag: Bool) -> BusyDayBreakdown {
        let dayRange = date.startOfDay..<date.endOfDay
        let todayStart = Date().startOfDay
        var dueTasks: [Task] = []
        var overdueTasks: [Task] = []
        var continuousTasks: [Task] = []
        var completedTodayTasks: [Task] = []

        for task in tasks {
            if task.status == .completed && dayRange.contains(task.updatedAt) {
                completedTodayTasks.append(task)
            }

            if let dueDate = task.dueDate,
               dueDate < date.startOfDay,
               date.startOfDay <= todayStart,
               task.status != .completed || dayRange.contains(task.updatedAt) {
                overdueTasks.append(task)
            } else if let dueDate = task.dueDate,
                      dayRange.contains(dueDate) {
                dueTasks.append(task)
            } else if includeTodayFlag && task.isToday && task.status != .completed {
                continuousTasks.append(task)
            }
        }

        return BusyDayBreakdown(
            dueTasks: sortedBusyTasks(dueTasks),
            overdueTasks: sortedBusyTasks(overdueTasks),
            continuousTasks: sortedBusyTasks(continuousTasks),
            completedTodayTasks: sortedBusyTasks(completedTodayTasks)
        )
    }

    private func sortedBusyTasks(_ tasks: [Task]) -> [Task] {
        tasks.sorted { lhs, rhs in
            if lhs.status == .completed && rhs.status != .completed { return false }
            if lhs.status != .completed && rhs.status == .completed { return true }
            let lhsDue = lhs.dueDate ?? .distantFuture
            let rhsDue = rhs.dueDate ?? .distantFuture
            if lhsDue != rhsDue { return lhsDue < rhsDue }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func updateBusySnapshot(for date: Date) {
        let breakdown = busyTaskBreakdown(for: date, includeTodayFlag: Calendar.current.isDateInToday(date))
        let snapshot = BusyDaySnapshot(
            dayKey: Self.dayKey(for: date),
            date: date.startOfDay,
            totalTasks: breakdown.denominatorCount,
            completedTasks: breakdown.completedTodayCount,
            dueTasks: breakdown.dueTasks.count,
            overdueTasks: breakdown.overdueTasks.count,
            continuousTasks: breakdown.continuousTasks.count,
            workloadTasks: breakdown.workloadCount,
            updatedAt: Date()
        )

        if let index = busyDaySnapshots.firstIndex(where: { $0.dayKey == snapshot.dayKey }) {
            busyDaySnapshots[index] = snapshot
        } else {
            busyDaySnapshots.append(snapshot)
        }
    }

    private func finalizePastBusySnapshots() {
        let todayStart = Date().startOfDay
        var candidateDays = Set<String>()

        for task in tasks {
            if let dueDate = task.dueDate, dueDate.startOfDay < todayStart {
                candidateDays.insert(Self.dayKey(for: dueDate))
            }
            if task.status == .completed && task.updatedAt.startOfDay < todayStart {
                candidateDays.insert(Self.dayKey(for: task.updatedAt))
            }
        }

        for snapshot in busyDaySnapshots where snapshot.date.startOfDay < todayStart {
            candidateDays.insert(snapshot.dayKey)
        }

        for dayKey in candidateDays where busyDaySnapshots.contains(where: { $0.dayKey == dayKey }) == false {
            guard let date = Self.date(fromDayKey: dayKey) else { continue }
            let breakdown = busyTaskBreakdown(for: date, includeTodayFlag: false)
            busyDaySnapshots.append(
                BusyDaySnapshot(
                    dayKey: dayKey,
                    date: date.startOfDay,
                    totalTasks: breakdown.denominatorCount,
                    completedTasks: breakdown.completedTodayCount,
                    dueTasks: breakdown.dueTasks.count,
                    overdueTasks: breakdown.overdueTasks.count,
                    continuousTasks: breakdown.continuousTasks.count,
                    workloadTasks: breakdown.workloadCount,
                    updatedAt: Date()
                )
            )
        }
    }

    private static func dayKey(for date: Date) -> String {
        date.formatted("yyyy-MM-dd")
    }

    private static func date(fromDayKey dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dayKey)
    }

    struct TodaySnapshot {
        var todayOpenTasks: Int = 0
        var dueTodayTasks: Int = 0
        var inProgressTasks: Int = 0
        var activeSubmissions: Int = 0
    }

    func computeTodaySnapshot() -> TodaySnapshot {
        let range = Date().startOfDay..<Date().endOfDay
        var snap = TodaySnapshot()
        let activeProjectIds = Set(projects.filter { !$0.isArchived }.map(\.id))
        let activeThesisIds = Set(thesisInfos.filter { !$0.isArchived }.map(\.id))
        let activeAffairIds = Set(affairs.filter { !$0.isArchived }.map(\.id))
        let openTasks = tasks.filter { task in
            guard task.status != .completed else { return false }
            if let projectId = task.projectId { return activeProjectIds.contains(projectId) }
            if let thesisId = task.thesisId { return activeThesisIds.contains(thesisId) }
            if let affairId = task.affairId { return activeAffairIds.contains(affairId) }
            return true
        }
        snap.todayOpenTasks = openTasks.filter(\.isToday).count
        snap.dueTodayTasks = openTasks.filter { task in
            task.dueDate.map { range.contains($0) } ?? false
        }.count
        snap.inProgressTasks = openTasks.filter(\.isOverdue).count
        snap.activeSubmissions = submissions.filter(\.isActive).count
        return snap
    }

    struct ProjectBoardStats {
        var totalProjects: Int = 0
        var activeProjects: Int = 0
        var totalTasks: Int = 0
        var incompleteTasks: Int = 0
        var dueWithin7Days: Int = 0
        var unassignedTasks: Int = 0
        var q1Tasks: Int = 0
        var q2Tasks: Int = 0
        var q3Tasks: Int = 0
        var q4Tasks: Int = 0
        var todayMustDo: Int = 0
        var todayShouldDo: Int = 0
    }

    struct ThesisBoardStats {
        var totalTheses: Int = 0
        var activeTheses: Int = 0
        var completedTheses: Int = 0
        var totalTasks: Int = 0
        var incompleteTasks: Int = 0
        var completedTasks: Int = 0
        var dueWithin7Days: Int = 0
        var q1Tasks: Int = 0
        var q2Tasks: Int = 0
        var q3Tasks: Int = 0
        var q4Tasks: Int = 0
        var todayMustDo: Int = 0
        var todayShouldDo: Int = 0
    }

    struct AffairBoardStats {
        var totalAffairs: Int = 0
        var activeAffairs: Int = 0
        var completedAffairs: Int = 0
        var totalTasks: Int = 0
        var incompleteTasks: Int = 0
        var completedTasks: Int = 0
        var dueWithin7Days: Int = 0
        var q1Tasks: Int = 0
        var q2Tasks: Int = 0
        var q3Tasks: Int = 0
        var q4Tasks: Int = 0
        var todayMustDo: Int = 0
        var todayShouldDo: Int = 0
    }

    struct TodoBoardStats {
        var totalTasks: Int = 0
        var incompleteTasks: Int = 0
        var completedTasks: Int = 0
        var dueWithin7Days: Int = 0
        var overdueTasks: Int = 0
        var q1Tasks: Int = 0
        var q2Tasks: Int = 0
        var q3Tasks: Int = 0
        var q4Tasks: Int = 0
        var todayMustDo: Int = 0
        var todayShouldDo: Int = 0
    }

    func computeProjectBoardStats() -> ProjectBoardStats {
        var s = ProjectBoardStats()
        let activeProjectIds = Set(projects.filter { !$0.isArchived }.map(\.id))
        let projectTasks = tasks.filter { task in
            guard let projectId = task.projectId else { return false }
            return activeProjectIds.contains(projectId) && task.thesisId == nil && task.affairId == nil
        }
        let activeProjects = projects.filter { !$0.isArchived }
        s.totalProjects = activeProjects.count
        s.activeProjects = activeProjects.filter(\.isActive).count
        s.totalTasks = projectTasks.count
        s.incompleteTasks = projectTasks.filter { $0.status != .completed }.count
        s.dueWithin7Days = projectTasks.filter(\.isDueWithin7Days).count
        s.unassignedTasks = tasks.filter { $0.projectId == nil && $0.thesisId == nil && $0.affairId == nil }.count
        s.q1Tasks = projectTasks.filter { $0.priority == .urgentImportant && $0.status != .completed }.count
        s.q2Tasks = projectTasks.filter { $0.priority == .important && $0.status != .completed }.count
        s.q3Tasks = projectTasks.filter { $0.priority == .urgent && $0.status != .completed }.count
        s.q4Tasks = projectTasks.filter { $0.priority == .low && $0.status != .completed }.count
        s.todayMustDo = projectTasks.filter { $0.isToday && ($0.priority == .urgentImportant || $0.priority == .urgent) && $0.status != .completed }.count
        s.todayShouldDo = projectTasks.filter { $0.isToday && $0.priority == .important && $0.status != .completed }.count
        return s
    }

    func computeThesisBoardStats() -> ThesisBoardStats {
        var s = ThesisBoardStats()
        let activeTheses = thesisInfos.filter { !$0.isArchived }
        let activeThesisIds = Set(activeTheses.map(\.id))
        let thesisTasks = tasks.filter { task in
            guard let thesisId = task.thesisId else { return false }
            return activeThesisIds.contains(thesisId) && task.projectId == nil && task.affairId == nil
        }
        s.totalTheses = activeTheses.count
        s.activeTheses = activeTheses.filter { $0.stage != .submitted }.count
        s.completedTheses = activeTheses.filter { $0.stage == .submitted }.count
        s.totalTasks = thesisTasks.count
        s.incompleteTasks = thesisTasks.filter { $0.status != .completed }.count
        s.completedTasks = thesisTasks.filter { $0.status == .completed }.count
        s.dueWithin7Days = thesisTasks.filter(\.isDueWithin7Days).count
        s.q1Tasks = thesisTasks.filter { $0.priority == .urgentImportant && $0.status != .completed }.count
        s.q2Tasks = thesisTasks.filter { $0.priority == .important && $0.status != .completed }.count
        s.q3Tasks = thesisTasks.filter { $0.priority == .urgent && $0.status != .completed }.count
        s.q4Tasks = thesisTasks.filter { $0.priority == .low && $0.status != .completed }.count
        s.todayMustDo = thesisTasks.filter { $0.isToday && ($0.priority == .urgentImportant || $0.priority == .urgent) && $0.status != .completed }.count
        s.todayShouldDo = thesisTasks.filter { $0.isToday && $0.priority == .important && $0.status != .completed }.count
        return s
    }

    func computeAffairBoardStats() -> AffairBoardStats {
        var s = AffairBoardStats()
        let activeAffairs = affairs.filter { !$0.isArchived }
        let activeAffairIds = Set(activeAffairs.map(\.id))
        let affairTasks = tasks.filter { task in
            guard let affairId = task.affairId else { return false }
            return activeAffairIds.contains(affairId) && task.projectId == nil && task.thesisId == nil
        }
        s.totalAffairs = activeAffairs.count
        s.activeAffairs = activeAffairs.count
        s.completedAffairs = affairs.filter(\.isArchived).count
        s.totalTasks = affairTasks.count
        s.incompleteTasks = affairTasks.filter { $0.status != .completed }.count
        s.completedTasks = affairTasks.filter { $0.status == .completed }.count
        s.dueWithin7Days = affairTasks.filter(\.isDueWithin7Days).count
        s.q1Tasks = affairTasks.filter { $0.priority == .urgentImportant && $0.status != .completed }.count
        s.q2Tasks = affairTasks.filter { $0.priority == .important && $0.status != .completed }.count
        s.q3Tasks = affairTasks.filter { $0.priority == .urgent && $0.status != .completed }.count
        s.q4Tasks = affairTasks.filter { $0.priority == .low && $0.status != .completed }.count
        s.todayMustDo = affairTasks.filter { $0.isToday && ($0.priority == .urgentImportant || $0.priority == .urgent) && $0.status != .completed }.count
        s.todayShouldDo = affairTasks.filter { $0.isToday && $0.priority == .important && $0.status != .completed }.count
        return s
    }

    func computeTodoBoardStats() -> TodoBoardStats {
        var s = TodoBoardStats()
        let todoTasks = tasks.filter { $0.projectId == nil && $0.thesisId == nil && $0.affairId == nil }
        s.totalTasks = todoTasks.count
        s.incompleteTasks = todoTasks.filter { $0.status != .completed }.count
        s.completedTasks = todoTasks.filter { $0.status == .completed }.count
        s.dueWithin7Days = todoTasks.filter(\.isDueWithin7Days).count
        s.overdueTasks = todoTasks.filter(\.isOverdue).count
        s.q1Tasks = todoTasks.filter { $0.priority == .urgentImportant && $0.status != .completed }.count
        s.q2Tasks = todoTasks.filter { $0.priority == .important && $0.status != .completed }.count
        s.q3Tasks = todoTasks.filter { $0.priority == .urgent && $0.status != .completed }.count
        s.q4Tasks = todoTasks.filter { $0.priority == .low && $0.status != .completed }.count
        s.todayMustDo = todoTasks.filter { $0.isToday && ($0.priority == .urgentImportant || $0.priority == .urgent) && $0.status != .completed }.count
        s.todayShouldDo = todoTasks.filter { $0.isToday && $0.priority == .important && $0.status != .completed }.count
        return s
    }
}

private struct AnyEncodable: Encodable {
    private let encodeImpl: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encodeImpl = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}
