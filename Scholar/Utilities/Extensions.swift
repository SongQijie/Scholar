import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case chinese = "zh-Hans"
    case english = "en"

    static let userDefaultsKey = "Scholar.AppLanguage"
    private static let legacyUserDefaultsKey = "PhDMasterWorkspace.AppLanguage"

    var id: String { rawValue }

    static var `default`: AppLanguage {
        if let preferred = Locale.preferredLanguages.first, preferred.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }

    static var storedPreference: AppLanguage {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey)
                ?? UserDefaults.standard.string(forKey: legacyUserDefaultsKey),
            let language = AppLanguage(rawValue: rawValue)
        else {
            return .default
        }
        return language
    }

    var localeIdentifier: String {
        switch self {
        case .chinese:
            return "zh_CN"
        case .english:
            return "en_US_POSIX"
        }
    }

    var displayName: String {
        text("中文", "English")
    }

    func text(_ chinese: String, _ english: String) -> String {
        switch self {
        case .chinese:
            return chinese
        case .english:
            return english
        }
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = calendar.firstWeekday
        return calendar.date(from: components) ?? startOfDay
    }

    var endOfWeek: Date {
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? endOfDay
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? startOfDay
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? endOfDay
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isSameDay: (Date) -> Bool {
        { [self] otherDate in
            Calendar.current.isDate(self, inSameDayAs: otherDate)
        }
    }

    func formatted(_ format: String = "yyyy/MM/dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: AppLanguage.storedPreference.localeIdentifier)
        return formatter.string(from: self)
    }

    func timeFormatted(_ format: String = "HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var weekdaySymbol: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLanguage.storedPreference.localeIdentifier)
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions
extension TimeInterval {
    var formattedAsDuration: String {
        let totalMinutes = Int(self) / 60
        let language = AppLanguage.storedPreference
        if totalMinutes < 60 {
            return language.text("\(totalMinutes) 分钟", "\(totalMinutes) min")
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return language.text("\(hours) 小时", "\(hours) hr")
        }
        return language.text("\(hours)小时\(minutes)分钟", "\(hours) hr \(minutes) min")
    }
}

// MARK: - Int Extensions
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - String Extensions
extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }

    var normalizedLines: [String] {
        split(whereSeparator: { [",", "，", "\n", ";", "；"].contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(\.isNotEmpty)
    }
}

// MARK: - Color Hex Extension
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    init(light: Color, dark: Color) {
#if canImport(AppKit)
        self.init(
            nsColor: NSColor(
                name: nil,
                dynamicProvider: { appearance in
                    switch appearance.bestMatch(from: [.darkAqua, .aqua]) {
                    case .darkAqua:
                        return NSColor(dark)
                    default:
                        return NSColor(light)
                    }
                }
            )
        )
#else
        self = light
#endif
    }
}
