import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var showClearConfirm: Bool = false
    @State private var statusMessage: String = ""
    @State private var statusType: StatusType = .info
    @State private var appNameDraft: String = ""
    private var language: AppLanguage { store.appLanguage }

    enum StatusType {
        case info
        case success
        case error
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXl) {
                headerSection
                    .fadeIn()

                interfaceSettingsSection
                    .fadeIn(delay: 0.1)

                storageInfoSection
                    .fadeIn(delay: 0.15)

                dataActionsSection
                    .fadeIn(delay: 0.2)

                dataOverviewSection
                    .fadeIn(delay: 0.25)
            }
            .padding(AppTheme.spacingLg)
        }
        .workspacePageBackground()
        .onAppear {
            appNameDraft = store.appDisplayName
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AppTheme.spacingMd) {
            VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                Text(language.text("数据与设置", "Data & Settings"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(language.text("管理应用数据与界面设置", "Manage app data and interface settings"))
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Interface Settings

    private var interfaceSettingsSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("界面设置", "Interface"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.primary)
                }

                Divider()
                    .background(AppTheme.divider)

                VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                    Text(language.text("语言", "Language"))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)

                    Picker("", selection: Binding(
                        get: { store.appLanguage },
                        set: { newLanguage in
                            store.updateAppLanguage(newLanguage)
                            showStatus(
                                newLanguage.text("语言已切换为中文。", "Language switched to English."),
                                type: .success
                            )
                        }
                    )) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .workspaceSegmented()
                }

                HStack(spacing: AppTheme.spacingMd) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXs) {
                        Text(language.text("左上角名称", "App Name"))
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                        TextField("Scholar", text: $appNameDraft)
                            .textFieldStyle(WorkspaceTextFieldStyle())
                            .font(AppTheme.bodyFont)
                    }

                    Spacer()

                    HStack(spacing: AppTheme.spacingSm) {
                        PrimaryButton(
                            title: language.text("保存", "Save"),
                            icon: "checkmark",
                            action: {
                                store.updateAppDisplayName(appNameDraft)
                                appNameDraft = store.appDisplayName
                                showStatus(language.text("名称已更新。", "App name updated."), type: .success)
                            }
                        )

                        GhostButton(
                            title: language.text("恢复默认", "Reset"),
                            icon: "arrow.counterclockwise",
                            action: {
                                store.updateAppDisplayName("Scholar")
                                appNameDraft = store.appDisplayName
                                showStatus(language.text("名称已恢复默认。", "App name reset."), type: .success)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Storage Info

    private var storageInfoSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("存储信息", "Storage"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "externaldrive.fill")
                        .foregroundStyle(AppTheme.secondary)
                }

                Divider()
                    .background(AppTheme.divider)

                VStack(spacing: AppTheme.spacingMd) {
                    InfoRow(
                        icon: "folder.fill",
                        iconColor: AppTheme.primary,
                        title: language.text("当前 Workspace", "Current Workspace"),
                        value: store.workspaceName
                    )

                    InfoRow(
                        icon: "doc.fill",
                        iconColor: AppTheme.secondary,
                        title: language.text("存储位置", "Location"),
                        value: store.storageInfo.displayPath
                    )

                    InfoRow(
                        icon: "doc.text.fill",
                        iconColor: AppTheme.accent,
                        title: language.text("数据格式", "Format"),
                        value: store.storageInfo.dataFormat
                    )

                    InfoRow(
                        icon: "number",
                        iconColor: AppTheme.success,
                        title: language.text("数据版本", "Version"),
                        value: store.storageInfo.dataVersion
                    )
                }

                SecondaryButton(
                    title: language.text("切换 Workspace", "Switch Workspace"),
                    icon: "arrow.left.arrow.right",
                    action: {
                        if store.selectWorkspaceWithPanel() {
                            showStatus(
                                language.text(
                                    "Workspace 已切换到：\(store.workspaceName)",
                                    "Workspace switched to: \(store.workspaceName)"
                                ),
                                type: .success
                            )
                        }
                    }
                )
            }
        }
    }

    // MARK: - Data Actions

    private var dataActionsSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("数据操作", "Data Actions"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }

                Divider()
                    .background(AppTheme.divider)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacingMd) {
                    ActionButton(
                        title: language.text("导出数据", "Export Data"),
                        icon: "square.and.arrow.up",
                        color: AppTheme.accent,
                        action: exportData
                    )

                    ActionButton(
                        title: language.text("导入数据", "Import Data"),
                        icon: "square.and.arrow.down",
                        color: AppTheme.accent,
                        action: importData
                    )

                    ActionButton(
                        title: language.text("清空全部数据", "Clear All Data"),
                        icon: "trash",
                        color: AppTheme.danger,
                        action: { showClearConfirm = true }
                    )

                    ActionButton(
                        title: language.text("复制到剪贴板", "Copy to Clipboard"),
                        icon: "doc.on.doc",
                        color: AppTheme.secondary,
                        action: copyToClipboard
                    )
                }

                statusMessageView
            }
        }
        .alert(language.text("确认清空", "Confirm Clear"), isPresented: $showClearConfirm) {
            Button(language.text("取消", "Cancel"), role: .cancel) { }
            Button(language.text("清空", "Clear"), role: .destructive) {
                store.clearAll()
                showStatus(language.text("所有数据已清空。", "All data has been cleared."), type: .success)
            }
        } message: {
            Text(language.text("此操作将删除所有数据且不可恢复，确定继续吗？", "This deletes all data and cannot be undone. Continue?"))
        }
    }

    @ViewBuilder
    private var statusMessageView: some View {
        if !statusMessage.isEmpty {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusForegroundColor)

                Text(statusMessage)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(statusForegroundColor)

                Spacer()
            }
            .padding(AppTheme.spacingMd)
            .background(statusBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .stroke(statusBorderColor, lineWidth: 1)
            )
        }
    }

    private var statusIcon: String {
        switch statusType {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusForegroundColor: Color {
        switch statusType {
        case .info:
            return AppTheme.textSecondary
        case .success:
            return AppTheme.success
        case .error:
            return AppTheme.danger
        }
    }

    private var statusBackgroundColor: Color {
        switch statusType {
        case .info:
            return AppTheme.background
        case .success:
            return AppTheme.success.opacity(0.1)
        case .error:
            return AppTheme.danger.opacity(0.1)
        }
    }

    private var statusBorderColor: Color {
        switch statusType {
        case .info:
            return AppTheme.border
        case .success:
            return AppTheme.success.opacity(0.3)
        case .error:
            return AppTheme.danger.opacity(0.3)
        }
    }

    // MARK: - Data Overview

    private var dataOverviewSection: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                HStack {
                    Text(language.text("数据概览", "Data Overview"))
                        .font(AppTheme.subtitleFont)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(AppTheme.primary)
                }

                Divider()
                    .background(AppTheme.divider)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: AppTheme.spacingMd) {
                    DataOverviewItem(title: language.text("项目", "Projects"), count: store.projects.count, icon: "folder", color: AppTheme.primary)
                    DataOverviewItem(title: language.text("任务", "Tasks"), count: store.tasks.count, icon: "checklist", color: AppTheme.accent)
                    DataOverviewItem(title: language.text("课题", "Topics"), count: store.thesisInfos.count, icon: "doc.text", color: AppTheme.primary)
                    DataOverviewItem(title: language.text("投稿项目", "Submissions"), count: store.submissions.count, icon: "paperplane", color: AppTheme.accent)
                    DataOverviewItem(title: language.text("健康习惯", "Health Habits"), count: store.healthHabits.count, icon: "heart", color: AppTheme.danger)
                    DataOverviewItem(title: language.text("健康记录", "Health Records"), count: store.healthRecords.count, icon: "heart.text.square", color: AppTheme.success)
                    DataOverviewItem(title: language.text("心灵关怀", "Mental Care"), count: store.mentalCareRecords.count, icon: "brain.head.profile", color: AppTheme.secondary)
                    DataOverviewItem(title: language.text("成就", "Achievements"), count: store.achievements.count, icon: "trophy", color: AppTheme.warning)
                }
            }
        }
    }

    // MARK: - Helper Views

    private struct InfoRow: View {
        let icon: String
        let iconColor: Color
        let title: String
        let value: String

        var body: some View {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSm))

                Text(title)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .textSelection(.enabled)
            }
        }
    }

    private struct ActionButton: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacingMd)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .hoverScale(1.02)
        }
    }

    private struct DataOverviewItem: View {
        let title: String
        let count: Int
        let icon: String
        let color: Color

        var body: some View {
            VStack(spacing: AppTheme.spacingSm) {
                HStack(spacing: AppTheme.spacingXs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)

                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text("\(count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.spacingMd)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
    }

    // MARK: - Actions

    private func showStatus(_ message: String, type: StatusType) {
        statusMessage = message
        statusType = type
    }

    private func exportData() {
        guard let jsonData = store.exportWorkspaceBundle() else {
            showStatus(language.text("导出失败：无法生成数据。", "Export failed: unable to generate data."), type: .error)
            return
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = store.defaultBackupFileName

        let response = panel.runModal()
        store.restoreApplicationFocus()
        if response == .OK, let url = panel.url {
            do {
                try jsonData.write(to: url)
                showStatus(
                    language.text(
                        "数据已成功导出到：\(url.lastPathComponent)",
                        "Data exported to: \(url.lastPathComponent)"
                    ),
                    type: .success
                )
            } catch {
                showStatus(
                    language.text(
                        "导出失败：\(error.localizedDescription)",
                        "Export failed: \(error.localizedDescription)"
                    ),
                    type: .error
                )
            }
        }
    }

    private func importData() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        let response = panel.runModal()
        store.restoreApplicationFocus()
        if response == .OK, let url = panel.url {
            do {
                let jsonData = try Data(contentsOf: url)
                let imported: Bool
                if url.pathExtension == "json" {
                    imported = store.importLegacyJSON(jsonData)
                } else {
                    imported = store.importWorkspaceBundle(jsonData)
                }
                if imported {
                    showStatus(language.text("数据已成功导入。", "Data imported successfully."), type: .success)
                } else {
                    showStatus(
                        language.text(
                            "导入失败：数据格式不正确或解析错误。",
                            "Import failed: unsupported format or parse error."
                        ),
                        type: .error
                    )
                }
            } catch {
                showStatus(
                    language.text(
                        "导入失败：无法读取文件。\(error.localizedDescription)",
                        "Import failed: unable to read the file. \(error.localizedDescription)"
                    ),
                    type: .error
                )
            }
        }
    }

    private func copyToClipboard() {
        guard let jsonData = store.exportWorkspaceBundle() else {
            showStatus(language.text("复制失败：无法生成数据。", "Copy failed: unable to generate data."), type: .error)
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(String(decoding: jsonData, as: UTF8.self), forType: .string)
        showStatus(language.text("明文 JSON 已复制到剪贴板。", "Plain JSON copied to the clipboard."), type: .success)
    }
}
