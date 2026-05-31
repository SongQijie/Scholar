import Foundation
import Combine
import AppKit

// MARK: - Submission Statistics
struct SubmissionStats {
    var totalCount: Int = 0
    var activeCount: Int = 0
    var rejectedCount: Int = 0
    var acceptedPapers: Int = 0
    var authorizedPatents: Int = 0
    var awards: Int = 0
    var otherAchievements: Int = 0
}

// MARK: - Submission ViewModel
class SubmissionViewModel: ObservableObject {
    @Published var timeRange: TimeRange = .weekly
    @Published var showNewSubmissionForm: Bool = false
    @Published var newSubmissionName: String = ""
    @Published var newOutcomeType: ResearchOutcomeType = .paper
    @Published var newPersonalRank: String = ""
    @Published var newTargetJournal: String = ""
    @Published var newTargetIdentifier: String = ""
    @Published var newCollaborators: String = ""
    @Published var newAwardLevel: String = ""
    @Published var newSubmissionSummary: String = ""
    @Published var newCCFGrade: CCFGrade = .none
    @Published var newSCIGrade: SCIGrade = .none
    @Published var newIsEI: Bool = false
    @Published var newIsCorrespondingAuthor: Bool = false
    @Published var newAuthors: String = ""
    @Published var newAuthorOrder: String = ""
    @Published var newPatentStatus: PatentStatus = .submitted
    @Published var newPaperStatus: PaperStatus = .submitted
    @Published var newRelatedStudents: String = ""
    @Published var newSubmissionDate: Date?
    @Published var newAcceptanceDate: Date?
    @Published var pendingAttachmentURLs: [URL] = []
    @Published var showNewLogForm: Bool = false
    @Published var newLogContent: String = ""
    @Published var selectedSubmissionId: UUID?
    @Published var stats: SubmissionStats = .init()
    // 归档筛选
    @Published var archiveFilterType: ResearchOutcomeType?
    @Published var archiveFilterYear: Int?
    @Published var archiveFilterMonth: Int?

    private var store: AppDataStore { AppDataStore.shared }

    // MARK: - Computed Properties

    var activeSubmissions: [Submission] {
        store.submissions.filter { $0.isActive && !$0.isArchived }
    }

    var archivedSubmissions: [Submission] {
        var submissions = store.submissions.filter {
            !$0.isActive || $0.isArchived || $0.type == .award || $0.type == .other
        }
        // 应用筛选
        if let filterType = archiveFilterType {
            submissions = submissions.filter { $0.type == filterType }
        }
        if let filterYear = archiveFilterYear, let filterMonth = archiveFilterMonth {
            let calendar = Calendar.current
            submissions = submissions.filter { submission in
                let date = submission.acceptanceDate ?? submission.createdAt
                let components = calendar.dateComponents([.year, .month], from: date)
                return components.year == filterYear && components.month == filterMonth
            }
        } else if let filterYear = archiveFilterYear {
            let calendar = Calendar.current
            submissions = submissions.filter { submission in
                let date = submission.acceptanceDate ?? submission.createdAt
                return calendar.component(.year, from: date) == filterYear
            }
        }
        return submissions
    }

    var paperSubmissions: [Submission] {
        activeSubmissions.filter { $0.type == .paper }
    }

    var patentSubmissions: [Submission] {
        activeSubmissions.filter { $0.type == .patent }
    }

    var selectedSubmission: Submission? {
        guard let id = selectedSubmissionId else { return nil }
        return store.submissions.first { $0.id == id }
    }

    var selectedSubmissionLogs: [SubmissionLog] {
        selectedSubmission?.logs.sorted { $0.date > $1.date } ?? []
    }

    var availableYears: [Int] {
        let dates = store.submissions.map { $0.acceptanceDate ?? $0.createdAt }
        let years = Set(dates.map { Calendar.current.component(.year, from: $0) })
        return years.sorted(by: >)
    }

    // MARK: - Data Loading

    func loadData() {
        computeStats()
    }

    // MARK: - CRUD

