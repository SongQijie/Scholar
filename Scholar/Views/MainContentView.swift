import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case overview
    case projectManagement
    case thesisManagement
    case affairManagement
    case todoManagement
    case archiveManagement
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
        case .affairManagement: return "tray.full"
        case .todoManagement: return "checklist"
        case .archiveManagement: return "archivebox"
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
        case .overview: return language.text("科研工作台", "Research Desk")
        case .projectManagement: return language.text("项目管理", "Projects")
        case .thesisManagement: return language.text("课题管理", "Topics")
        case .affairManagement: return language.text("事务管理", "Affairs")
        case .todoManagement: return language.text("待办管理", "Todos")
        case .archiveManagement: return language.text("归档管理", "Archive")
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
        case .overview, .projectManagement, .thesisManagement, .affairManagement, .todoManagement:
            return language.text("教学科研推进", "Faculty Work")
        case .health, .mentalCare:
            return language.text("状态维护", "Wellbeing")
        case .archiveManagement, .submission, .achievement, .dataDashboard, .dataManagement:
            return language.text("沉淀与回顾", "Review & Archive")
        }
    }
}

struct MainContentView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedItem: NavigationItem = .overview
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    private let sidebarWidth: CGFloat = 232
    private let sidebarContentPadding: CGFloat = AppTheme.spacingSm
    private var language: AppLanguage { store.appLanguage }
    private var sidebarContentWidth: CGFloat {
        sidebarWidth - sidebarContentPadding * 2
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
                .frame(width: sidebarWidth, alignment: .leading)
                .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth, max: sidebarWidth)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(AppTheme.workspaceBackground)
        }
        .navigationSplitViewStyle(.prominentDetail)
        .background(AppTheme.workspaceBackground)
    }

    private var sidebarContent: some View {
        VStack(spacing: 0) {
            brandHeader

            Divider()
                .background(AppTheme.divider)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                    ForEach(Array(groupedItems.enumerated()), id: \.element.title) { index, group in
                        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                            Text(group.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.textTertiary)
                                .textCase(.uppercase)
                                .padding(.horizontal, AppTheme.spacingSm)
                                .padding(.top, index == 0 ? 0 : AppTheme.spacingXs)

                            VStack(spacing: AppTheme.spacingXs) {
                                ForEach(Array(group.items.enumerated()), id: \.element.id) { itemIndex, item in
                                    sidebarItem(for: item)
                                        .fadeIn(delay: Double(index) * 0.05 + Double(itemIndex) * 0.03)
                                }
                            }
                            .frame(width: sidebarContentWidth, alignment: .leading)
                        }
                        .frame(width: sidebarContentWidth, alignment: .leading)
                    }
                }
                .padding(.vertical, AppTheme.spacingSm)
                .frame(width: sidebarContentWidth, alignment: .leading)
                .padding(.horizontal, sidebarContentPadding)
            }
        }
        .frame(width: sidebarWidth, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.surface,
                    AppTheme.surfaceElevated.opacity(0.46),
                    AppTheme.success.opacity(0.035)
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
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                            .fill(AppTheme.primaryGradient)
                            .shadow(color: AppTheme.primary.opacity(0.18), radius: 6, x: 0, y: 3)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.appDisplayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(language.text("科研工作台", "Research Desk"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, AppTheme.spacingMd)
        .padding(.horizontal, AppTheme.spacingSm)
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
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.radiusSm)
                        .fill(selectedItem == item ? AppTheme.primary.opacity(0.14) : AppTheme.surfaceElevated.opacity(0.55))
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: selectedItem == item ? .semibold : .regular))
                        .foregroundStyle(selectedItem == item ? AppTheme.primary : AppTheme.textSecondary)
                }
                .frame(width: 26, height: 26)

                Text(item.title(for: language))
                    .font(.system(size: 15, weight: selectedItem == item ? .bold : .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(selectedItem == item ? AppTheme.textPrimary : AppTheme.textSecondary)

                Spacer(minLength: 0)

                if let count = sidebarCount(for: item) {
                    SidebarCountBadge(
                        numerator: count.numerator,
                        denominator: count.denominator,
                        showsDenominator: count.showsDenominator,
                        isSelected: selectedItem == item
                    )
                }

                Rectangle()
                    .fill(selectedItem == item ? AppTheme.primary : Color.clear)
                    .frame(width: 3, height: 20)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, AppTheme.spacingXs + 3)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .fill(selectedItem == item ? AppTheme.primary.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(selectedItem == item ? AppTheme.primary.opacity(0.24) : Color.clear, lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .frame(width: sidebarContentWidth, alignment: .leading)
    }

    private func sidebarCount(for item: NavigationItem) -> (numerator: Int, denominator: Int, showsDenominator: Bool)? {
        switch item {
        case .projectManagement:
            let stats = store.computeProjectBoardStats()
            return (stats.incompleteTasks, stats.totalProjects, true)
        case .thesisManagement:
            let stats = store.computeThesisBoardStats()
            return (stats.incompleteTasks, stats.totalTheses, true)
        case .affairManagement:
            let stats = store.computeAffairBoardStats()
            return (stats.incompleteTasks, stats.totalAffairs, true)
        case .todoManagement:
            let stats = store.computeTodoBoardStats()
            return (stats.incompleteTasks, stats.totalTasks, false)
        default:
            return nil
        }
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
                case .projectManagement:
                    ProjectManagementView()
                case .thesisManagement:
                    ThesisManagementView()
                case .affairManagement:
                    AffairManagementView()
                case .todoManagement:
                    TodoManagementView()
                case .archiveManagement:
                    ArchiveManagementView()
                case .submission:
                    SubmissionView()
                case .health:
                    HealthView()
                case .mentalCare:
                    MentalCareView()
                case .achievement:
                    AchievementView()
                case .dataDashboard:
                    DataDashboardView()
                case .dataManagement:
                    DataManagementView()
                }
            }
        }
    }
}

