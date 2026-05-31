import AppKit
import SwiftUI

struct ThesesSectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @ObservedObject var viewModel: ThesisManagementViewModel
    @State private var thesisToDelete: ThesisInfo?
    @State private var showDeleteThesisConfirmation = false
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
                            onSelect: {
                                viewModel.selectedThesisFilter = thesis.id
                                viewModel.loadTasks()
                            },
                            onArchive: {
                                viewModel.archiveThesis(thesis)
                            },
                            onEdit: {
                                viewModel.beginEditingThesis(thesis)
                            },
                            onDelete: {
                                thesisToDelete = thesis
                                showDeleteThesisConfirmation = true
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
        .alert(language.text("删除课题", "Delete Thesis"), isPresented: $showDeleteThesisConfirmation) {
            Button(language.text("取消", "Cancel"), role: .cancel) {}
            Button(language.text("删除", "Delete"), role: .destructive) {
                if let thesis = thesisToDelete {
                    viewModel.deleteThesis(thesis)
                }
                thesisToDelete = nil
            }
        } message: {
            Text(language.text("确定删除这个课题及其关联任务吗？此操作不可撤销。", "Delete this thesis and its linked tasks? This cannot be undone."))
        }
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
            }

            HStack(alignment: .bottom, spacing: AppTheme.spacingSm) {
                formField(language.text("共享文档链接", "Shared Doc Link"), text: $viewModel.thesisFormSharedDocumentLink)
                    .frame(width: 260)

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("课题状态", "Thesis Stage"))
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("", selection: $viewModel.thesisFormStage) {
                        ForEach(ThesisStage.allCases, id: \.self) { stage in
                            Text(stage.displayName).tag(stage)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .workspaceControl()
                }
                .frame(width: 150)

                thesisDatePicker(
                    title: language.text("DDL", "DDL"),
                    hasDate: $viewModel.thesisFormHasDueDate,
                    date: $viewModel.thesisFormDueDate
                )
                .frame(width: 260)

                Spacer(minLength: 0)
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

    private func thesisDatePicker(title: String, hasDate: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacingSm) {
                Toggle(title, isOn: hasDate)
                    .labelsHidden()
                    .toggleStyle(.checkbox)

                DatePicker(title, selection: date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .disabled(!hasDate.wrappedValue)
                    .opacity(hasDate.wrappedValue ? 1 : 0.45)
            }
            .frame(height: 38)
            .padding(.horizontal, AppTheme.spacingSm)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMd)
                    .stroke(AppTheme.border, lineWidth: 0.75)
            )
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
    var onSelect: () -> Void
    var onArchive: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    private var language: AppLanguage { store.appLanguage }
    private var taskCount: Int {
        store.tasks.filter { $0.thesisId == thesis.id && $0.projectId == nil && $0.affairId == nil }.count
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.primary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                HStack(spacing: AppTheme.spacingMd) {
                    Text(thesis.title)
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    infoChip(thesis.stage.displayName, color: AppTheme.warning)

                    if let dueDate = thesis.dueDate {
                        infoChip(language.text("DDL \(dueDate.formatted("MM/dd HH:mm"))", "DDL \(dueDate.formatted("MM/dd HH:mm"))"), color: AppTheme.danger)
                    }
                    
                    if !thesis.sharedDocumentLink.isEmpty {
                        sharedDocumentChip(thesis.sharedDocumentLink)
                    }

                    ForEach(thesis.students) { student in
                        infoChip(student.name, color: AppTheme.secondary)
                    }
                    
                    Spacer()
                    
                    infoChip(language.text("进度 \(Int(thesis.overallProgress * 100))%", "Progress \(Int(thesis.overallProgress * 100))%"), color: AppTheme.primary)
                    infoChip(language.text("\(taskCount) 个任务", "\(taskCount) tasks"), color: AppTheme.accent)
                }

                if !thesis.notes.isEmpty {
                    HStack(spacing: AppTheme.spacingSm) {
                        Text(language.text("摘要", "Abstract") + ": ")
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textTertiary)
                        Text(thesis.notes)
                            .font(AppTheme.captionFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                HStack(spacing: AppTheme.spacingXs) {
                    Spacer()
                    Button(language.text("任务", "Tasks")) { onSelect() }
                        .buttonStyle(.bordered)
                    Button { onArchive() } label: {
                        Label(language.text("归档", "Archive"), systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)
                    Button { onEdit() } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
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
}
