import SwiftUI

struct TodayScheduleView: View {
    @EnvironmentObject private var store: AppDataStore
    var viewModel: OverviewViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Text(language.text("今日节奏", "Today's Rhythm"))
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(language.text("按时间排序", "By Time"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
            }

            Text(language.text("根据今日任务的截止时间和已有安排生成。", "Generated from today's task due times and existing schedule."))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textTertiary)

            if viewModel.todayTimelineItems.isEmpty {
                Text(language.text("今天还没有可排序的任务。", "No timeline-ready tasks yet."))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, AppTheme.spacingMd)
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.todayTimelineItems.prefix(6)) { item in
                        HStack(spacing: AppTheme.spacingSm) {
                            Text(item.time?.formatted("HH:mm") ?? language.text("待定", "Anytime"))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: 48, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(AppTheme.bodyFont)
                                    .foregroundStyle(item.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                                    .lineLimit(1)
                                Text(item.subtitle)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding(AppTheme.spacingSm)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    }
                }
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }
}