struct ArchiveManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedArchiveItem: ArchiveDetailSelection?
    private var language: AppLanguage { store.appLanguage }

    private var archivedProjects: [Project] {
        store.archivedData.projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    private var archivedTheses: [ThesisInfo] {
        store.archivedData.thesisInfos.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private var archivedAffairs: [Affair] {
        store.archivedData.affairs.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                header
                archiveSection(
                    title: language.text("归档项目", "Archived Projects"),
                    emptyText: language.text("还没有归档项目。", "No archived projects yet."),
                    icon: "folder",
                    color: AppTheme.primary,
                    items: archivedProjects.map { item in
                        ArchiveRowItem(
                            id: item.id,
                            title: item.name,
                            subtitle: item.summary.isEmpty ? item.category.displayName : item.summary,
                            meta: item.deadline.map { language.text("截止 \($0.formatted("yyyy-MM-dd"))", "Due \($0.formatted("yyyy-MM-dd"))") } ?? language.text("未设截止", "No due date"),
                            icon: "folder",
                            detailSelection: .project(item.id)
                        )
                    },
                    onRestore: restoreProject
                )
                archiveSection(
                    title: language.text("归档课题", "Archived Topics"),
                    emptyText: language.text("还没有归档课题。", "No archived topics yet."),
                    icon: "doc.text",
                    color: AppTheme.secondary,
                    items: archivedTheses.map { item in
                        ArchiveRowItem(
                            id: item.id,
                            title: item.title,
                            subtitle: item.notes.isEmpty ? item.stage.displayName : item.notes,
                            meta: item.dueDate.map { "DDL \($0.formatted("yyyy-MM-dd"))" } ?? language.text("未设 DDL", "No DDL"),
                            icon: "doc.text",
                            detailSelection: .thesis(item.id)
                        )
                    },
                    onRestore: restoreThesis
                )
                archiveSection(
                    title: language.text("归档事务", "Archived Affairs"),
                    emptyText: language.text("还没有归档事务。", "No archived affairs yet."),
                    icon: "tray.full",
                    color: AppTheme.accent,
                    items: archivedAffairs.map { item in
                        ArchiveRowItem(
                            id: item.id,
                            title: item.title,
                            subtitle: item.details.isEmpty ? item.tagText : item.details,
                            meta: item.dueDate.map { language.text("截止 \($0.formatted("yyyy-MM-dd"))", "Due \($0.formatted("yyyy-MM-dd"))") } ?? language.text("未设截止", "No due date"),
                            icon: "tray.full",
                            detailSelection: .affair(item.id)
                        )
                    },
                    onRestore: restoreAffair
                )
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .sheet(item: $selectedArchiveItem) { selection in
            ArchiveDetailSheet(selection: selection)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: AppTheme.spacingLg) {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .shadow(color: AppTheme.primary.opacity(0.22), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("归档管理", "Archive Management"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("查看已完成的项目、课题和事务，也可以恢复到对应管理页。", "Review completed projects, topics, and affairs, or restore them."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: AppTheme.spacingSm) {
                archiveMetric(language.text("项目", "Projects"), archivedProjects.count, color: AppTheme.primary)
                archiveMetric(language.text("课题", "Topics"), archivedTheses.count, color: AppTheme.secondary)
                archiveMetric(language.text("事务", "Affairs"), archivedAffairs.count, color: AppTheme.accent)
            }
        }
        .padding(AppTheme.spacingLg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.09), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.primary.opacity(0.16), lineWidth: 0.75)
        )
        .shadow(color: AppTheme.cardShadow, radius: 6, x: 0, y: 2)
    }

    private func archiveMetric(_ title: String, _ value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(minWidth: 62)
        .padding(.horizontal, AppTheme.spacingSm)
        .padding(.vertical, AppTheme.spacingSm)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(color.opacity(0.16), lineWidth: 0.75)
        )
    }

    private func archiveSection(title: String, emptyText: String, icon: String, color: Color, items: [ArchiveRowItem], onRestore: @escaping (UUID) -> Void) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))

                Text(title)
                    .font(AppTheme.subtitleFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(items.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, AppTheme.spacingSm)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.10))
                    .clipShape(Capsule())
            }

            if items.isEmpty {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "archivebox")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(emptyText)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingMd)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(items) { item in
                        archiveRow(item, onRestore: onRestore)
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.75), lineWidth: 0.75)
        )
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func archiveRow(_ item: ArchiveRowItem, onRestore: @escaping (UUID) -> Void) -> some View {
        HStack(spacing: AppTheme.spacingMd) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 32, height: 32)
                .background(AppTheme.primary.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(item.meta)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.spacingSm)
                .padding(.vertical, AppTheme.spacingXs)
                .background(AppTheme.surfaceElevated)
                .clipShape(Capsule())

            Button {
                selectedArchiveItem = item.detailSelection
            } label: {
                Label(language.text("查看详情", "Details"), systemImage: "doc.text.magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
                .workspaceButton()
            .tint(AppTheme.primary)
            .controlSize(.small)

            Button {
                onRestore(item.id)
            } label: {
                Label(language.text("恢复", "Restore"), systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(.bordered)
                .workspaceButton()
            .controlSize(.small)
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border.opacity(0.60), lineWidth: 0.75)
        )
        .hoverScale(1.003)
    }

    private func restoreProject(_ id: UUID) {
        store.restoreProject(id)
    }

    private func restoreThesis(_ id: UUID) {
        store.restoreThesis(id)
    }

    private func restoreAffair(_ id: UUID) {
        store.restoreAffair(id)
    }

    private struct ArchiveRowItem: Identifiable {
        var id: UUID
        var title: String
        var subtitle: String
        var meta: String
        var icon: String
        var detailSelection: ArchiveDetailSelection
    }
}

