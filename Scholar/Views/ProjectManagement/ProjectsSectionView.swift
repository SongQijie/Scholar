import SwiftUI

struct ProjectsSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ProjectManagementViewModel
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
                .tint(AppTheme.primary)
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
                                taskCount: AppDataStore.shared.tasks.filter { $0.projectId == project.id && $0.thesisId == nil }.count,
                                reminderListName: viewModel.reminderLists.first { $0.id == project.reminderCalendarIdentifier }?.title,
                                onSelect: {
                                    viewModel.selectedProjectFilter = project.id
                                    viewModel.loadTasks()
                                },
                                onSync: {
                                    viewModel.syncProjectToReminders(project)
                                },
                                onEdit: {
                                    viewModel.beginEditingProject(project)
                                },
                                onDelete: {
                                    viewModel.deleteProject(project)
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
                formField(language.text("预期成果", "Expected Outcome"), text: $viewModel.projectFormResult)
                formField(language.text("负责人", "Owner"), text: $viewModel.projectFormOwner)
                formField(language.text("合作方 / 合作者", "Partners / Collaborators"), text: $viewModel.projectFormCollaborators)
                formField(language.text("共享文档链接", "Shared Doc Link"), text: $viewModel.projectFormSharedDocumentLink)
                formField(language.text("经费来源", "Funding Source"), text: $viewModel.projectFormFundingSource)
                formField(language.text("关键词（逗号分隔）", "Keywords (comma separated)"), text: $viewModel.projectFormKeywords)
                formField(language.text("预算", "Budget"), text: $viewModel.projectFormBudget)
            }

            reminderListPicker

            HStack(spacing: AppTheme.spacingSm) {
                Picker(language.text("分类", "Category"), selection: $viewModel.projectFormCategory) {
                    ForEach(ProjectCategory.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
                Picker(language.text("阶段", "Stage"), selection: $viewModel.projectFormStage) {
                    ForEach(ProjectStage.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
                Picker(language.text("优先级", "Priority"), selection: $viewModel.projectFormPriority) {
                    ForEach(ProjectPriority.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .workspaceControl()
            }

            HStack(spacing: AppTheme.spacingSm) {
                DatePicker(language.text("开始", "Start"), selection: $viewModel.projectFormStartDate, displayedComponents: [.date, .hourAndMinute])
                    .workspaceControl()
                DatePicker(language.text("截止", "Deadline"), selection: $viewModel.projectFormDeadline, displayedComponents: [.date, .hourAndMinute])
                    .workspaceControl()
            }

            multilineField(language.text("项目摘要", "Summary"), text: $viewModel.projectFormSummary)
            multilineField(language.text("阶段性交付物", "Deliverables"), text: $viewModel.projectFormExpectedDeliverables)
            multilineField(language.text("备注", "Notes"), text: $viewModel.projectFormNotes)

            HStack {
                Button(viewModel.editingProjectId == nil ? language.text("保存项目", "Save Project") : language.text("更新项目", "Update Project")) {
                    viewModel.saveProject()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button(language.text("取消", "Cancel")) {
                    viewModel.resetProjectForm()
                }
                .buttonStyle(.bordered)
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

    private var reminderListPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(language.text("关联提醒事项列表", "Linked Reminders List"))
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
            Picker(language.text("关联提醒事项列表", "Linked Reminders List"), selection: $viewModel.projectFormReminderCalendarIdentifier) {
                Text(language.text("不关联", "Not Linked")).tag(nil as String?)
                ForEach(viewModel.reminderLists) { list in
                    Text(list.title).tag(list.id as String?)
                }
            }
            .pickerStyle(.menu)
            .workspaceControl()
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

struct ProjectRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let project: Project
    let taskCount: Int
    let reminderListName: String?
    var onSelect: () -> Void
    var onSync: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(project.name)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(project.summary.isEmpty ? project.result : project.summary)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: AppTheme.spacingXs) {
                    Button(language.text("任务", "Tasks")) { onSelect() }
                        .buttonStyle(.bordered)
                    if project.reminderCalendarIdentifier != nil {
                        Button {
                            onSync()
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                    }
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.small)
            }

            HStack(spacing: AppTheme.spacingSm) {
                infoChip(project.category.displayName, color: AppTheme.secondary)
                infoChip(project.stage.displayName, color: AppTheme.primary)
                infoChip(language.text("优先级 \(project.priority.displayName)", "Priority \(project.priority.displayName)"), color: AppTheme.warning)
                infoChip(language.text("\(taskCount) 个项目任务", "\(taskCount) project tasks"), color: AppTheme.accent)
                if let reminderListName {
                    infoChip(language.text("提醒事项：\(reminderListName)", "Reminders: \(reminderListName)"), color: AppTheme.success)
                }
            }

            if project.sharedDocumentLink.isNotEmpty {
                Text(language.text("共享文档：\(project.sharedDocumentLink)", "Shared doc: \(project.sharedDocumentLink)"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
                    .lineLimit(1)
            }

            HStack(spacing: AppTheme.spacingMd) {
                detailText(language.text("负责人", "Owner"), value: project.owner.isEmpty ? language.text("未填写", "Not set") : project.owner)
                detailText(language.text("协作", "Collab"), value: project.collaborators.isEmpty ? language.text("未填写", "Not set") : project.collaborators)
                detailText(language.text("时间", "Timeline"), value: dateRangeText)
            }
        }
        .padding(AppTheme.spacingMd)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    private func infoChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.captionFont)
            .padding(.horizontal, AppTheme.spacingSm)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func detailText(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary)
            Text(value)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private var dateRangeText: String {
        let start = project.startDate?.formatted("MM/dd HH:mm") ?? language.text("未设", "Unset")
        let end = project.deadline?.formatted("MM/dd HH:mm") ?? language.text("未设", "Unset")
        return "\(start) - \(end)"
    }
}
