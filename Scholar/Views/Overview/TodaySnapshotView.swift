import SwiftUI

struct TodaySnapshotView: View {
    @EnvironmentObject private var store: AppDataStore
    let snapshot: AppDataStore.TodaySnapshot
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("今日工作面", "Today's Snapshot"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Badge(text: language.text("今日", "Today"), style: .success)
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingSm), count: 4)
            LazyVGrid(columns: columns, spacing: AppTheme.spacingSm) {
                SnapshotItemView(title: language.text("关注任务", "Watched"), value: "\(snapshot.todayOpenTasks)", systemImage: "list.bullet.clipboard.fill", color: AppTheme.primary)
                SnapshotItemView(title: language.text("今天截止", "Due Today"), value: "\(snapshot.dueTodayTasks)", systemImage: "calendar.badge.exclamationmark", color: AppTheme.warning)
                SnapshotItemView(title: language.text("已经逾期", "Overdue"), value: "\(snapshot.inProgressTasks)", systemImage: "exclamationmark.triangle.fill", color: AppTheme.danger)
                SnapshotItemView(title: language.text("成果推进", "Submission Flow"), value: "\(snapshot.activeSubmissions)", systemImage: "paperplane.fill", color: AppTheme.success)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.55), lineWidth: 0.75)
        )
    }
}

struct SnapshotItemView: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(AppTheme.spacingSm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(color.opacity(0.14), lineWidth: 0.75)
        )
    }
}
