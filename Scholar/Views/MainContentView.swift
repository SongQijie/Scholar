import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case overview
    case projectManagement
    case thesisManagement
    case submission
    case health
    case mentalCare
    case achievement
    case dataDashboard
    case dataManagement

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .projectManagement: return "folder"
        case .thesisManagement: return "doc.text"
        case .submission: return "paperplane"
        case .health: return "heart"
        case .mentalCare: return "brain.head.profile"
        case .achievement: return "flag"
        case .dataDashboard: return "chart.line.uptrend.xyaxis"
        case .dataManagement: return "gearshape"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .overview: return language.text("教师工作台", "Faculty Desk")
        case .projectManagement: return language.text("项目管理", "Projects")
        case .thesisManagement: return language.text("课题管理", "Topics")
        case .submission: return language.text("成果管理", "Submissions")
        case .health: return language.text("生活与健康", "Health")
        case .mentalCare: return language.text("天气与心情", "Mood & Weather")
        case .achievement: return language.text("阶段里程碑", "Milestones")
        case .dataDashboard: return language.text("研究洞察", "Insights")
        case .dataManagement: return language.text("数据与设置", "Data & Settings")
        }
    }

    func groupTitle(for language: AppLanguage) -> String {
        switch self {
        case .overview, .projectManagement, .thesisManagement, .submission:
            return language.text("教学科研推进", "Faculty Work")
        case .health, .mentalCare:
            return language.text("状态维护", "Wellbeing")
        case .achievement, .dataDashboard, .dataManagement:
            return language.text("沉淀与回顾", "Review & Archive")
        }
    }
}

struct MainContentView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedItem: NavigationItem = .overview
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    private let sidebarWidth: CGFloat = 288
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .frame(minWidth: sidebarWidth, idealWidth: sidebarWidth, maxWidth: sidebarWidth)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(AppTheme.workspaceBackground)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationSplitViewColumnWidth(
            min: sidebarWidth,
            ideal: sidebarWidth,
            max: sidebarWidth
        )
        .background(AppTheme.workspaceBackground)
    }

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            brandHeader

            Divider()
                .background(AppTheme.divider)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                    ForEach(Array(groupedItems.enumerated()), id: \.element.title) { index, group in
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text(group.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .padding(.horizontal, AppTheme.spacingMd)
                                .padding(.top, index == 0 ? 0 : AppTheme.spacingXs)

                            VStack(spacing: AppTheme.spacingXs) {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, item in
                                    sidebarItem(for: item)
                                        .fadeIn(delay: Double(index) * 0.05 + Double(itemIndex) * 0.03)
                                }
                            }
                            .padding(.horizontal, AppTheme.spacingSm)
                        }
                    }
                }
                .padding(.vertical, AppTheme.spacingMd)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    AppTheme.surface,
                    AppTheme.surfaceElevated.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var brandHeader: some View {
        VStack(spacing: AppTheme.spacingXs) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                            .fill(AppTheme.primaryGradient)
                            .shadow(color: AppTheme.primary.opacity(0.25), radius: 10, x: 0, y: 5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.appDisplayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(language.text("教师工作台", "Faculty Desk"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, AppTheme.spacingLg)
        .padding(.horizontal, AppTheme.spacingMd)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [AppTheme.primary.opacity(0.10), AppTheme.surface.opacity(0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func sidebarItem(for item: NavigationItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedItem = item
            }
        } label: {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: selectedItem == item ? .semibold : .regular))
                    .frame(width: 28)
                    .foregroundStyle(selectedItem == item ? AppTheme.primary : AppTheme.textSecondary)

                Text(item.title(for: language))
                    .font(.system(size: 13, weight: selectedItem == item ? .semibold : .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(selectedItem == item ? AppTheme.textPrimary : AppTheme.textSecondary)

                Spacer(minLength: 0)

                if selectedItem == item {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, AppTheme.spacingMd)
            .padding(.vertical, AppTheme.spacingSm + 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .fill(selectedItem == item ? AppTheme.primary.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .stroke(selectedItem == item ? AppTheme.primary.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverScale(1.01)
    }

    private var groupedItems: [(title: String, items: [NavigationItem])] {
        let orderedSections = NavigationItem.allCases.reduce(into: [String: [NavigationItem]]()) { result, item in
            result[item.groupTitle(for: language), default: []].append(item)
        }
        let titles = [
            language.text("教学科研推进", "Faculty Work"),
            language.text("状态维护", "Wellbeing"),
            language.text("沉淀与回顾", "Review & Archive")
        ]
        return titles.map { title in
            (title: title, items: orderedSections[title] ?? [])
        }
    }

    private var detailContent: some View {
        ZStack {
            AppTheme.workspaceBackground
                .ignoresSafeArea()

            Group {
                switch selectedItem {
                case .overview:
                    OverviewView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .projectManagement:
                    ProjectManagementView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .thesisManagement:
                    ThesisManagementView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .submission:
                    SubmissionView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .health:
                    HealthView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .mentalCare:
                    MentalCareView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .achievement:
                    AchievementView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .dataDashboard:
                    DataDashboardView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                case .dataManagement:
                    DataManagementView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedItem)
        }
    }
}
