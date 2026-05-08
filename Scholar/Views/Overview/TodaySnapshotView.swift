import SwiftUI

struct TodaySnapshotView: View {
    @EnvironmentObject private var store: AppDataStore
    let snapshot: AppDataStore.TodaySnapshot
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack {
                Text(language.text("今日工作面", "Today's Snapshot"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingSm), count: 4)
            LazyVGrid(columns: columns, spacing: AppTheme.spacingSm) {
                SnapshotItemView(title: language.text("今日待推进", "Open Today"), value: "\(snapshot.todayOpenTasks)", systemImage: "list.bullet.clipboard")
                SnapshotItemView(title: language.text("今天截止", "Due Today"), value: "\(snapshot.dueTodayTasks)", systemImage: "calendar.badge.exclamationmark")
                SnapshotItemView(title: language.text("进行中任务", "In Progress"), value: "\(snapshot.inProgressTasks)", systemImage: "checklist")
                SnapshotItemView(title: language.text("成果推进", "Submission Flow"), value: "\(snapshot.activeSubmissions)", systemImage: "paperplane")
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}

struct SnapshotItemView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingSm)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}
