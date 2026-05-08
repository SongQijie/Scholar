import Foundation

struct HealthHabit: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var recordType: HealthRecordType
    var targetValue: Double
    var isActive: Bool
    var createdAt: Date

    init(id: UUID = UUID(), name: String = "", icon: String = "", recordType: HealthRecordType = .checkin, targetValue: Double = 1, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.icon = icon; self.recordType = recordType; self.targetValue = targetValue; self.isActive = isActive; self.createdAt = createdAt
    }
}
