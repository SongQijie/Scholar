import Foundation
import Combine
import AppKit

class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var checkInRecords: [CheckInRecord] = []
    @Published var projects: [Project] = []
    @Published var tasks: [Task] = []
    @Published var focusSessions: [FocusSession] = []
    @Published var scheduleBlocks: [ScheduleBlock] = []
    @Published var thesisInfos: [ThesisInfo] = []
    @Published var submissions: [Submission] = []
    @Published var healthHabits: [HealthHabit] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var mentalCareRecords: [MentalCareRecord] = []
    @Published var achievements: [Achievement] = []
    @Published var workspaceURL: URL?
    @Published var lastErrorMessage: String = ""
    @Published var appDisplayName: String
    @Published var appLanguage: AppLanguage

    private let workspaceFolderName = "ScholarData"
    private let legacyWorkspaceFolderName = "PhDMasterWorkspaceData"
    private let dataFileExtension = "json"
    private let legacyDataFileExtension = "orzbug"
    private let backupFileName = "workspace_backup.json"
    private let bookmarkKey = "Scholar.SelectedWorkspaceBookmark"
    private let workspacePathKey = "Scholar.SelectedWorkspacePath"
    private let appDisplayNameKey = "Scholar.AppDisplayName"
    private let legacyBookmarkKey = "PhDMasterWorkspace.SelectedWorkspaceBookmark"
    private let legacyWorkspacePathKey = "PhDMasterWorkspace.SelectedWorkspacePath"
    private let legacyAppDisplayNameKey = "PhDMasterWorkspace.AppDisplayName"
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
            ?? UserDefaults.standard.string(forKey: legacyAppDisplayNameKey)
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
        var tasks: [Task]
        var focusSessions: [FocusSession]
        var scheduleBlocks: [ScheduleBlock]
        var thesisInfos: [ThesisInfo]
        var submissions: [Submission]
        var healthHabits: [HealthHabit]
        var healthRecords: [HealthRecord]
        var mentalCareRecords: [MentalCareRecord]
        var achievements: [Achievement]
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
            dataFormat: appLanguage.text("分类目录 + 紧凑 JSON 分片", "Categorized compact JSON shards"),
            dataVersion: "v3.1"
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
        let buckets = dataBuckets(for: appDataSnapshot())
        do {
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
            print("Save error: \(error)")
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
            print("Load error: \(error)")
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
        activeDataRoot?.appendingPathComponent("attachments/submissions", isDirectory: true)
    }

    private func workspaceDataRoot(for workspace: URL) -> URL {
        let currentRoot = workspace.appendingPathComponent(workspaceFolderName, isDirectory: true)
        let legacyRoot = workspace.appendingPathComponent(legacyWorkspaceFolderName, isDirectory: true)
        if FileManager.default.fileExists(atPath: legacyRoot.path),
           !FileManager.default.fileExists(atPath: currentRoot.path) {
            return legacyRoot
        }
        return currentRoot
    }

    private func appDataSnapshot() -> AppData {
        AppData(
            checkInRecords: checkInRecords,
            projects: projects,
            tasks: tasks,
            focusSessions: focusSessions,
            scheduleBlocks: scheduleBlocks,
            thesisInfos: thesisInfos,
            submissions: submissions,
            healthHabits: healthHabits,
            healthRecords: healthRecords,
            mentalCareRecords: mentalCareRecords,
            achievements: achievements
        )
    }

    private func applyAppData(_ decoded: AppData) {
        checkInRecords = decoded.checkInRecords
        projects = decoded.projects
        tasks = decoded.tasks
        focusSessions = decoded.focusSessions
        scheduleBlocks = decoded.scheduleBlocks
        thesisInfos = decoded.thesisInfos
        submissions = decoded.submissions
        healthHabits = decoded.healthHabits
        healthRecords = decoded.healthRecords
        mentalCareRecords = decoded.mentalCareRecords
        achievements = decoded.achievements
    }

    private func resetInMemoryData() {
        checkInRecords = []
        projects = []
        tasks = []
        focusSessions = []
        scheduleBlocks = []
        thesisInfos = []
        submissions = []
        healthHabits = []
        healthRecords = []
        mentalCareRecords = []
        achievements = []
    }

    private func dataBuckets(for data: AppData) -> [(relativePath: String, payload: AnyEncodable)] {
        [
            ("overview/checkins", AnyEncodable(data.checkInRecords)),
            ("projects/projects", AnyEncodable(data.projects)),
            ("projects/tasks", AnyEncodable(data.tasks)),
            ("focus/focus_sessions", AnyEncodable(data.focusSessions)),
            ("focus/schedule_blocks", AnyEncodable(data.scheduleBlocks)),
            ("thesis/thesis_infos", AnyEncodable(data.thesisInfos)),
            ("outcomes/submissions", AnyEncodable(data.submissions)),
            ("health/health_habits", AnyEncodable(data.healthHabits)),
            ("health/health_records", AnyEncodable(data.healthRecords)),
            ("mental/mental_care_records", AnyEncodable(data.mentalCareRecords)),
            ("milestones/achievements", AnyEncodable(data.achievements))
        ]
    }

    private func loadAppData(from root: URL) throws -> AppData {
        AppData(
            checkInRecords: try readArray([CheckInRecord].self, from: root, relativePath: "overview/checkins"),
            projects: try readArray([Project].self, from: root, relativePath: "projects/projects"),
            tasks: try readArray([Task].self, from: root, relativePath: "projects/tasks"),
            focusSessions: try readArray([FocusSession].self, from: root, relativePath: "focus/focus_sessions"),
            scheduleBlocks: try readArray([ScheduleBlock].self, from: root, relativePath: "focus/schedule_blocks"),
            thesisInfos: try readArray([ThesisInfo].self, from: root, relativePath: "thesis/thesis_infos"),
            submissions: try readArray([Submission].self, from: root, relativePath: "outcomes/submissions"),
            healthHabits: try readArray([HealthHabit].self, from: root, relativePath: "health/health_habits"),
            healthRecords: try readArray([HealthRecord].self, from: root, relativePath: "health/health_records"),
            mentalCareRecords: try readArray([MentalCareRecord].self, from: root, relativePath: "mental/mental_care_records"),
            achievements: try readArray([Achievement].self, from: root, relativePath: "milestones/achievements")
        )
    }

    private func readArray<T: Decodable>(_ type: [T].Type, from root: URL, relativePath: String) throws -> [T] {
        let preferredURL = root.appendingPathComponent(relativePath).appendingPathExtension(dataFileExtension)
        let legacyURL = root.appendingPathComponent(relativePath).appendingPathExtension(legacyDataFileExtension)
        let sourceURL: URL

        if FileManager.default.fileExists(atPath: preferredURL.path) {
            sourceURL = preferredURL
        } else if FileManager.default.fileExists(atPath: legacyURL.path) {
            sourceURL = legacyURL
        } else {
            return []
        }

        let raw = try Data(contentsOf: sourceURL)
        let decoded = try decodeStoredPayload(raw)
        return try decoder.decode([T].self, from: decoded)
    }

    private func decodeWorkspaceBundle(_ data: Data) -> AppData? {
        guard let decoded = try? decodeStoredPayload(data) else { return nil }
        return try? decoder.decode(AppData.self, from: decoded)
    }

    private func decodeStoredPayload(_ data: Data) throws -> Data {
        if (try? decoder.decode(AppData.self, from: data)) != nil {
            return data
        }
        if (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }
        return try deobfuscate(data)
    }

    private func obfuscate(_ data: Data) throws -> Data {
        let key = Array("orzbug.workspace".utf8)
        let body = Data(data.enumerated().map { index, byte in
            byte ^ key[index % key.count] ^ 0x5A
        })
        let wrapped = EncodedEnvelope(version: 2, payload: body.base64EncodedString())
        return try encoder.encode(wrapped)
    }

    private func deobfuscate(_ data: Data) throws -> Data {
        if let legacy = try? decoder.decode(AppData.self, from: data) {
            return try encoder.encode(legacy)
        }

        let envelope = try decoder.decode(EncodedEnvelope.self, from: data)
        guard let body = Data(base64Encoded: envelope.payload) else {
            throw NSError(domain: "AppDataStore", code: 10, userInfo: [NSLocalizedDescriptionKey: "数据内容损坏"])
        }
        let key = Array("orzbug.workspace".utf8)
        return Data(body.enumerated().map { index, byte in
            byte ^ key[index % key.count] ^ 0x5A
        })
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
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey)
            ?? UserDefaults.standard.data(forKey: legacyBookmarkKey) else { return nil }

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
        guard let path = UserDefaults.standard.string(forKey: workspacePathKey)
            ?? UserDefaults.standard.string(forKey: legacyWorkspacePathKey),
              !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func removePersistedWorkspaceReference() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: bookmarkKey)
        defaults.removeObject(forKey: workspacePathKey)
        defaults.removeObject(forKey: legacyBookmarkKey)
        defaults.removeObject(forKey: legacyWorkspacePathKey)
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

    private struct EncodedEnvelope: Codable {
        var version: Int
        var payload: String
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

    struct TodaySnapshot {
        var todayOpenTasks: Int = 0
        var dueTodayTasks: Int = 0
        var inProgressTasks: Int = 0
        var activeSubmissions: Int = 0
    }

    func computeTodaySnapshot() -> TodaySnapshot {
        let range = Date().startOfDay..<Date().endOfDay
        var snap = TodaySnapshot()
        let openTasks = tasks.filter { $0.status != .completed }
        snap.todayOpenTasks = openTasks.filter(\.isToday).count
        snap.dueTodayTasks = openTasks.filter { task in
            task.dueDate.map { range.contains($0) } ?? false
        }.count
        snap.inProgressTasks = tasks.filter { $0.status == .inProgress }.count
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

    func computeProjectBoardStats() -> ProjectBoardStats {
        var s = ProjectBoardStats()
        let projectTasks = tasks.filter { $0.projectId != nil && $0.thesisId == nil }
        s.totalProjects = projects.count
        s.activeProjects = projects.filter(\.isActive).count
        s.totalTasks = projectTasks.count
        s.incompleteTasks = projectTasks.filter { $0.status != .completed }.count
        s.dueWithin7Days = projectTasks.filter(\.isDueWithin7Days).count
        s.unassignedTasks = tasks.filter { $0.projectId == nil && $0.thesisId == nil }.count
        s.q1Tasks = projectTasks.filter { $0.priority == .urgentImportant && $0.status != .completed }.count
        s.q2Tasks = projectTasks.filter { $0.priority == .important && $0.status != .completed }.count
        s.q3Tasks = projectTasks.filter { $0.priority == .urgent && $0.status != .completed }.count
        s.q4Tasks = projectTasks.filter { $0.priority == .low && $0.status != .completed }.count
        s.todayMustDo = projectTasks.filter { $0.isToday && ($0.priority == .urgentImportant || $0.priority == .urgent) && $0.status != .completed }.count
        s.todayShouldDo = projectTasks.filter { $0.isToday && $0.priority == .important && $0.status != .completed }.count
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