private enum ArchiveDetailSelection: Identifiable {
    case project(UUID)
    case thesis(UUID)
    case affair(UUID)

    var id: String {
        switch self {
        case .project(let id): return "project-\(id.uuidString)"
        case .thesis(let id): return "thesis-\(id.uuidString)"
        case .affair(let id): return "affair-\(id.uuidString)"
        }
    }
}

private struct ArchiveDetailSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let selection: ArchiveDetailSelection
    private var language: AppLanguage { store.appLanguage }

    private var linkedTasks: [Task] {
        store.archivedData.tasks.filter { task in
            switch selection {
            case .project(let id): return task.projectId == id
            case .thesis(let id): return task.thesisId == id
            case .affair(let id): return task.affairId == id
            }
        }
        .sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
            }
            return lhs.status != .completed && rhs.status == .completed
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: headerIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))

                VStack(alignment: .leading, spacing: 3) {
                    Text(headerTitle)
                        .font(AppTheme.titleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("归档详情", "Archive Details"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: AppTheme.spacingSm) {
                        archiveBadge(selectionLabel, color: AppTheme.primary)
                        archiveBadge(language.text("\(linkedTasks.count) 个关联任务", "\(linkedTasks.count) linked tasks"), color: AppTheme.secondary)
                    }
                    .padding(.top, AppTheme.spacingXs)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Label(language.text("关闭", "Close"), systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
            }
            .padding(AppTheme.spacingLg)
            .background(AppTheme.surface)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                    detailSection
                    taskSection
                }
                .padding(AppTheme.spacingLg)
            }
            .background(AppTheme.background)
        }
        .frame(minWidth: 760, idealWidth: 860, minHeight: 600, idealHeight: 720)
    }

    private var headerIcon: String {
        switch selection {
        case .project: return "folder"
        case .thesis: return "doc.text"
        case .affair: return "tray.full"
        }
    }

    private var headerTitle: String {
        switch selection {
        case .project(let id): return store.archivedData.projects.first(where: { $0.id == id })?.name ?? language.text("项目", "Project")
        case .thesis(let id): return store.archivedData.thesisInfos.first(where: { $0.id == id })?.title ?? language.text("课题", "Topic")
        case .affair(let id): return store.archivedData.affairs.first(where: { $0.id == id })?.title ?? language.text("事务", "Affair")
        }
    }

    private var selectionLabel: String {
        switch selection {
        case .project: return language.text("归档项目", "Archived Project")
        case .thesis: return language.text("归档课题", "Archived Topic")
        case .affair: return language.text("归档事务", "Archived Affair")
        }
    }

    @ViewBuilder
    private var detailSection: some View {
        switch selection {
        case .project(let id):
            if let project = store.archivedData.projects.first(where: { $0.id == id }) {
                archiveCard(title: language.text("项目信息", "Project Information"), icon: "folder") {
                    detailGrid([
                        detail(language.text("类别", "Category"), project.category.displayName),
                        detail(language.text("阶段", "Stage"), project.stage.displayName),
                        detail(language.text("优先级", "Priority"), project.priority.displayName),
                        detail(language.text("负责人", "Owner"), project.owner),
                        detail(language.text("协作者", "Collaborators"), project.collaborators),
                        detail(language.text("起止时间", "Timeline"), dateRange(project.startDate, project.deadline)),
                        detail(language.text("经费来源", "Funding Source"), project.fundingSource),
                        detail(language.text("预算", "Budget"), project.budget.map { String(format: "%.2f", $0) } ?? ""),
                        detail(language.text("关键词", "Keywords"), project.keywordText),
                        detail(language.text("预期成果", "Expected Deliverables"), project.expectedDeliverables),
                        detail(language.text("项目简介", "Summary"), project.summary),
                        detail(language.text("项目成果", "Result"), project.result),
                        detail(language.text("备注", "Notes"), project.notes),
                        detail(language.text("共享文档", "Shared Document"), project.sharedDocumentLink)
                    ])
                }
            }
        case .thesis(let id):
            if let thesis = store.archivedData.thesisInfos.first(where: { $0.id == id }) {
                archiveCard(title: language.text("课题信息", "Topic Information"), icon: "doc.text") {
                    detailGrid([
                        detail(language.text("阶段", "Stage"), thesis.stage.displayName),
                        detail("DDL", thesis.dueDate?.formatted("yyyy-MM-dd HH:mm") ?? ""),
                        detail(language.text("当前版本", "Current Version"), thesis.currentVersion),
                        detail(language.text("整体进度", "Overall Progress"), "\(Int(thesis.overallProgress * 100))%"),
                        detail(language.text("关联学生", "Students"), thesis.students.map(\.name).joined(separator: " / ")),
                        detail(language.text("里程碑", "Milestones"), "\(thesis.milestones.filter(\.isCompleted).count) / \(thesis.milestones.count)"),
                        detail(language.text("章节", "Chapters"), "\(thesis.chapters.count)"),
                        detail(language.text("课题备注", "Notes"), thesis.notes),
                        detail(language.text("共享文档", "Shared Document"), thesis.sharedDocumentLink)
                    ])
                }
            }
        case .affair(let id):
            if let affair = store.archivedData.affairs.first(where: { $0.id == id }) {
                archiveCard(title: language.text("事务信息", "Affair Information"), icon: "tray.full") {
                    detailGrid([
                        detail(language.text("来源", "Source"), affair.source),
                        detail(language.text("截止时间", "Due Date"), affair.dueDate?.formatted("yyyy-MM-dd HH:mm") ?? ""),
                        detail(language.text("标签", "Tags"), affair.tagText),
                        detail(language.text("详情", "Details"), affair.details),
                        detail(language.text("创建时间", "Created"), affair.createdAt.formatted("yyyy-MM-dd HH:mm")),
                        detail(language.text("更新时间", "Updated"), affair.updatedAt.formatted("yyyy-MM-dd HH:mm"))
                    ])
                }
            }
        }
    }

    private var taskSection: some View {
        archiveCard(
            title: language.text("任务清单（\(linkedTasks.count)）", "Task List (\(linkedTasks.count))"),
            icon: "checklist"
        ) {
            if linkedTasks.isEmpty {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "checklist")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(language.text("该归档项下没有关联任务。", "No linked tasks for this archived item."))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingMd)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(linkedTasks) { task in
                        archiveTaskRow(task)
                    }
                }
            }
        }
    }

    private func archiveTaskRow(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? AppTheme.success : AppTheme.textTertiary)
                Text(task.title)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                archiveBadge(task.status.displayName, color: task.status == .completed ? AppTheme.success : AppTheme.warning)
                archiveBadge(task.priority.displayName, color: Color(hex: task.priority.color))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: AppTheme.spacingSm) {
                taskMeta(language.text("负责人", "Owner"), task.collaborator)
                taskMeta(language.text("截止", "Due"), task.dueDate?.formatted("yyyy-MM-dd HH:mm") ?? language.text("未设", "Unset"))
                taskMeta(language.text("完成度", "Progress"), "\(task.completionRate)%")
                if task.recurrence != .none {
                    taskMeta(language.text("循环", "Recurrence"), task.recurrence.displayName)
                }
            }

            if !task.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(task.details)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GeometryReader { geometry in
                Capsule()
                    .fill(AppTheme.surfaceElevated)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(task.status == .completed ? AppTheme.success : AppTheme.primary)
                            .frame(width: geometry.size.width * CGFloat(task.completionRate) / 100)
                    }
            }
            .frame(height: 3)
        }
        .padding(AppTheme.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .fill(AppTheme.background)
                .overlay(
                    LinearGradient(
                        colors: [
                            (task.status == .completed ? AppTheme.success : AppTheme.primary).opacity(0.045),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.border.opacity(0.65), lineWidth: 0.75)
        )
    }

    private func archiveCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            Label(title, systemImage: icon)
                .font(AppTheme.subtitleFont)
                .foregroundStyle(AppTheme.textPrimary)
            content()
        }
        .padding(AppTheme.spacingLg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                .stroke(AppTheme.border.opacity(0.75), lineWidth: 0.75)
        )
        .shadow(color: AppTheme.cardShadow, radius: 5, x: 0, y: 2)
    }

    private func detailGrid(_ items: [(String, String)]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: AppTheme.spacingMd) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text(item.1)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppTheme.spacingSm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.background.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))
            }
        }
    }

    private func detail(_ title: String, _ value: String) -> (String, String) {
        (title, value.isEmpty ? language.text("未填写", "Not provided") : value)
    }

    private func dateRange(_ start: Date?, _ end: Date?) -> String {
        switch (start, end) {
        case let (start?, end?): return "\(start.formatted("yyyy-MM-dd")) ~ \(end.formatted("yyyy-MM-dd"))"
        case let (start?, nil): return language.text("\(start.formatted("yyyy-MM-dd")) 起", "From \(start.formatted("yyyy-MM-dd"))")
        case let (nil, end?): return language.text("截止 \(end.formatted("yyyy-MM-dd"))", "Due \(end.formatted("yyyy-MM-dd"))")
        case (nil, nil): return language.text("未设置", "Unset")
        }
    }

    private func archiveBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 3)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }

    private func taskMeta(_ title: String, _ value: String) -> some View {
        Text("\(title)：\(value)")
            .font(AppTheme.captionFont)
            .foregroundStyle(AppTheme.textSecondary)
    }
}

