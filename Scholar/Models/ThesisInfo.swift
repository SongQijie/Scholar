import Foundation

struct ThesisInfo: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var stage: ThesisStage
    var currentVersion: String
    var notes: String
    var sharedDocumentLink: String
    var dueDate: Date?
    var isArchived: Bool
    var students: [Student] // 关联学生
    var milestones: [Milestone]
    var chapters: [Chapter]
    var logs: [ThesisLog]

    init(
        id: UUID = UUID(),
        title: String = "",
        stage: ThesisStage = .literatureReview,
        currentVersion: String = "",
        notes: String = "",
        sharedDocumentLink: String = "",
        dueDate: Date? = nil,
        isArchived: Bool = false,
        students: [Student] = []
    ) {
        self.id = id
        self.title = title
        self.stage = stage
        self.currentVersion = currentVersion
        self.notes = notes
        self.sharedDocumentLink = sharedDocumentLink
        self.dueDate = dueDate
        self.isArchived = isArchived
        self.students = students
        self.milestones = []
        self.chapters = []
        self.logs = []
    }

    var overallProgress: Double {
        let mp = milestones.isEmpty ? 0 : Double(milestones.filter(\.isCompleted).count) / Double(milestones.count)
        let cp = chapters.isEmpty ? 0 : chapters.reduce(0.0) { $0 + Double($1.progress) } / Double(chapters.count * 100)
        return (mp + cp) / 2.0
    }

    enum CodingKeys: String, CodingKey {
        case id, title, stage, defenseDate, currentVersion, notes, sharedDocumentLink, dueDate, isArchived, content, students, milestones, chapters, logs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        stage = try container.decodeIfPresent(ThesisStage.self, forKey: .stage) ?? .literatureReview
        currentVersion = try container.decodeIfPresent(String.self, forKey: .currentVersion) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        sharedDocumentLink = try container.decodeIfPresent(String.self, forKey: .sharedDocumentLink)
            ?? container.decodeIfPresent(String.self, forKey: .content)
            ?? ""
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        students = try container.decodeIfPresent([Student].self, forKey: .students) ?? []
        milestones = try container.decodeIfPresent([Milestone].self, forKey: .milestones) ?? []
        chapters = try container.decodeIfPresent([Chapter].self, forKey: .chapters) ?? []
        logs = try container.decodeIfPresent([ThesisLog].self, forKey: .logs) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(stage, forKey: .stage)
        try container.encode(currentVersion, forKey: .currentVersion)
        try container.encode(notes, forKey: .notes)
        try container.encode(sharedDocumentLink, forKey: .sharedDocumentLink)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(students, forKey: .students)
        try container.encode(milestones, forKey: .milestones)
        try container.encode(chapters, forKey: .chapters)
        try container.encode(logs, forKey: .logs)
    }
}

struct Student: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var email: String?
    var role: String // 例如：主导学生、合作学生

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String? = nil,
        role: String = "主导学生"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }
}
