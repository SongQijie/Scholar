import SwiftUI

// MARK: - App Theme
enum AppTheme {
    // MARK: - Brand Colors (Modern Gradient Palette)
    static let primary = Color(hex: "2F6FED")      // Scholarly Blue
    static let primaryLight = Color(hex: "60A5FA") // Sky
    static let primaryDark = Color(hex: "1D4ED8")  // Deep Blue
    
    static let secondary = Color(hex: "0891B2")    // Cyan
    static let accent = Color(hex: "D97706")       // Amber
    static let success = Color(hex: "059669")      // Emerald
    static let warning = Color(hex: "EA580C")      // Orange
    static let danger = Color(hex: "DC2626")       // Red
    static let info = Color(hex: "2563EB")         // Blue
    
    // MARK: - Achievement Category Colors
    static let executionColor = Color(hex: "8B5CF6")  // Violet
    static let researchColor = Color(hex: "10B981")   // Emerald
    static let recoveryColor = Color(hex: "EC4899")   // Pink
    static let supportColor = Color(hex: "06B6D4")    // Cyan
    
    // MARK: - Semantic Colors (Light/Dark Mode Adaptive)
    static let background = Color(light: Color(hex: "F6F8FC"), dark: Color(hex: "101418"))
    static let surface = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "171C22"))
    static let surfaceElevated = Color(light: Color(hex: "F0F5FB"), dark: Color(hex: "202832"))
    static let textPrimary = Color(light: Color(hex: "111827"), dark: Color(hex: "F8FAFC"))
    static let textSecondary = Color(light: Color(hex: "4B5B70"), dark: Color(hex: "B6C2D1"))
    static let textTertiary = Color(light: Color(hex: "8391A5"), dark: Color(hex: "718093"))
    static let textInverse = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "0F172A"))
    static let border = Color(light: Color(hex: "D8E1EE"), dark: Color(hex: "2A3441"))
    static let divider = Color(light: Color(hex: "E7EDF6"), dark: Color(hex: "26313D"))
    
    // MARK: - Gradient Presets
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [success, Color(hex: "34D399")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(hex: "FBBF24")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [surface, surfaceElevated],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var workspaceBackground: LinearGradient {
        LinearGradient(
            colors: [
                background,
                primary.opacity(0.055),
                success.opacity(0.045)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Spacing (8pt Grid System)
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing6: CGFloat = 6
    static let spacing8: CGFloat = 8
    static let spacing10: CGFloat = 10
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48
    
    // Legacy spacing aliases
    static let spacingXs = spacing4
    static let spacingSm = spacing8
    static let spacingMd = spacing16
    static let spacingLg = spacing24
    static let spacingXl = spacing32
    
    // MARK: - Corner Radius
    static let radiusSm: CGFloat = 6
    static let radiusMd: CGFloat = 10
    static let radiusLg: CGFloat = 16
    static let radiusXl: CGFloat = 24
    static let radiusPill: CGFloat = 9999
    
    // MARK: - Shadows
    static let shadowSm = Color.black.opacity(0.035)
    static let shadowMd = Color.black.opacity(0.055)
    static let shadowLg = Color.black.opacity(0.085)
    static let shadowXl = Color.black.opacity(0.12)
    static let cardShadow = Color.black.opacity(0.065)
    
    // MARK: - Typography
    static let fontDisplay: Font = .system(size: 32, weight: .bold, design: .rounded)
    static let fontTitle1: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let fontTitle2: Font = .system(size: 22, weight: .bold, design: .rounded)
    static let fontTitle3: Font = .system(size: 18, weight: .semibold, design: .rounded)
    static let fontHeadline: Font = .system(size: 16, weight: .semibold)
    static let fontBody: Font = .system(size: 15, weight: .regular)
    static let fontBodyMedium: Font = .system(size: 15, weight: .medium)
    static let fontCallout: Font = .system(size: 14, weight: .regular)
    static let fontCalloutMedium: Font = .system(size: 14, weight: .medium)
    static let fontCaption: Font = .system(size: 12, weight: .regular)
    static let fontCaptionMedium: Font = .system(size: 12, weight: .medium)
    static let fontFootnote: Font = .system(size: 11, weight: .regular)
    
    // Legacy font aliases
    static let titleFont = fontTitle2
    static let subtitleFont = fontTitle3
    static let bodyFont = fontBody
    static let captionFont = fontCaption
    static let statNumberFont = fontTitle1
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    var isElevated: Bool = true
    var padding: CGFloat = AppTheme.spacing16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), AppTheme.surfaceElevated.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                            .stroke(AppTheme.border, lineWidth: 0.5)
                    )
            )
            .shadow(
                color: isElevated ? AppTheme.shadowMd : Color.clear,
                radius: isElevated ? 8 : 0,
                x: 0,
                y: isElevated ? 2 : 0
            )
    }
}

struct PrimaryButtonStyle: ViewModifier {
    var isFullWidth: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.fontCalloutMedium)
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(AppTheme.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.radiusMd)
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.fontCalloutMedium)
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .background(AppTheme.surfaceElevated)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(AppTheme.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct GhostButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.fontCalloutMedium)
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing8)
            .foregroundColor(AppTheme.primary)
            .cornerRadius(AppTheme.radiusMd)
    }
}

struct WorkspaceTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTheme.fontCallout)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing8)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border.opacity(0.70), lineWidth: 0.75)
            )
            .shadow(color: AppTheme.shadowSm, radius: 1.5, x: 0, y: 1)
    }
}

struct WorkspaceControlSurface: ViewModifier {
    var minHeight: CGFloat = 34

    func body(content: Content) -> some View {
        content
            .font(AppTheme.fontCallout)
            .foregroundStyle(AppTheme.textPrimary)
            .controlSize(.regular)
            .padding(.horizontal, AppTheme.spacing8)
            .padding(.vertical, AppTheme.spacing4)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border.opacity(0.70), lineWidth: 0.75)
            )
            .shadow(color: AppTheme.shadowSm, radius: 1.5, x: 0, y: 1)
    }
}

struct WorkspaceSegmentedSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .controlSize(.regular)
            .padding(AppTheme.spacing2)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border.opacity(0.75), lineWidth: 0.75)
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(isElevated: Bool = true, padding: CGFloat = AppTheme.spacing16) -> some View {
        modifier(CardStyle(isElevated: isElevated, padding: padding))
    }
    
    func primaryButton(isFullWidth: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isFullWidth: isFullWidth))
    }
    
    func secondaryButton() -> some View {
        modifier(SecondaryButtonStyle())
    }
    
    func ghostButton() -> some View {
        modifier(GhostButtonStyle())
    }

    func workspaceControl(minHeight: CGFloat = 38) -> some View {
        modifier(WorkspaceControlSurface(minHeight: minHeight))
    }

    func workspaceSegmented() -> some View {
        modifier(WorkspaceSegmentedSurface())
    }
}
