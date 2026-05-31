import SwiftUI

// MARK: - Modern Card
struct ModernCard<Content: View>: View {
    let content: Content
    var isElevated: Bool = true
    var padding: CGFloat = AppTheme.spacing16
    var cornerRadius: CGFloat = AppTheme.radiusLg
    
    init(isElevated: Bool = true, padding: CGFloat = AppTheme.spacing16, cornerRadius: CGFloat = AppTheme.radiusLg, @ViewBuilder content: () -> Content) {
        self.isElevated = isElevated
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), AppTheme.surfaceElevated.opacity(0.14)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppTheme.border.opacity(0.75), lineWidth: 0.75)
                    )
            )
            .shadow(
                color: isElevated ? AppTheme.cardShadow : Color.clear,
                radius: isElevated ? 10 : 0,
                x: 0,
                y: isElevated ? 4 : 0
            )
    }
}

// MARK: - Gradient Card
struct GradientCard<Content: View>: View {
    let content: Content
    var gradient: LinearGradient
    var padding: CGFloat = AppTheme.spacing20
    var borderColor: Color = Color.clear
    
    init(
        gradient: LinearGradient = AppTheme.primaryGradient,
        padding: CGFloat = AppTheme.spacing20,
        borderColor: Color = Color.clear,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.padding = padding
        self.borderColor = borderColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 16,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = AppTheme.primary
    var showTrend: Bool = false
    var trendValue: String = ""
    var isPositive: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if showTrend {
                    Text(trendValue)
                        .font(AppTheme.fontCaptionMedium)
                        .foregroundColor(isPositive ? AppTheme.success : AppTheme.danger)
                        .padding(.horizontal, AppTheme.spacing6)
                        .padding(.vertical, 2)
                        .background((isPositive ? AppTheme.success : AppTheme.danger).opacity(0.1))
                        .cornerRadius(AppTheme.radiusPill)
                }
            }

            Text(title)
                .font(AppTheme.fontCaption)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Rectangle()
                .fill(color.opacity(0.75))
                .frame(height: 3)
                .clipShape(Capsule())
        }
        .padding(AppTheme.spacing12)
        .frame(minWidth: 118, maxWidth: 150, minHeight: 86, alignment: .topLeading)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
        .shadow(color: AppTheme.cardShadow, radius: 6, x: 0, y: 2)
    }
}

struct CompactDashboardMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let color: Color
}

struct CompactDashboardQuadrant: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct CompactDashboardPanel: View {
    let metrics: [CompactDashboardMetric]
    let quadrants: [CompactDashboardQuadrant]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(spacing: AppTheme.spacingSm) {
                ForEach(metrics) { item in
                    CompactMetricChip(item: item)
                }
            }
            .frame(maxWidth: .infinity)

            if !quadrants.isEmpty {
                HStack(spacing: AppTheme.spacingSm) {
                    ForEach(quadrants) { item in
                        CompactQuadrantChip(item: item)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, AppTheme.spacingSm)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .center)
        .background(AppTheme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border.opacity(0.45), lineWidth: 0.75)
        )
    }
}

private struct CompactMetricChip: View {
    let item: CompactDashboardMetric

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(item.value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(item.color)
            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.spacingSm)
        .padding(.vertical, AppTheme.spacingXs)
        .frame(minWidth: 86, maxWidth: .infinity, minHeight: 50, alignment: .center)
        .background(item.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(item.color.opacity(0.18), lineWidth: 0.75)
        )
    }
}

private struct CompactQuadrantChip: View {
    let item: CompactDashboardQuadrant

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(item.color)
            Text(item.value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(item.color)
            Text(item.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(item.color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(item.color.opacity(0.14), lineWidth: 0.75)
        )
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let subtitle: String
    let icon: String
    var color: Color = AppTheme.info
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .cornerRadius(AppTheme.radiusMd)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.fontCalloutMedium)
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(AppTheme.fontCaption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.spacing12)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let progress: Double
    var color: Color = AppTheme.primary
    var showPercentage: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text(title)
                    .font(AppTheme.fontCalloutMedium)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(AppTheme.fontCaptionMedium)
                        .foregroundColor(color)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                        .fill(AppTheme.background)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: AppTheme.radiusPill)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * progress), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(AppTheme.spacing16)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border, lineWidth: 0.5)
        )
    }
}

// MARK: - List Item Card
struct ListItemCard<Content: View>: View {
    let content: Content
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    
    init(isSelected: Bool = false, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            content
                .padding(AppTheme.spacing12)
                .background(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.surface)
                .cornerRadius(AppTheme.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                        .stroke(isSelected ? AppTheme.primary.opacity(0.3) : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .pressScale()
        .hoverScale(1.005)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)?
    var actionTitle: String?
    
    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 80, height: 80)
                .background(AppTheme.background)
                .cornerRadius(AppTheme.radiusLg)
            
            VStack(spacing: AppTheme.spacing4) {
                Text(title)
                    .font(AppTheme.fontHeadline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(AppTheme.fontCallout)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                PrimaryButton(title: actionTitle, icon: "plus", action: action)
            }
        }
        .padding(AppTheme.spacing32)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.radiusLg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
        )
    }
}

// MARK: - Badge
struct Badge: View {
    let text: String
    var color: Color = AppTheme.primary
    var size: BadgeSize = .medium
    var style: BadgeStyle = .custom(AppTheme.primary)

    init(text: String, color: Color = AppTheme.primary, size: BadgeSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
        self.style = .custom(color)
    }

    init(text: String, style: BadgeStyle, size: BadgeSize = .medium) {
        self.text = text
        self.style = style
        self.size = size
        self.color = style.color
    }

    enum BadgeStyle {
        case primary
        case success
        case secondary
        case warning
        case danger
        case custom(Color)

        var color: Color {
            switch self {
            case .primary: return AppTheme.primary
            case .success: return AppTheme.success
            case .secondary: return AppTheme.textSecondary
            case .warning: return AppTheme.warning
            case .danger: return AppTheme.danger
            case .custom(let color): return color
            }
        }
    }
    
    enum BadgeSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return AppTheme.fontCaption
            case .medium: return AppTheme.fontCaptionMedium
            case .large: return AppTheme.fontCalloutMedium
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(color)
            .padding(size.padding)
            .background(color.opacity(0.12))
            .cornerRadius(AppTheme.radiusPill)
    }
}

struct SidebarCountBadge: View {
    let numerator: Int
    let denominator: Int
    var showsDenominator: Bool = true
    let isSelected: Bool

    var body: some View {
        Text(showsDenominator ? "\(numerator)/\(denominator)" : "\(numerator)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(width: showsDenominator ? 42 : 22, alignment: .trailing)
    }
}

// MARK: - Avatar
struct Avatar: View {
    let name: String
    var size: CGFloat = 40
    var backgroundColor: Color?
    
    private var initials: String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.count > 1 ? components.last?.prefix(1) : ""
        return String(first + (last ?? "")).uppercased()
    }
    
    private var color: Color {
        backgroundColor ?? Color(hue: Double(name.hashValue % 360) / 360, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(color)
            .cornerRadius(size / 2)
    }
}
