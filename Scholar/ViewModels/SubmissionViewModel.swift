import Foundation
import Combine
import AppKit

// MARK: - Submission Statistics
struct SubmissionStats {
    var totalCount: Int = 0
    var activeCount: Int = 0
    var publishedCount: Int = 0
    var rejectedCount: Int = 0
    var newThisPeriod: Int = 0
}

// MARK: - Submission View Model
class SubmissionViewModel: ObservableObject {
    @Published var timeRange: TimeRange = .weekly
    @Published var showNewSubmissionForm: Bool = false
    @Published var newSubmissionName: String = ""
    @Published var newOutcomeType: ResearchOutcomeType = .paper
    @Published var newTargetJournal: String = ""
    @Published var newTargetIdentifier: String = ""
    @Published var newCollaborators: String = ""
    @Published var newSubmissionSummary: String = ""
    @Published var newCCFGrade: CCFGrade = .none
    @Published var newSCIGrade: SCIGrade = .none
    @Published var newIsEI: Bool = false
    @Published var newIsCorrespondingAuthor: Bool = false
    @Published var newAuthors: String = ""
    @Published var newAuthorOrder: String = ""
    @Published var newPatentStatus: PatentStatus = .submitted
    @Published var newRelatedStudents: String = ""
    @Published var pendingAttachmentURLs: [URL] = []
    @Published var showNewLogForm: Bool = false
    @Published var newLogContent: String = ""
    @Published var selectedSubmissionId: UUID? = nil
    @Published var stats: SubmissionStats = .init()

    private var store: AppDataStore { AppDataStore.shared }

    // MARK: - Computed Properties

    var activeSubmissions: [Submission] {
        store.submissions.filter { $0.isActive }
    }

    var archivedSubmissions: [Submission] {
        store.submissions.filter { !$0.isActive }
    }

    var submissionsByStage: [SubmissionStage: [Submission]] {
        Dictionary(grouping: store.submissions, by: \.stage)
    }

    var selectedSubmission: Submission? {
        guard let id = selectedSubmissionId else { return nil }
        return store.submissions.first { $0.id == id }
    }

    var selectedSubmissionLogs: [SubmissionLog] {
        selectedSubmission?.logs.sorted { $0.date > $1.date } ?? []
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
        let submission = Submission(
            id: submissionID,
            name: name,
            type: newOutcomeType,
            targetJournal: newTargetJournal.trimmingCharacters(in: .whitespaces),
            targetIdentifier: newTargetIdentifier.trimmingCharacters(in: .whitespaces),
            collaborators: newCollaborators.trimmingCharacters(in: .whitespaces),
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
            attachments: attachments
        )
        store.submissions.append(submission)
        store.save()
        newSubmissionName = ""
        newOutcomeType = .paper
        newTargetJournal = ""
        newTargetIdentifier = ""
        newCollaborators = ""
        newSubmissionSummary = ""
        newCCFGrade = .none
        newSCIGrade = .none
        newIsEI = false
        newIsCorrespondingAuthor = false
        newAuthors = ""
        newAuthorOrder = ""
        newPatentStatus = .submitted
        newRelatedStudents = ""
        pendingAttachmentURLs = []
        showNewSubmissionForm = false
        loadData()
    }

    func updateSubmissionStage(_ submission: Submission, stage: SubmissionStage) {
        if let idx = store.submissions.firstIndex(where: { $0.id == submission.id }) {
            store.submissions[idx].stage = stage
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

    // MARK: - Statistics

    func computeStats() {
        let submissions = store.submissions
        let dateRange = store.dateRange(for: timeRange)

        stats.totalCount = submissions.count
        stats.activeCount = submissions.filter(\.isActive).count
        stats.publishedCount = submissions.filter { $0.stage == .published }.count
        stats.rejectedCount = submissions.filter { $0.stage == .rejected }.count
        stats.newThisPeriod = submissions.filter { $0.createdAt >= dateRange.lowerBound && $0.createdAt <= dateRange.upperBound }.count
    }

    // MARK: - Stage Flow

    func nextStage(for stage: SubmissionStage) -> SubmissionStage? {
        switch stage {
        case .preparing:   return .writing
        case .writing:     return .submitted
        case .submitted:   return .underReview
        case .underReview: return .revising
        case .revising:    return .accepted
        case .accepted:    return .published
        case .published:   return nil
        case .rejected:    return nil
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

    func submissionStage(for patentStatus: PatentStatus) -> SubmissionStage {
        switch patentStatus {
        case .submitted: return .submitted
        case .accepted: return .underReview
        case .published: return .published
        case .authorized: return .accepted
        }
    }

    // MARK: - Export

    func exportLogsAsMarkdown(for submission: Submission) -> String {
        var lines: [String] = []
        lines.append("# \(submission.name)")
        lines.append("")
        lines.append("- **成果类型**: \(submission.type.displayName)")
        lines.append("- **目标期刊**: \(submission.targetJournal)")
        if !submission.targetIdentifier.isEmpty {
            lines.append("- **编号/奖项信息**: \(submission.targetIdentifier)")
        }
        if !submission.collaborators.isEmpty {
            lines.append("- **合作方**: \(submission.collaborators)")
        }
        if submission.type == .paper {
            lines.append("- **CCF 分级**: \(submission.ccfGrade.displayName)")
            lines.append("- **SCI 分区**: \(submission.sciGrade.displayName)")
            lines.append("- **EI**: \(submission.isEI ? "是" : "否")")
            lines.append("- **通讯作者**: \(submission.isCorrespondingAuthor ? "是" : "否")")
            if !submission.authors.isEmpty {
                lines.append("- **作者**: \(submission.authors)")
            }
            if let authorOrder = submission.authorOrder {
                lines.append("- **作者顺序**: 第 \(authorOrder) 作者")
            }
        }
        if submission.type == .patent {
            lines.append("- **专利状态**: \(submission.patentStatus.displayName)")
            if !submission.relatedStudents.isEmpty {
                lines.append("- **关联学生**: \(submission.relatedStudents.joined(separator: "、"))")
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
