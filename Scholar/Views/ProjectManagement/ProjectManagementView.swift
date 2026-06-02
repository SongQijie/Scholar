import SwiftUI

struct ProjectManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ProjectManagementViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLg) {
                overviewSection
                    .fadeIn()

                ProjectsSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.1)

                TasksSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.16)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            viewModel.loadData()
        }
    }

    private var overviewSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingLg) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("项目管理", "Project Management"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理科研、教学、基金、学生指导与公共服务任务", "Manage research, teaching, grants, mentoring, and service tasks"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: 330, alignment: .leading)

            CompactDashboardPanel(metrics: projectMetrics, quadrants: projectQuadrants)
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

    private var projectMetrics: [CompactDashboardMetric] {
        [
            .init(title: language.text("工作线索", "Workstreams"), value: "\(viewModel.stats.totalProjects)", color: AppTheme.primary),
            .init(title: language.text("活跃项目", "Active"), value: "\(viewModel.stats.activeProjects)", color: AppTheme.secondary),
            .init(title: language.text("任务总量", "Tasks"), value: "\(viewModel.stats.totalTasks)", color: AppTheme.accent),
            .init(title: language.text("待推进", "Open"), value: "\(viewModel.stats.incompleteTasks)", color: AppTheme.warning),
            .init(title: language.text("7天内", "7 Days"), value: "\(viewModel.stats.dueWithin7Days)", color: AppTheme.danger),
            .init(title: language.text("未归档", "Unfiled"), value: "\(viewModel.stats.unassignedTasks)", color: AppTheme.textSecondary)
        ]
    }

    private var projectQuadrants: [CompactDashboardQuadrant] {
        [
            .init(title: language.text("紧急\n且重要", "Urgent\nImportant"), value: "\(viewModel.stats.todayMustDo)", icon: "exclamationmark.triangle.fill", color: AppTheme.danger),
            .init(title: language.text("重要\n不紧急", "Important\nNot Urgent"), value: "\(viewModel.stats.todayShouldDo)", icon: "arrow.up.circle.fill", color: AppTheme.warning),
            .init(title: language.text("紧急\n不重要", "Urgent\nNot Important"), value: "\(viewModel.stats.q3Tasks)", icon: "bolt.fill", color: AppTheme.secondary),
            .init(title: language.text("不紧急\n不重要", "Not Urgent\nNot Important"), value: "\(viewModel.stats.q4Tasks)", icon: "minus.circle.fill", color: AppTheme.textSecondary)
        ]
    }
}

struct EisenhowerItem: View {
    let label: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingXs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Text("\(count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingSm)
    }
}
