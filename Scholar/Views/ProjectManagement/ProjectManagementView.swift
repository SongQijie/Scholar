import SwiftUI

struct ProjectManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ProjectManagementViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                statsSection
                    .fadeIn(delay: 0.1)

                ProjectsSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.15)

                TasksSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.2)
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("项目管理", "Project Management"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理科研、教学、基金、学生指导与公共服务任务", "Manage research, teaching, grants, mentoring, and service tasks"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var statsSection: some View {
        ModernCard {
            VStack(spacing: AppTheme.spacingLg) {
                // 统计卡片行
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacingMd) {
                        StatCard(
                            title: language.text("工作线索", "Workstreams"),
                            value: "\(viewModel.stats.totalProjects)",
                            icon: "folder.fill",
                            color: AppTheme.primary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("活跃项目", "Active Projects"),
                            value: "\(viewModel.stats.activeProjects)",
                            icon: "bolt.fill",
                            color: AppTheme.secondary
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("任务总量", "Total Tasks"),
                            value: "\(viewModel.stats.totalTasks)",
                            icon: "checklist",
                            color: AppTheme.accent
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("待推进任务", "Open Tasks"),
                            value: "\(viewModel.stats.incompleteTasks)",
                            icon: "hourglass",
                            color: AppTheme.warning
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("7天内到期", "Due in 7 Days"),
                            value: "\(viewModel.stats.dueWithin7Days)",
                            icon: "clock.badge.exclamationmark",
                            color: AppTheme.danger
                        )
                        .hoverScale(1.02)

                        StatCard(
                            title: language.text("未归档任务", "Unassigned Tasks"),
                            value: "\(viewModel.stats.unassignedTasks)",
                            icon: "tray",
                            color: AppTheme.textSecondary
                        )
                        .hoverScale(1.02)
                    }
                    .padding(.vertical, AppTheme.spacingXs)
                }

                Divider()
                    .background(AppTheme.divider)

                // 艾森豪威尔矩阵
                HStack(spacing: AppTheme.spacingMd) {
                    EisenhowerItem(
                        label: language.text("Q1 今日关键", "Q1 Must Do"),
                        count: viewModel.stats.todayMustDo,
                        color: AppTheme.danger,
                        icon: "exclamationmark.triangle.fill"
                    )

                    EisenhowerItem(
                        label: language.text("Q2 今日推进", "Q2 Should Do"),
                        count: viewModel.stats.todayShouldDo,
                        color: AppTheme.warning,
                        icon: "arrow.up.circle.fill"
                    )

                    EisenhowerItem(
                        label: language.text("Q3 紧急不重要", "Q3 Urgent"),
                        count: viewModel.stats.q3Tasks,
                        color: AppTheme.secondary,
                        icon: "bolt.fill"
                    )

                    EisenhowerItem(
                        label: language.text("Q4 不紧急不重要", "Q4 Low Priority"),
                        count: viewModel.stats.q4Tasks,
                        color: AppTheme.textSecondary,
                        icon: "minus.circle.fill"
                    )
                }
                .padding(AppTheme.spacingMd)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            }
        }
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
