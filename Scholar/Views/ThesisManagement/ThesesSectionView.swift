import SwiftUI

struct ThesesSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ThesisManagementViewModel
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("课题", "Theses"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(language.text("课题围绕学生、研究内容和共享文档组织，不再展示答辩日期。", "Theses are organized around students, research content, and shared documents. Defense dates are no longer shown."))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Button {
                    viewModel.beginCreatingThesis()
                } label: {
                    Label(language.text("新建课题", "New Thesis"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
            }

            if viewModel.showThesisForm {
                thesisForm
            }

            if viewModel.theses.isEmpty {
                emptyState(language.text("还没有课题，先把研究主题和学生关联起来。", "No theses yet. Start by linking a research topic with students."))
            } else {
                VStack(spacing: AppTheme.spacingSm) {
                    ForEach(viewModel.theses) { thesis in
                        ThesisRowView(
                            thesis: thesis,
                            taskCount: AppDataStore.shared.tasks.filter { $0.thesisId == thesis.id && $0.projectId == nil }.count,
                            reminderListName: viewModel.reminderLists.first { $0.id == thesis.reminderCalendarIdentifier }?.title,
                            onSelect: {
                                viewModel.selectedThesisFilter = thesis.id
                                viewModel.loadTasks()
                            },
                            onSync: {
                                viewModel.syncThesisToReminders(thesis)
                            },
                            onEdit: {
                                viewModel.beginEditingThesis(thesis)
                            },
                            onDelete: {
                                viewModel.deleteThesis(thesis)
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

    private var thesisForm: some View {
        VStack(spacing: AppTheme.spacingMd) {
            HStack {
                Text(viewModel.editingThesisId == nil ? language.text("新建课题", "New Thesis") : language.text("编辑课题", "Edit Thesis"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingSm) {
                formField(language.text("课题标题", "Thesis Title"), text: $viewModel.thesisFormTitle)
                formField(language.text("关联学生（逗号分隔）", "Students (comma separated)"), text: $viewModel.thesisFormStudents)
                formField(language.text("共享文档链接", "Shared Doc Link"), text: $viewModel.thesisFormSharedDocumentLink)
            }

            reminderListPicker

            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("课题状态", "Thesis Stage"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.textSecondary)
                Picker(language.text("课题状态", "Thesis Stage"), selection: $viewModel.thesisFormStage) {
                    ForEach(ThesisStage.allCases, id: \.self) { stage in
                        Text(stage.displayName).tag(stage)
                    }
                }
                .pickerStyle(.segmented)
                .workspaceSegmented()
            }

            multilineField(language.text("备注", "Notes"), text: $viewModel.thesisFormNotes)

            HStack {
                Button(viewModel.editingThesisId == nil ? language.text("保存课题", "Save Thesis") : language.text("更新课题", "Update Thesis")) {
                    viewModel.saveThesis()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)

                Button(language.text("取消", "Cancel")) {
                    viewModel.resetThesisForm()
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
            Picker(language.text("关联提醒事项列表", "Linked Reminders List"), selection: $viewModel.thesisFormReminderCalendarIdentifier) {
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

struct ThesisRowView: View {
    @EnvironmentObject private var store: AppDataStore
    let thesis: ThesisInfo
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.spacingSm) {
                            Text(thesis.title)
                                .font(AppTheme.bodyFont)
                                .foregroundStyle(AppTheme.textPrimary)
                            infoChip(thesis.stage.displayName, color: AppTheme.warning)
                            infoChip(language.text("进度 \(Int(thesis.overallProgress * 100))%", "Progress \(Int(thesis.overallProgress * 100))%"), color: AppTheme.primary)
                            ForEach(thesis.students) { student in
                                infoChip(student.name, color: AppTheme.secondary)
                            }
                        }
                    }
                    Text(thesis.notes.isEmpty ? language.text("可关联学生、文档和课题任务。", "You can link students, documents, and thesis tasks.") : thesis.notes)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: AppTheme.spacingXs) {
                    Button(language.text("任务", "Tasks")) { onSelect() }
                        .buttonStyle(.bordered)
                    if thesis.reminderCalendarIdentifier != nil {
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
                infoChip(language.text("\(taskCount) 个课题任务", "\(taskCount) thesis tasks"), color: AppTheme.accent)
                if let reminderListName {
                    infoChip(language.text("提醒事项：\(reminderListName)", "Reminders: \(reminderListName)"), color: AppTheme.success)
                }
            }

            if thesis.sharedDocumentLink.isNotEmpty {
                Text(language.text("共享文档：\(thesis.sharedDocumentLink)", "Shared doc: \(thesis.sharedDocumentLink)"))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.primary)
                    .lineLimit(1)
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
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
