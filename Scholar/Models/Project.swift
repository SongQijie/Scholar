import Foundation

struct Project: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var result: String
    var sharedDocumentLink: String
    var category: ProjectCategory
    var stage: ProjectStage
    var priority: ProjectPriority
    var owner: String
    var collaborators: String
    var summary: String
    var keywords: [String]
    var fundingSource: String
    var expectedDeliverables: String
    var budget: Double?
    var startDate: Date?
    var deadline: Date?
    var notes: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        result: String = "",
        sharedDocumentLink: String = "",
        category: ProjectCategory = .horizontal,
        stage: ProjectStage = .planning,
        priority: ProjectPriority = .medium,
        owner: String = "",
        collaborators: String = "",
        summary: String = "",
        keywords: [String] = [],
        fundingSource: String = "",
        expectedDeliverables: String = "",
        budget: Double? = nil,
        startDate: Date? = nil,
        deadline: Date? = nil,
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.result = result
        self.sharedDocumentLink = sharedDocumentLink
        self.category = category
        self.stage = stage
        self.priority = priority
        self.owner = owner
        self.collaborators = collaborators
        self.summary = summary
        self.keywords = keywords
        self.fundingSource = fundingSource
        self.expectedDeliverables = expectedDeliverables
        self.budget = budget
        self.startDate = startDate
        self.deadline = deadline
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var isActive: Bool {
        !isArchived && stage != .completed && stage != .paused
    }

    var keywordText: String {
        keywords.joined(separator: " / ")
    }

    enum CodingKeys: String, CodingKey {
        case id, name, result, sharedDocumentLink, category, stage, priority, owner, collaborators, summary, keywords, fundingSource, expectedDeliverables, budget, startDate, deadline, notes, isArchived, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        result = try container.decodeIfPresent(String.self, forKey: .result) ?? ""
        sharedDocumentLink = try container.decodeIfPresent(String.self, forKey: .sharedDocumentLink) ?? ""
        category = try container.decodeIfPresent(ProjectCategory.self, forKey: .category) ?? .horizontal
        stage = try container.decodeIfPresent(ProjectStage.self, forKey: .stage) ?? .planning
        priority = try container.decodeIfPresent(ProjectPriority.self, forKey: .priority) ?? .medium
        owner = try container.decodeIfPresent(String.self, forKey: .owner) ?? ""
        collaborators = try container.decodeIfPresent(String.self, forKey: .collaborators) ?? ""
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        fundingSource = try container.decodeIfPresent(String.self, forKey: .fundingSource) ?? ""
        expectedDeliverables = try container.decodeIfPresent(String.self, forKey: .expectedDeliverables) ?? ""
        budget = try container.decodeIfPresent(Double.self, forKey: .budget)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct Affair: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var details: String
    var dueDate: Date?
    var source: String
    var tags: [String]
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        details: String = "",
        dueDate: Date? = nil,
        source: String = "",
        tags: [String] = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.source = source
        self.tags = tags
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var tagText: String {
        tags.joined(separator: " / ")
    }

    var sectionTitle: String {
        let ddl = dueDate?.formatted("yyyy-MM-dd") ?? "未设DDL"
        return "\(title)-\(ddl)"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, details, dueDate, source, tags, isArchived, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
