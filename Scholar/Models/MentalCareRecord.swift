import Foundation

struct MentalCareRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var mood: Int
    var stressLevel: Int
    var energyLevel: Int
    var weather: String
    var drainSource: String
    var selfCare: String
    var gratitude: String
    var supportNeeded: String
    var selfTalk: String

    init(id: UUID = UUID(), date: Date = Date(), mood: Int = 3, stressLevel: Int = 3, energyLevel: Int = 3, weather: String = "☀️ 晴", drainSource: String = "", selfCare: String = "", gratitude: String = "", supportNeeded: String = "", selfTalk: String = "") {
        self.id = id; self.date = date; self.mood = mood; self.stressLevel = stressLevel; self.energyLevel = energyLevel; self.weather = weather; self.drainSource = drainSource; self.selfCare = selfCare; self.gratitude = gratitude; self.supportNeeded = supportNeeded; self.selfTalk = selfTalk
    }

    var moodEmoji: String {
        switch mood {
        case 1: return "😫"
        case 2: return "😟"
        case 3: return "😕"
        case 4: return "😐"
        case 5: return "😬"
        case 6: return "😠"
        case 7: return "😤"
        case 8: return "🙂"
        case 9: return "😊"
        case 10: return "🤩"
        case 11: return "🥺"
        case 12: return "😑"
        case 13: return "🥱"
        case 14: return "😣"
        case 15: return "😄"
        default: return "😐"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, mood, stressLevel, energyLevel, weather, drainSource, selfCare, gratitude, supportNeeded, selfTalk
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        mood = try container.decodeIfPresent(Int.self, forKey: .mood) ?? 3
        stressLevel = try container.decodeIfPresent(Int.self, forKey: .stressLevel) ?? 3
        energyLevel = try container.decodeIfPresent(Int.self, forKey: .energyLevel) ?? 3
        weather = try container.decodeIfPresent(String.self, forKey: .weather) ?? "☀️ 晴"
        drainSource = try container.decodeIfPresent(String.self, forKey: .drainSource) ?? ""
        selfCare = try container.decodeIfPresent(String.self, forKey: .selfCare) ?? ""
        gratitude = try container.decodeIfPresent(String.self, forKey: .gratitude) ?? ""
        supportNeeded = try container.decodeIfPresent(String.self, forKey: .supportNeeded) ?? ""
        selfTalk = try container.decodeIfPresent(String.self, forKey: .selfTalk) ?? ""
    }
}
