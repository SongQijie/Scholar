import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minWidth: 96, idealWidth: 112, maxWidth: 128, minHeight: 88, maxHeight: 88, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .fill(AppTheme.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(color.opacity(0.75))
                        .frame(height: 3)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 3)
    }
}
