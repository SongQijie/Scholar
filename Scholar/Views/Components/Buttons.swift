import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isFullWidth: Bool = false
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(title)
                        .font(AppTheme.fontCalloutMedium)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(AppTheme.radiusMd)
            .shadow(color: AppTheme.primary.opacity(0.24), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .pressScale()
        .hoverScale(1.015)
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(AppTheme.fontCalloutMedium)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .fill(AppTheme.surfaceElevated.opacity(0.45))
                    )
            )
            .foregroundColor(AppTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadowSm, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .pressScale()
        .hoverScale(1.01)
    }
}

// MARK: - Ghost Button
struct GhostButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = AppTheme.primary
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(AppTheme.fontCalloutMedium)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing8)
            .foregroundColor(color)
            .background(color.opacity(0.1))
            .cornerRadius(AppTheme.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(color.opacity(0.18), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .pressScale()
        .hoverScale(1.02)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 36
    var backgroundColor: Color = AppTheme.surfaceElevated
    var iconColor: Color = AppTheme.textPrimary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: size, height: size)
                .background(backgroundColor)
                .foregroundColor(iconColor)
                .cornerRadius(AppTheme.radiusSm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                        .stroke(AppTheme.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .pressScale(0.92)
        .hoverScale(1.05)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = AppTheme.primary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(AppTheme.radiusLg)
                .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .pressScale(0.9)
        .hoverScale(1.05)
    }
}

// MARK: - Segmented Control
struct SegmentedControl<T: Hashable & CaseIterable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let items: [(value: T, label: String)]
    
    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            ForEach(items, id: \.value) { item in
                Button(action: { selection = item.value }) {
                    Text(item.label)
                        .font(AppTheme.fontCalloutMedium)
                        .padding(.horizontal, AppTheme.spacing12)
                        .padding(.vertical, AppTheme.spacing8)
                        .frame(maxWidth: .infinity)
                        .background(selection == item.value ? AppTheme.primary : Color.clear)
                        .foregroundColor(selection == item.value ? .white : AppTheme.textSecondary)
                        .cornerRadius(AppTheme.radiusSm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.spacing4)
        .background(AppTheme.background)
        .cornerRadius(AppTheme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Toggle Button
struct ToggleButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    var activeColor: Color = AppTheme.success
    
    var body: some View {
        SwiftUI.Button(action: { isOn.toggle() }) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AppTheme.fontCaptionMedium)
            }
            .padding(.horizontal, AppTheme.spacing10)
            .padding(.vertical, AppTheme.spacing6)
            .background(isOn ? activeColor.opacity(0.15) : AppTheme.surfaceElevated)
            .foregroundColor(isOn ? activeColor : AppTheme.textSecondary)
            .cornerRadius(AppTheme.radiusPill)
            .overlay(
                Capsule()
                    .stroke(isOn ? activeColor.opacity(0.3) : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}
