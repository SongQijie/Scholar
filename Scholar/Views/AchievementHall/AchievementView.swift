import SwiftUI

struct AchievementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = AchievementViewModel()
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                statsSection
                    .fadeIn(delay: 0.1)

                categoryFilter
                    .fadeIn(delay: 0.15)

                achievementGrid
                    .fadeIn(delay: 0.2)
            }
            .padding(AppTheme.spacingLg)
        }
        .background(AppTheme.background)
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("成就殿堂", "Achievements"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("追踪研究旅程中的里程碑", "Track milestones in your research journey"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            SecondaryButton(
                title: language.text("刷新进度", "Refresh"),
                icon: "arrow.clockwise",
                action: {
                    viewModel.refreshAchievements()
                }
            )
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        ModernCard {
            HStack(spacing: AppTheme.spacingMd) {
                StatCard(
                    title: language.text("已解锁成就", "Unlocked"),
                    value: "\(viewModel.stats.totalUnlocked)",
                    icon: "checkmark.seal.fill",
                    color: AppTheme.success
                )
                .hoverScale(1.02)

                StatCard(
                    title: language.text("总进度", "Overall Progress"),
                    value: String(format: "%.0f%%", viewModel.stats.overallProgress * 100),
                    icon: "chart.pie.fill",
                    color: AppTheme.primary
                )
                .hoverScale(1.02)

                StatCard(
                    title: language.text("总成就数", "Total Achievements"),
                    value: "\(viewModel.stats.totalAchievements)",
                    icon: "trophy.fill",
                    color: AppTheme.secondary
                )
                .hoverScale(1.02)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ModernCard(padding: AppTheme.spacingMd) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacingSm) {
                    categoryButton(title: language.text("全部", "All"), isSelected: viewModel.selectedCategory == nil) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedCategory = nil
                        }
                    }
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        categoryButton(
                            title: category.displayName,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }

    private func categoryButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, AppTheme.spacingMd)
                .padding(.vertical, AppTheme.spacingXs + 2)
                .background {
                    if isSelected {
                        Capsule().fill(AppTheme.primaryGradient)
                    } else {
                        Capsule().fill(Color.clear)
                    }
                }
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .pressScale(0.95)
    }

    // MARK: - Achievement Grid

    private var achievementGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacingSm), count: 4), spacing: AppTheme.spacingSm) {
            ForEach(viewModel.filteredAchievements) { achievement in
                AchievementCardView(achievement: achievement)
            }
        }
    }
}

// MARK: - Achievement Card View

private struct AchievementCardView: View {
    let achievement: Achievement

    var body: some View {
        ModernCard(padding: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                // Icon + Name
                HStack(spacing: AppTheme.spacingXs) {
                    Image(systemName: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(achievement.isUnlocked ? AppTheme.success : AppTheme.textTertiary)

                    Text(achievement.displayName)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(achievement.isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary)
                        .lineLimit(1)
                }

                // Progress
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                            .fill(AppTheme.background)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                            .fill(achievement.isUnlocked ? AppTheme.success : AppTheme.primary.opacity(0.5))
                            .frame(width: geo.size.width * CGFloat(achievement.progress), height: 6)
                            .animation(.easeInOut(duration: 0.5), value: achievement.progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(achievement.currentValue)/\(achievement.targetValue)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    // Tier tag
                    Badge(
                        text: achievement.tier.displayName,
                        style: achievement.isUnlocked ? .success : .secondary
                    )
                }

                // Category tag
                Text(achievement.category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                    .lineLimit(1)

                // Unlocked date
                if achievement.isUnlocked, let date = achievement.unlockedAt {
                    HStack(spacing: AppTheme.spacingXs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(date, style: .date)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .hoverScale(1.01)
    }
}
