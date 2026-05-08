import Foundation

struct HealthRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var habitId: UUID
    var date: Date
    var timeValue: Date?
    var durationValue: Double?
    var countValue: Int?
    var textValue: String?
    var mealType: MealType?
    var weightValue: Double?
    var createdAt: Date

    init(id: UUID = UUID(), habitId: UUID = UUID(), date: Date = Date(), timeValue: Date? = nil, durationValue: Double? = nil, countValue: Int? = nil, textValue: String? = nil, mealType: MealType? = nil, weightValue: Double? = nil, createdAt: Date = Date()) {
        self.id = id; self.habitId = habitId; self.date = date; self.timeValue = timeValue; self.durationValue = durationValue; self.countValue = countValue; self.textValue = textValue; self.mealType = mealType; self.weightValue = weightValue; self.createdAt = createdAt
    }
}
