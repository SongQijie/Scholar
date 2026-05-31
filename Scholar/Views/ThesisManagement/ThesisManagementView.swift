import SwiftUI

struct ThesisManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ThesisManagementViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLg) {
                overviewSection
                    .fadeIn()

                ThesesSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.1)

                ThesisTasksSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.16)
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
    }

    private var overviewSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingLg) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("课题管理", "Topic Management"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理研究课题与相关任务", "Manage research topics and related tasks"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: 330, alignment: .leading)

            CompactDashboardPanel(metrics: thesisMetrics, quadrants: thesisQuadrants)
                .frame(maxWidth: .infinity, minHeight: 118, alignment: .center)
        }
        .padding(AppTheme.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                        .stroke(AppTheme.primary.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var thesisMetrics: [CompactDashboardMetric] {
        [
            .init(title: language.text("课题总数", "Topics"), value: "\(viewModel.boardStats.totalTheses)", color: AppTheme.primary),
            .init(title: language.text("进行中", "Active"), value: "\(viewModel.boardStats.activeTheses)", color: AppTheme.secondary),
            .init(title: language.text("已完成", "Done"), value: "\(viewModel.boardStats.completedTheses)", color: AppTheme.success),
            .init(title: language.text("关联任务", "Tasks"), value: "\(viewModel.boardStats.totalTasks)", color: AppTheme.accent),
            .init(title: language.text("任务完成", "Done"), value: "\(viewModel.boardStats.completedTasks)", color: AppTheme.success),
            .init(title: language.text("7天内", "7 Days"), value: "\(viewModel.boardStats.dueWithin7Days)", color: AppTheme.danger)
        ]
    }

    private var thesisQuadrants: [CompactDashboardQuadrant] {
        [
            .init(title: language.text("紧急\n且重要", "Urgent\nImportant"), value: "\(viewModel.boardStats.todayMustDo)", icon: "exclamationmark.triangle.fill", color: AppTheme.danger),
            .init(title: language.text("重要\n不紧急", "Important\nNot Urgent"), value: "\(viewModel.boardStats.todayShouldDo)", icon: "arrow.up.circle.fill", color: AppTheme.warning),
            .init(title: language.text("紧急\n不重要", "Urgent\nNot Important"), value: "\(viewModel.boardStats.q3Tasks)", icon: "bolt.fill", color: AppTheme.secondary),
            .init(title: language.text("不紧急\n不重要", "Not Urgent\nNot Important"), value: "\(viewModel.boardStats.q4Tasks)", icon: "minus.circle.fill", color: AppTheme.textSecondary)
        ]
    }
}