struct AffairManagementView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = AffairManagementViewModel()
    @State private var taskToDelete: Task?
    @State private var showDeleteTaskConfirmation = false
    @State private var affairToDelete: Affair?
    @State private var showDeleteAffairConfirmation = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingLg) {
                overviewSection
                    .fadeIn()
                affairsSection
                    .fadeIn(delay: 0.1)
                tasksSection
                    .fadeIn(delay: 0.16)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            viewModel.loadData()
        }
        .alert(language.text("删除任务", "Delete Task"), isPresented: $showDeleteTaskConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let task = taskToDelete {
                    viewModel.deleteTask(task)
                }
                taskToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个任务吗？", "Delete this task?"))
        }
        .alert(language.text("删除事务", "Delete Affair"), isPresented: $showDeleteAffairConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let affair = affairToDelete {
                    viewModel.deleteAffair(affair)
                }
                affairToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个事务及其关联任务吗？此操作不可撤销。", "Delete this affair and its linked tasks? This cannot be undone."))
        }
    }

    private var overviewSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingLg) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text("事务管理", "Affair Management"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("管理团队短期事务和对应任务", "Manage short-term team affairs and their tasks"))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 330, alignment: .leading)

            CompactDashboardPanel(metrics: affairMetrics, quadrants: affairQuadrants)
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

    private var affairMetrics: [CompactDashboardMetric] {
        [
            .init(title: language.text("事务总数", "Affairs"), value: "\(viewModel.stats.totalAffairs)", color: AppTheme.primary),
            .init(title: language.text("进行中", "Active"), value: "\(viewModel.stats.activeAffairs)", color: AppTheme.secondary),
            .init(title: language.text("已完成", "Done"), value: "\(viewModel.stats.completedAffairs)", color: AppTheme.success),
            .init(title: language.text("关联任务", "Tasks"), value: "\(viewModel.stats.totalTasks)", color: AppTheme.accent),
            .init(title: language.text("任务完成", "Done"), value: "\(viewModel.stats.completedTasks)", color: AppTheme.success),
            .init(title: language.text("7天内", "7 Days"), value: "\(viewModel.stats.dueWithin7Days)", color: AppTheme.danger)
        ]
    }

    private var affairQuadrants: [CompactDashboardQuadrant] {
        [
            .init(title: language.text("紧急\n且重要", "Urgent\nImportant"), value: "\(viewModel.stats.todayMustDo)", icon: "exclamationmark.triangle.fill", color: AppTheme.danger),
            .init(title: language.text("重要\n不紧急", "Important\nNot Urgent"), value: "\(viewModel.stats.todayShouldDo)", icon: "arrow.up.circle.fill", color: AppTheme.warning),
            .init(title: language.text("紧急\n不重要", "Urgent\nNot Important"), value: "\(viewModel.stats.q3Tasks)", icon: "bolt.fill", color: AppTheme.secondary),
            .init(title: language.text("不紧急\n不重要", "Not Urgent\nNot Important"), value: "\(viewModel.stats.q4Tasks)", icon: "minus.circle.fill", color: AppTheme.textSecondary)
        ]
    }

    private var affairsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("事务", "Affairs"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("事务用于组织短期工作分区，分区名为 标题-日期。", "Affairs organize short-term work sections named title-date."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.beginCreatingAffair()
                } label: {
                    Label(language.text("新建事务", "New Affair"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)

                AffairTimelineSectionView(viewModel: viewModel)
            }

            if viewModel.showAffairForm {
                affairForm
            }

            if viewModel.affairs.isEmpty {
                emptyState(language.text("还没有事务。先创建一个短期工作分区。", "No affairs yet. Create a short-term work section."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.affairs) { affair in
                        AffairRowView(
                            affair: affair,
                            isSelected: viewModel.selectedAffairFilter == affair.id,
                            onSelect: {
                                viewModel.selectedAffairFilter = affair.id
                                viewModel.loadTasks()
                            },
                            onNewTask: {
                                viewModel.beginCreatingTask(prefilledAffairId: affair.id)
                            },
                            onArchive: {
                                viewModel.archiveAffair(affair)
                            },
                            onEdit: {
                                viewModel.beginEditingAffair(affair)
                            },
                            onDelete: {
                                affairToDelete = affair
                                showDeleteAffairConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("事务任务", "Affair Tasks"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("事务任务用于拆解短期事项，可按人员、截止时间和关注状态筛选。", "Affair tasks break down short-term work by owner, due time, and watched state."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if viewModel.selectedAffairFilter != nil {
                    Button(language.text("全部任务", "All Tasks")) {
                        viewModel.selectedAffairFilter = nil
                        viewModel.loadTasks()
                    }
                    .buttonStyle(.bordered)
                .workspaceButton()
                    .controlSize(.small)
                }
                Button {
                    viewModel.beginCreatingTask()
                } label: {
                    Label(language.text("新建任务", "New Task"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.accent)
                .disabled(viewModel.affairs.isEmpty)
            }

            filterBar

            if viewModel.showTaskForm {
                taskForm
            }

            if viewModel.filteredTasks.isEmpty {
                emptyState(language.text("当前没有事务任务。", "No affair tasks yet."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.filteredTasks) { task in
                        AffairTaskRowView(
                            task: task,
                            affair: store.affairs.first { $0.id == task.affairId },
                            onToggle: { viewModel.toggleTaskCompletion(task) },
                            onToggleToday: { viewModel.toggleTaskToday(task) },
                            onEdit: { viewModel.beginEditingTask(task) },
                            onDelaySaved: { viewModel.loadData() },
                            onDelete: {
                                taskToDelete = task
                                showDeleteTaskConfirmation = true
                            }
                        )
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var filterBar: some View {
        HStack(spacing: AppTheme.spacingSm) {
            Picker(language.text("事务筛选", "Affair Filter"), selection: $viewModel.selectedAffairFilter) {
                Text(language.text("全部事务", "All Affairs")).tag(nil as UUID?)
                ForEach(viewModel.affairs) { affair in
                    Text(affair.title).tag(affair.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .workspaceControl()

            Toggle(language.text("隐藏已完成", "Hide Completed"), isOn: $viewModel.hideCompletedTasks)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)

            Spacer()
        }
        .onChange(of: viewModel.selectedAffairFilter) {
            viewModel.loadTasks()
        }
        .onChange(of: viewModel.hideCompletedTasks) {
            viewModel.loadTasks()
        }
    }

    private var affairForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingAffairId == nil ? language.text("新建事务", "New Affair") : language.text("编辑事务", "Edit Affair"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                formField(language.text("事务标题", "Affair Title"), text: $viewModel.affairFormTitle)
                    .frame(minWidth: 260)
                formField(language.text("标签", "Tags"), text: $viewModel.affairFormTags)
                    .frame(width: 180)

                optionalDatePicker(
                    title: language.text("DDL", "DDL"),
                    hasDate: $viewModel.affairFormHasDueDate,
                    date: $viewModel.affairFormDueDate
                )
                .frame(width: 190)
            }

            multilineField(language.text("具体内容", "Details"), text: $viewModel.affairFormDetails)

            HStack {
                Button(viewModel.editingAffairId == nil ? language.text("保存事务", "Save Affair") : language.text("更新事务", "Update Affair")) {
                    viewModel.saveAffair()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)
                Button(language.text("取消", "Cancel")) {
                    viewModel.resetAffairForm()
                }
                .buttonStyle(.bordered)
                .workspaceButton()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private var taskForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingTaskId == nil ? language.text("新建事务任务", "New Affair Task") : language.text("编辑事务任务", "Edit Affair Task"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            formField(language.text("任务标题", "Task Title"), text: $viewModel.taskFormTitle)

            HStack(spacing: AppTheme.spacingSm) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("所属事务", "Affair"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("所属事务", "Affair"), selection: $viewModel.taskFormAffairId) {
                        Text(language.text("请选择事务", "Select an Affair")).tag(nil as UUID?)
                        ForEach(viewModel.affairs) { affair in
                            Text(affair.title).tag(affair.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("优先级", "Priority"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker(language.text("优先级", "Priority"), selection: $viewModel.taskFormPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                    .workspaceControl()
                }

                optionalDatePickerCompact(
                    title: language.text("DDL", "DDL"),
                    hasDate: $viewModel.taskFormHasDueDate,
                    date: $viewModel.taskFormDueDate
                )

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("关注", "Watched"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Toggle(language.text("关注", "Watched"), isOn: $viewModel.taskFormIsToday)
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                        .frame(height: 38)
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("Collaborator", "Collaborator"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField(language.text("Collaborator", "Collaborator"), text: $viewModel.taskFormCollaborator)
                        .textFieldStyle(WorkspaceTextFieldStyle())
                        .frame(maxWidth: 100)
                }
            }

            multilineField(language.text("任务内容", "Task Content"), text: $viewModel.taskFormDetails)

            TaskDependencyFormFields(
                blockedReason: $viewModel.taskFormBlockedReason,
                waitingFor: $viewModel.taskFormWaitingFor,
                prerequisiteTaskId: $viewModel.taskFormPrerequisiteTaskId,
                shouldPostpone: $viewModel.taskFormShouldPostpone,
                postponementDuration: $viewModel.taskFormPostponementDuration,
                editingTaskId: viewModel.editingTaskId
            )

            if let error = viewModel.taskFormError {
                Text(error)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.danger)
            }

            HStack {
                Button(viewModel.editingTaskId == nil ? language.text("保存任务", "Save Task") : language.text("更新任务", "Update Task")) {
                    viewModel.saveTask()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.accent)
                Button(language.text("取消", "Cancel")) {
                    viewModel.resetTaskForm()
                }
                .buttonStyle(.bordered)
                .workspaceButton()
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func formField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(WorkspaceTextFieldStyle())
        }
    }

    private func multilineField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            TextField(title, text: text, axis: .vertical)
                .textFieldStyle(WorkspaceTextFieldStyle())
                .lineLimit(2...4)
        }
    }

    private func optionalDatePicker(title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Toggle(title, isOn: hasDate)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: AppTheme.spacingXs) {
                DatePicker(language.text("日期", "Date"), selection: date, displayedComponents: .date)
                    .labelsHidden()
                DatePicker(language.text("时间", "Time"), selection: date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .workspaceControl()
            .disabled(!hasDate.wrappedValue)
            .opacity(hasDate.wrappedValue ? 1 : 0.45)
        }
    }

    private func optionalDatePickerCompact(title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Toggle(title, isOn: hasDate)
                .toggleStyle(.checkbox)
                .font(AppTheme.captionFont)
            HStack(spacing: AppTheme.spacingXs) {
                DatePicker(language.text("日期", "Date"), selection: date, displayedComponents: .date)
                    .labelsHidden()
                DatePicker(language.text("时间", "Time"), selection: date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .workspaceControl()
            .disabled(!hasDate.wrappedValue)
            .opacity(hasDate.wrappedValue ? 1 : 0.45)
        }
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(AppTheme.bodyFont)
            .foregroundStyle(AppTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacingXl)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}

private struct AffairRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let affair: Affair
    let isSelected: Bool
    var onSelect: () -> Void
    var onNewTask: () -> Void
    var onArchive: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }
    private var taskCount: Int {
        store.tasks.filter { $0.affairId == affair.id && $0.projectId == nil && $0.thesisId == nil }.count
    }
    private var affairProgress: Double {
        let tasks = store.tasks.filter { $0.affairId == affair.id && $0.projectId == nil && $0.thesisId == nil }
        guard !tasks.isEmpty else { return 0 }
        let completed = tasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(tasks.count)
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                HStack(spacing: AppTheme.spacingMd) {
                    Text(affair.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    if let deadline = affair.dueDate {
                        Text(deadline.formatted("yyyy-MM-dd"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.warning)
                    }
                    
                    ForEach(affair.tags, id: \.self) { tag in
                        badge(tag, color: AppTheme.primary)
                    }
                    
                    Spacer()
                    
                    infoChip(language.text("进度 \(Int(affairProgress * 100))%", "Progress \(Int(affairProgress * 100))%"), color: AppTheme.primary)
                    infoChip(language.text("\(taskCount) 个任务", "\(taskCount) tasks"), color: AppTheme.accent)
                }

                if !affair.details.isEmpty {
                    HStack(spacing: AppTheme.spacingSm) {
                        Text(language.text("详情", "Details") + ": ")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text(affair.details)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                HStack(spacing: AppTheme.spacingXs) {
                    Spacer()
                    Button(language.text("任务", "Tasks")) { onSelect() }
                        .buttonStyle(.bordered)
                .workspaceButton()
                    Button { onNewTask() } label: {
                        Label(language.text("任务", "Task"), systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                .workspaceButton()
                    Button { onArchive() } label: {
                        Label(language.text("归档", "Archive"), systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)
                .workspaceButton()
                    Button { onEdit() } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)
                .workspaceButton()
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                .workspaceButton()
                }
                .controlSize(.small)
            }
            .padding(AppTheme.spacingMd)
        }
        .background(isSelected ? AppTheme.primary.opacity(0.10) : AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func infoChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct AffairTaskRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let task: Task
    let affair: Affair?
    var onToggle: () -> Void
    var onToggleToday: () -> Void
    var onEdit: () -> Void
    var onDelaySaved: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacingMd) {
            Button {
                onToggle()
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.status == .completed ? AppTheme.success : AppTheme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                HStack(spacing: AppTheme.spacingSm) {
                    Text(task.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(task.status == .completed ? AppTheme.textTertiary : AppTheme.textPrimary)
                        .strikethrough(task.status == .completed, color: AppTheme.textTertiary)
                        .lineLimit(1)

                    badge(task.priority.displayName, color: Color(hex: task.priority.color))

                    if let deadline = task.dueDate {
                        Text(deadline.formatted("MM/dd HH:mm"))
                            .font(AppTheme.captionFont)
                            .foregroundStyle(task.isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                    }

                    if task.isToday {
                        badge(language.text("关注", "Watched"), color: AppTheme.warning)
                    }

                    Text("• \(task.collaborator)")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    if let affair {
                        ForEach(affair.tags, id: \.self) { tag in
                            badge(tag, color: AppTheme.primary)
                        }
                    }
                }

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                TaskDependencySummary(task: task)
            }

            Spacer()

            HStack(spacing: AppTheme.spacingXs) {
                Button {
                    onToggleToday()
                } label: {
                    Image(systemName: task.isToday ? "flag.fill" : "flag")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)

                TaskDelayButton(task: task, onSaved: onDelaySaved)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .workspaceButton()
                .controlSize(.small)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func meta(_ title: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(AppTheme.captionFont)
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
