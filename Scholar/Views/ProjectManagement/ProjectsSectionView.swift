import AppKit
import SwiftUI

struct ProjectsSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ProjectManagementViewModel
    @State private var projectToDelete: Project?
    @State private var showDeleteProjectConfirmation = false
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("项目", "Projects"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("项目用于承接科研、教学、基金、学生指导和公共服务等长期工作线。", "Projects hold long-running research, teaching, grants, mentoring, and service workstreams."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.beginCreatingProject()
                } label: {
                    Label(language.text("新建项目", "New Project"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)

                ProjectTimelineSectionView(viewModel: viewModel)
            }

            if viewModel.showProjectForm {
                projectForm
            }

            if viewModel.projects.isEmpty {
                emptyState(language.text("还没有项目，先创建一个用于承接项目任务。", "No projects yet. Create one to hold project tasks."))
            } else {
                ForEach(viewModel.projectsByCategory, id: \.0) { category, projects in
                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        Text(category.displayName)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        ForEach(projects) { project in
                            ProjectRowView(
                                project: project,
                                onSelect: {
                                    viewModel.selectedProjectFilter = project.id
                                    viewModel.loadTasks()
                                },
                                onArchive: {
                                    viewModel.archiveProject(project)
                                },
                                onEdit: {
                                    viewModel.beginEditingProject(project)
                                },
                                onDelete: {
                                    projectToDelete = project
                                    showDeleteProjectConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        .shadow(color: AppTheme.cardShadow, radius: 4, x: 0, y: 2)
        .alert(language.text("删除项目", "Delete Project"), isPresented: $showDeleteProjectConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let project = projectToDelete {
                    viewModel.deleteProject(project)
                }
                projectToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个项目及其关联任务吗？此操作不可撤销。", "Delete this project and its linked tasks? This cannot be undone."))
        }
    }

    private var projectForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingProjectId == nil ? language.text("新建项目", "New Project") : language.text("编辑项目", "Edit Project"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSm) {
                formField(language.text("项目名称", "Project Name"), text: $viewModel.projectFormTitle)
                formField(language.text("负责人", "Owner"), text: $viewModel.projectFormOwner)
                formField(language.text("合作方 / 合作者", "Partners / Collaborators"), text: $viewModel.projectFormCollaborators)
                formField(language.text("共享文档链接", "Shared Doc Link"), text: $viewModel.projectFormSharedDocumentLink)
                formField(language.text("项目来源", "Project Source"), text: $viewModel.projectFormFundingSource)
                formField(language.text("预算", "Budget"), text: $viewModel.projectFormBudget)
            }

            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                compactPickerField(language.text("分类", "Category"), width: 120) {
                    Picker("", selection: $viewModel.projectFormCategory) {
                        ForEach(ProjectCategory.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                }

                compactPickerField(language.text("阶段", "Stage"), width: 120) {
                    Picker("", selection: $viewModel.projectFormStage) {
                        ForEach(ProjectStage.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                }

                compactOptionalDateField(
                    language.text("开始时间", "Start"),
                    hasDate: $viewModel.projectFormHasStartDate,
                    date: $viewModel.projectFormStartDate
                )
                .frame(width: 170)

                compactOptionalDateField(
                    language.text("截止时间", "Due"),
                    hasDate: $viewModel.projectFormHasDeadline,
                    date: $viewModel.projectFormDeadline
                )
                .frame(width: 170)
            }

            multilineField(language.text("项目摘要", "Summary"), text: $viewModel.projectFormSummary)
            multilineField(language.text("预期成果", "Expected Outcome"), text: $viewModel.projectFormExpectedDeliverables)
            multilineField(language.text("备注", "Notes"), text: $viewModel.projectFormNotes)

            HStack {
                Button(viewModel.editingProjectId == nil ? language.text("保存项目", "Save Project") : language.text("更新项目", "Update Project")) {
                    viewModel.saveProject()
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)

                Button(language.text("取消", "Cancel")) {
                    viewModel.resetProjectForm()
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

    private func compactOptionalDateField(_ title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: AppTheme.spacingXs) {
                Toggle(title, isOn: hasDate)
                    .labelsHidden()
                    .toggleStyle(.checkbox)

                DatePicker(title, selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .disabled(!hasDate.wrappedValue)
                    .opacity(hasDate.wrappedValue ? 1 : 0.45)
            }
            .workspaceControl()
        }
    }

    private func compactPickerField<Content: View>(_ title: String, width: CGFloat, @ViewBuilder picker: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            picker()
                .labelsHidden()
                .pickerStyle(.menu)
                .workspaceControl()
        }
        .frame(width: width)
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

struct ProjectRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let project: Project
    var onSelect: () -> Void
    var onArchive: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }
    private var taskCount: Int {
        store.tasks.filter { $0.projectId == project.id && $0.thesisId == nil && $0.affairId == nil }.count
    }
    private var projectProgress: Double {
        let tasks = store.tasks.filter { $0.projectId == project.id && $0.thesisId == nil && $0.affairId == nil }
        guard !tasks.isEmpty else { return 0 }
        let completed = tasks.filter { $0.status == .completed }.count
        return Double(completed) / Double(tasks.count)
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.primary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                HStack(spacing: AppTheme.spacingMd) {
                    Text(project.name)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    infoChip(project.category.displayName, color: AppTheme.secondary)
                    infoChip(project.stage.displayName, color: AppTheme.primary)
                    
                    if let start = project.startDate, let end = project.deadline {
                        infoChip("\(start.formatted("yyyy-MM-dd")) ~ \(end.formatted("yyyy-MM-dd"))", color: AppTheme.warning)
                    } else if let end = project.deadline {
                        infoChip(language.text("截止 \(end.formatted("yyyy-MM-dd"))", "Due \(end.formatted("yyyy-MM-dd"))"), color: AppTheme.warning)
                    }
                    
                    if !project.sharedDocumentLink.isEmpty {
                        sharedDocumentChip(project.sharedDocumentLink)
                    }
                    
                    Spacer()
                    
                    infoChip(language.text("进度 \(Int(projectProgress * 100))%", "Progress \(Int(projectProgress * 100))%"), color: AppTheme.primary)
                    infoChip(language.text("\(taskCount) 个任务", "\(taskCount) tasks"), color: AppTheme.accent)
                }

                if !project.summary.isEmpty {
                    Text(project.summary)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                if !project.result.isEmpty {
                    Text(language.text("预期成果", "Expected Outcome") + ": " + project.result)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: AppTheme.spacingMd) {
                    if !project.owner.isEmpty {
                        detailText(language.text("负责人", "Owner"), value: project.owner)
                    }
                    if !project.collaborators.isEmpty {
                        detailText(language.text("合作方", "Collaborators"), value: project.collaborators)
                    }
                    if !project.fundingSource.isEmpty {
                        detailText(language.text("项目来源", "Source"), value: project.fundingSource)
                    }
                    if let budget = project.budget {
                        detailText(language.text("预算", "Budget"), value: String(format: "%.2f", budget))
                    }
                }

                if !project.notes.isEmpty {
                    Text(project.notes)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary)
                        .lineLimit(1)
                }

                HStack(spacing: AppTheme.spacingXs) {
                    Spacer()
                    Button(language.text("任务", "Tasks")) { onSelect() }
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
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                .stroke(AppTheme.divider, lineWidth: 0.5)
        )
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

    private func sharedDocumentChip(_ link: String) -> some View {
        Button {
            openSharedDocument(link)
        } label: {
            infoChip(language.text("📎 共享文档", "📎 Shared Doc"), color: AppTheme.primary)
        }
        .buttonStyle(.plain)
    }

    private func openSharedDocument(_ link: String) {
        guard let url = sharedDocumentURL(from: link) else { return }
        NSWorkspace.shared.open(url)
    }

    private func sharedDocumentURL(from link: String) -> URL? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }

    private func detailText(_ title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }
}
