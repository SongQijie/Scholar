import Foundation

struct Submission: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var type: ResearchOutcomeType
    var personalRank: String
    var targetJournal: String
    var targetIdentifier: String
    var collaborators: String
    var awardLevel: String
    var summary: String
    var ccfGrade: CCFGrade
    var sciGrade: SCIGrade
    var isEI: Bool
    var isCorrespondingAuthor: Bool
    var authors: String
    var authorOrder: Int?
    var patentStatus: PatentStatus
    var relatedStudents: [String]
    var stage: SubmissionStage
    var paperStatus: PaperStatus
    var submissionDate: Date?
    var acceptanceDate: Date?
    var isArchived: Bool
    var attachments: [FileAttachment]
    var createdAt: Date
    var updatedAt: Date
    var logs: [SubmissionLog]

    init(
        id: UUID = UUID(),
        name: String = "",
        type: ResearchOutcomeType = .paper,
        personalRank: String = "",
        targetJournal: String = "",
        targetIdentifier: String = "",
        collaborators: String = "",
        awardLevel: String = "",
        summary: String = "",
        ccfGrade: CCFGrade = .none,
        sciGrade: SCIGrade = .none,
        isEI: Bool = false,
        isCorrespondingAuthor: Bool = false,
        authors: String = "",
        authorOrder: Int? = nil,
        patentStatus: PatentStatus = .submitted,
        relatedStudents: [String] = [],
        stage: SubmissionStage = .preparing,
        paperStatus: PaperStatus = .submitted,
        submissionDate: Date? = nil,
        acceptanceDate: Date? = nil,
        isArchived: Bool = false,
        attachments: [FileAttachment] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.personalRank = personalRank
        self.targetJournal = targetJournal
        self.targetIdentifier = targetIdentifier
        self.collaborators = collaborators
        self.awardLevel = awardLevel
        self.summary = summary
        self.ccfGrade = ccfGrade
        self.sciGrade = sciGrade
        self.isEI = isEI
        self.isCorrespondingAuthor = isCorrespondingAuthor
        self.authors = authors
        self.authorOrder = authorOrder
        self.patentStatus = patentStatus
        self.relatedStudents = relatedStudents
        self.stage = stage
        self.paperStatus = paperStatus
        self.submissionDate = submissionDate
        self.acceptanceDate = acceptanceDate
        self.isArchived = isArchived
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.logs = []
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, personalRank, targetJournal, targetIdentifier, collaborators, awardLevel, summary
        case ccfGrade, sciGrade, isEI, isCorrespondingAuthor, authors, authorOrder, patentStatus, relatedStudents
        case stage, paperStatus, submissionDate, acceptanceDate, isArchived, attachments, createdAt, updatedAt, logs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(ResearchOutcomeType.self, forKey: .type) ?? .paper
        personalRank = try container.decodeIfPresent(String.self, forKey: .personalRank) ?? ""
        targetJournal = try container.decodeIfPresent(String.self, forKey: .targetJournal) ?? ""
        targetIdentifier = try container.decodeIfPresent(String.self, forKey: .targetIdentifier) ?? ""
        collaborators = try container.decodeIfPresent(String.self, forKey: .collaborators) ?? ""
        awardLevel = try container.decodeIfPresent(String.self, forKey: .awardLevel) ?? ""
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        ccfGrade = try container.decodeIfPresent(CCFGrade.self, forKey: .ccfGrade) ?? .none
        sciGrade = try container.decodeIfPresent(SCIGrade.self, forKey: .sciGrade) ?? .none
        isEI = try container.decodeIfPresent(Bool.self, forKey: .isEI) ?? false
        isCorrespondingAuthor = try container.decodeIfPresent(Bool.self, forKey: .isCorrespondingAuthor) ?? false
        authors = try container.decodeIfPresent(String.self, forKey: .authors) ?? ""
        authorOrder = try container.decodeIfPresent(Int.self, forKey: .authorOrder)
        patentStatus = try container.decodeIfPresent(PatentStatus.self, forKey: .patentStatus) ?? .submitted
        relatedStudents = try container.decodeIfPresent([String].self, forKey: .relatedStudents) ?? []
        stage = try container.decodeIfPresent(SubmissionStage.self, forKey: .stage) ?? .preparing
        paperStatus = try container.decodeIfPresent(PaperStatus.self, forKey: .paperStatus) ?? .submitted
        submissionDate = try container.decodeIfPresent(Date.self, forKey: .submissionDate)
        acceptanceDate = try container.decodeIfPresent(Date.self, forKey: .acceptanceDate)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        attachments = try container.decodeIfPresent([FileAttachment].self, forKey: .attachments) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        logs = try container.decodeIfPresent([SubmissionLog].self, forKey: .logs) ?? []
    }

    var isActive: Bool {
        if isArchived {
            return false
        }
        // 奖项和其他添加即归档
        if type == .award || type == .other {
            return false
        }
        // 论文录用后可归档
        if type == .paper && paperStatus == .accepted {
            return false
        }
        // 专利授权后可归档
        if type == .patent && patentStatus == .authorized {
            return false
        }
        return true
    }

    var targetLabel: String {
        switch type {
        case .paper: return "目标期刊/会议"
        case .patent: return "发明人"
        case .award: return "奖项类别"
        case .other: return "内容"
        }
    }

    var authorOrderText: String {
        guard let authorOrder else { return "作者顺序未填" }
        return "第 \(authorOrder) 作者"
    }
}