    func addSubmission() {
        let name = newSubmissionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let submissionID = UUID()
        let attachments = pendingAttachmentURLs.compactMap { store.importAttachment(from: $0, for: submissionID) }
        
        // 奖项和其他添加即归档
        let isAutomaticallyArchived = newOutcomeType == .award || newOutcomeType == .other
        
        let submission = Submission(
            id: submissionID,
            name: name,
            type: newOutcomeType,
            personalRank: newPersonalRank.trimmingCharacters(in: .whitespacesAndNewlines),
            targetJournal: newTargetJournal.trimmingCharacters(in: .whitespaces),
            targetIdentifier: newTargetIdentifier.trimmingCharacters(in: .whitespaces),
            collaborators: newCollaborators.trimmingCharacters(in: .whitespaces),
            awardLevel: newOutcomeType == .award ? newAwardLevel.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            summary: newOutcomeType == .patent ? "" : newSubmissionSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            ccfGrade: newOutcomeType == .paper ? newCCFGrade : .none,
            sciGrade: newOutcomeType == .paper ? newSCIGrade : .none,
            isEI: newOutcomeType == .paper && newIsEI,
            isCorrespondingAuthor: newOutcomeType == .paper && newIsCorrespondingAuthor,
            authors: newOutcomeType == .paper ? newAuthors.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            authorOrder: newOutcomeType == .paper ? Int(newAuthorOrder) : nil,
            patentStatus: newOutcomeType == .patent ? newPatentStatus : .submitted,
            relatedStudents: newOutcomeType == .patent ? newRelatedStudents.normalizedLines : [],
            stage: newOutcomeType == .patent ? submissionStage(for: newPatentStatus) : .preparing,
            paperStatus: newPaperStatus,
            submissionDate: newSubmissionDate,
            acceptanceDate: newAcceptanceDate,
            isArchived: isAutomaticallyArchived,
            attachments: attachments
        )
        store.submissions.append(submission)
        store.save()
        resetForm()
        loadData()
    }

