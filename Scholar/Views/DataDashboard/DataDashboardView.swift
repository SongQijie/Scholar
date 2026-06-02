import SwiftUI

struct DataDashboardView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = DataDashboardViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                kpiSection
                    .fadeIn(delay: 0.1)

                highlightsSection
                    .fadeIn(delay: 0.15)

                chartsSection
                    .fadeIn(delay: 0.2)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: viewModel.timeRange) {
            viewModel.loadData()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("研究洞察", "Insights"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("数据分析与趋势洞察", "Data analysis and trend insights"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Picker("", selection: $viewModel.timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .workspaceSegmented()
            .frame(width: 200)
        }
    }

    private var kpiSection: some View {
        ModernCard {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingMd) {
                    StatCard(
                        title: language.text("活跃项目", "Active Projects"),
                        value: "\(viewModel.kpiData.activeProjects)",
                        icon: "folder.fill",
                        color: AppTheme.primary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("指导课题", "Active Topics"),
                        value: "\(viewModel.kpiData.activeTopics)",
                        icon: "doc.text.fill",
                        color: AppTheme.secondary
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("待推进任务", "Open Tasks"),
                        value: "\(viewModel.kpiData.openTasks)",
                        icon: "checklist",
                        color: AppTheme.warning
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("7天内到期", "Due in 7 Days"),
                        value: "\(viewModel.kpiData.dueSoonTasks)",
                        icon: "clock.badge.exclamationmark",
                        color: AppTheme.danger
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("完成任务", "Completed Tasks"),
                        value: "\(viewModel.kpiData.completedTasks)",
                        icon: "checkmark.circle.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("成果动作", "Outcome Actions"),
                        value: "\(viewModel.kpiData.submissionActions)",
                        icon: "paperplane.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("习惯均值", "Habit Rate"),
                        value: "\(Int(viewModel.kpiData.habitCompletionRate * 100))%",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.success
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("天气与心情", "Mood & Weather"),
                        value: "\(viewModel.kpiData.mentalCareCount)",
                        icon: "heart.fill",
                        color: AppTheme.accent
                    )
                    .hoverScale(1.02)

                    StatCard(
                        title: language.text("进行中提交", "Active Submissions"),
                        value: "\(viewModel.kpiData.activeSubmissions)",
                        icon: "hourglass",
                        color: AppTheme.primary
                    )
                    .hoverScale(1.02)
                }
                .padding(.vertical, AppTheme.spacingXs)
            }
        }
    }

    private var highlightsSection: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingLg) {
            ModernCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                    HStack {
                        Text(language.text("这一阶段的变化", "Changes in This Period"))
                            .font(AppTheme.subtitleFont)
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.accent)
                    }

                    Divider()
                        .background(AppTheme.divider)

                    if viewModel.highlights.isEmpty {
                        EmptyStateCard(
                            icon: "chart.bar",
                            title: language.text("暂无数据", "No data yet"),
                            subtitle: language.text("开始使用应用后，这里会显示您的研究进展", "Your research progress will appear here after you start using the app")
                        )
                    } else {
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            ForEach(viewModel.highlights, id: \.self) { highlight in
                                HStack(spacing: AppTheme.spacingSm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.success)
                                        .font(.system(size: 14))

                                    Text(highlight)
                                        .font(AppTheme.bodyFont)
                                        .foregroundStyle(AppTheme.textSecondary)

                                    Spacer()
                                }
                                .padding(.vertical, AppTheme.spacingXs)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ModernCard {
                VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                    HStack {
                        Text(language.text("模块使用覆盖", "Module Coverage"))
                            .font(AppTheme.subtitleFont)
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Image(systemName: "chart.pie.fill")
                            .foregroundStyle(AppTheme.primary)
                    }

                    Divider()
                        .background(AppTheme.divider)

                    VStack(spacing: AppTheme.spacingMd) {
                        ForEach(viewModel.moduleCoverage, id: \.moduleName) { item in
                            HStack(spacing: AppTheme.spacingMd) {
                                Text(item.moduleName)
                                    .font(AppTheme.captionFont)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .frame(width: 100, alignment: .leading)

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                                            .fill(AppTheme.background)
                                            .frame(height: 8)

                                        if item.hasData {
                                            RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                                                .fill(AppTheme.primaryGradient)
                                                .frame(width: geo.size.width * CGFloat(item.coverageRate), height: 8)
                                                .animation(.easeInOut(duration: 0.5), value: item.coverageRate)
                                        } else {
                                            RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                                                .fill(AppTheme.textTertiary.opacity(0.3))
                                                .frame(width: geo.size.width * CGFloat(item.coverageRate), height: 8)
                                                .animation(.easeInOut(duration: 0.5), value: item.coverageRate)
                                        }
                                    }
                                }
                                .frame(height: 8)

                                Text("\(item.recordCount)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(item.hasData ? AppTheme.primary : AppTheme.textTertiary)
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chartsSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("趋势图表", "Trend Charts"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Badge(text: "Coming Soon", style: .secondary)
                }

                Divider()
                    .background(AppTheme.divider)

                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textTertiary.opacity(0.5))

                    Text(language.text("当前版本先把重点放在决策信息上，图表会在后续版本补成更完整的趋势视图。", "This version focuses on decision-ready signals first. Richer trend charts will be added in later versions."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacingXl)
            }
        }
    }
}
