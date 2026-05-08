import SwiftUI

struct ThesisManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ThesisManagementViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                statsSection
                    .fadeIn(delay: 0.1)

                ThesesSectionView(viewModel: viewModel)
                    .fadeIn(delay: 0.15)

                ThesisTasksSectionView(viewModel: viewModel)
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
                Text(language.text("课题管理", "Topic Management"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理研究课题与相关任务", "Manage research topics and related tasks"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var statsSection: some View {
        ModernCard {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingMd) {
                    StatCard(
                        title: language.text("课题总数", "Total Theses"),
                        value: "\(viewModel.stats.totalTheses)",
                        icon: "doc.text.fill",
                        color: AppTheme.primary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("进行中", "Active"),
                        value: "\(viewModel.stats.activeTheses)",
                        icon: "bolt.fill",
                        color: AppTheme.secondary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("已完成", "Completed"),
                        value: "\(viewModel.stats.completedTheses)",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("关联任务", "Linked Tasks"),
                        value: "\(viewModel.stats.totalTasks)",
                        icon: "link",
                        color: AppTheme.accent
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("任务完成", "Tasks Done"),
                        value: "\(viewModel.stats.completedTasks)",
                        icon: "checkmark.circle.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)
                }
                .padding(.vertical, AppTheme.spacingXs)
            }
        }
    }
}
