import Foundation

struct Submission: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var type: ResearchOutcomeType
    var targetJournal: String
    var targetIdentifier: String
    var collaborators: String
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
    var attachments: [FileAttachment]
    var createdAt: Date
    var updatedAt: Date
    var logs: [SubmissionLog]

    init(
        id: UUID = UUID(),
        name: String = "",
        type: ResearchOutcomeType = .paper,
        targetJournal: String = "",
        targetIdentifier: String = "",
        collaborators: String = "",
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
        attachments: [FileAttachment] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.targetJournal = targetJournal
        self.targetIdentifier = targetIdentifier
        self.collaborators = collaborators
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
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.logs = []
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, targetJournal, targetIdentifier, collaborators, summary
        case ccfGrade, sciGrade, isEI, isCorrespondingAuthor, authors, authorOrder, patentStatus, relatedStudents
        case stage, attachments, createdAt, updatedAt, logs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(ResearchOutcomeType.self, forKey: .type) ?? .paper
        targetJournal = try container.decodeIfPresent(String.self, forKey: .targetJournal) ?? ""
        targetIdentifier = try container.decodeIfPresent(String.self, forKey: .targetIdentifier) ?? ""
        collaborators = try container.decodeIfPresent(String.self, forKey: .collaborators) ?? ""
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
        attachments = try container.decodeIfPresent([FileAttachment].self, forKey: .attachments) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        logs = try container.decodeIfPresent([SubmissionLog].self, forKey: .logs) ?? []
    }

    var isActive: Bool { stage.isActive }

    var targetLabel: String {
        switch type {
        case .paper: return "目标期刊/会议"
        case .patent: return "专利受理单位"
        case .award: return "奖项组织方"
        case .other: return "目标单位"
        }
    }

    var authorOrderText: String {
        guard let authorOrder else { return "作者顺序未填" }
        return "第 \(authorOrder) 作者"
    }
}