    func archiveSubmission(_ submission: Submission) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].isArchived = true
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func unarchiveSubmission(_ submission: Submission) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].isArchived = false
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func updatePaperStatus(_ submission: Submission, status: PaperStatus) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].paperStatus = status
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func updatePatentStatus(_ submission: Submission, status: PatentStatus) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].patentStatus = status
            store.submissions[idx].stage = submissionStage(for: status)
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func deleteSubmission(_ submission: Submission) {
        store.submissions.removeAll { $0.id == submission.id }
        if selectedSubmissionId == submission.id {
            selectedSubmissionId = nil
        }
        store.save()
        loadData()
    }

    func addLog(to submission: Submission) {
        let content = newLogContent.trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return }
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            let log = SubmissionLog(content: content)
            store.submissions[idx].logs.append(log)
            store.submissions[idx].updatedAt = Date()
            store.save()
            newLogContent = ""
            showNewLogForm = false
            loadData()
        }
    }

    func deleteLog(_ log: SubmissionLog, from submission: Submission) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].logs.removeAll { $0.id == log.id }
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func addPendingAttachment(from url: URL) {
        pendingAttachmentURLs.append(url)
    }

    func attachFile(to submission: Submission, from url: URL) {
        guard let attachment = store.importAttachment(from: url, for: submission.id) else { return }
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].attachments.append(attachment)
            store.submissions[idx].updatedAt = Date()
            store.save()
            loadData()
        }
    }

    func openAttachment(_ attachment: FileAttachment) {
        guard let url = store.attachmentURL(for: attachment) else { return }
        NSWorkspace.shared.open(url)
    }

    private func resetForm() {
        newSubmissionName = ""
        newOutcomeType = .paper
        newPersonalRank = ""
        newTargetJournal = ""
        newTargetIdentifier = ""
        newCollaborators = ""
        newAwardLevel = ""
        newSubmissionSummary = ""
        newCCFGrade = .none
        newSCIGrade = .none
        newIsEI = false
        newIsCorrespondingAuthor = false
        newAuthors = ""
        newAuthorOrder = ""
        newPatentStatus = .submitted
        newPaperStatus = .submitted
        newRelatedStudents = ""
        newSubmissionDate = nil
        newAcceptanceDate = nil
        pendingAttachmentURLs = []
        showNewSubmissionForm = false
    }

    // MARK: - Statistics

    func computeStats() {
        let submissions = store.submissions
        
        stats.totalCount = submissions.count
        stats.activeCount = submissions.filter { $0.isActive && !$0.isArchived }.count
        stats.rejectedCount = submissions.filter { $0.stage == .rejected }.count
        stats.acceptedPapers = submissions.filter { $0.type == .paper && ($0.paperStatus == .accepted || $0.stage == .accepted || $0.stage == .published) }.count
        stats.authorizedPatents = submissions.filter { $0.type == .patent && $0.patentStatus == .authorized }.count
        stats.awards = submissions.filter { $0.type == .award }.count
        stats.otherAchievements = submissions.filter { $0.type == .other }.count
    }

    // MARK: - Stage Flow

    func submissionStage(for patentStatus: PatentStatus) -> SubmissionStage {
        switch patentStatus {
        case .fastPreliminary: return .preparing
        case .submitted: return .submitted
        case .accepted: return .underReview
        case .published: return .revising
        case .authorized: return .accepted
        }
    }

    // MARK: - Export

    func exportLogsAsMarkdown(for submission: Submission) -> String {
        var lines: [String] = []
        lines.append("# \(submission.name)")
        lines.append("")
        lines.append("- **成果类型**: \(submission.type.displayName)")
        if !submission.personalRank.isEmpty {
            lines.append("- **本人排名**: \(submission.personalRank)")
        }
        lines.append("- **目标期刊**: \(submission.targetJournal)")
        if !submission.targetIdentifier.isEmpty {
            lines.append("- **编号/奖项信息**: \(submission.targetIdentifier)")
        }
        if submission.type == .award, !submission.awardLevel.isEmpty {
            lines.append("- **几等奖**: \(submission.awardLevel)")
        }
        if !submission.collaborators.isEmpty {
            lines.append("- **合作方**: \(submission.collaborators)")
        }
        if submission.type == .paper {
            lines.append("- **论文状态**: \(submission.paperStatus.displayName)")
            lines.append("- **CCF 分级**: \(submission.ccfGrade.displayName)")
            lines.append("- **SCI 分区**: \(submission.sciGrade.displayName)")
            lines.append("- **EI**: \(submission.isEI ? "是" : "否")")
            lines.append("- **是否通讯**: \(submission.isCorrespondingAuthor ? "是" : "否")")
            if !submission.authors.isEmpty {
                lines.append("- **作者**: \(submission.authors)")
            }
            if let authorOrder = submission.authorOrder {
                lines.append("- **作者顺序**: 第 \(authorOrder) 作者")
            }
            if let submissionDate = submission.submissionDate {
                lines.append("- **投递日期**: \(submissionDate.formatted(date: .abbreviated, time: .omitted))")
            }
            if let acceptanceDate = submission.acceptanceDate {
                lines.append("- **录用日期**: \(acceptanceDate.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        if submission.type == .patent {
            lines.append("- **专利状态**: \(submission.patentStatus.displayName)")
            if !submission.relatedStudents.isEmpty {
                lines.append("- **关联学生**: \(submission.relatedStudents.joined(separator: "、"))")
            }
            if let submissionDate = submission.submissionDate {
                lines.append("- **投递日期**: \(submissionDate.formatted(date: .abbreviated, time: .omitted))")
            }
            if let acceptanceDate = submission.acceptanceDate {
                lines.append("- **授权日期**: \(acceptanceDate.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        lines.append("- **当前阶段**: \(submission.stage.displayName)")
        lines.append("- **创建日期**: \(submission.createdAt.formatted(date: .abbreviated, time: .shortened))")
        lines.append("- **更新日期**: \(submission.updatedAt.formatted(date: .abbreviated, time: .shortened))")
        if !submission.summary.isEmpty {
            lines.append("- **摘要**: \(submission.summary)")
        }
        if !submission.attachments.isEmpty {
            lines.append("- **附件数**: \(submission.attachments.count)")
        }
        lines.append("")

        let sortedLogs = submission.logs.sorted { $0.date > $1.date }
        if sortedLogs.isEmpty {
            lines.append("## 推进日志")
            lines.append("")
            lines.append("*暂无日志*")
        } else {
            lines.append("## 推进日志 (\(sortedLogs.count))")
            lines.append("")
            for log in sortedLogs {
                let dateStr = log.date.formatted(date: .abbreviated, time: .shortened)
                lines.append("### \(dateStr)")
                lines.append("")
                lines.append(log.content)
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }
}
