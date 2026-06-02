import SwiftUI

struct WorkspaceSelectionView: View {
    @EnvironmentObject private var store: AppDataStore
    private var language: AppLanguage { store.appLanguage }

    var body: some View {
        ZStack {
            AppTheme.workspaceBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                                .fill(AppTheme.primaryGradient)
                        )
                        .shadow(color: AppTheme.primary.opacity(0.28), radius: 14, x: 0, y: 8)

                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        Text(language.text("选择 Workspace", "Choose Workspace"))
                            .font(AppTheme.titleFont)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(
                            language.text(
                                "科研项目、教学任务、学生指导、成果和附件会按分类保存在你选择的文件夹中，首次选择后会自动记住，后续启动直接恢复。数据文件使用明文 JSON 保存。",
                                "Research projects, teaching work, student mentoring, outcomes, and attachments are stored in categorized folders inside the workspace you choose. The first selection is remembered automatically and restored on later launches. Data files are stored as plain JSON."
                            )
                        )
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                    infoRow(
                        title: language.text("存储方式", "Storage"),
                        value: language.text("分类目录保存", "Categorized folders")
                    )
                    infoRow(
                        title: language.text("数据格式", "Data Format"),
                        value: language.text("JSON 明文", "Plain JSON")
                    )
                    infoRow(
                        title: language.text("附件策略", "Attachments"),
                        value: language.text("复制进 workspace 附件目录", "Copied into the workspace attachments folder")
                    )
                }
                .padding(AppTheme.spacingMd)
                .background(AppTheme.surfaceElevated.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                if !store.lastErrorMessage.isEmpty {
                    Text(store.lastErrorMessage)
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.danger)
                        .padding(AppTheme.spacingSm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.danger.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }

                Button {
                    _ = store.selectWorkspaceWithPanel()
                } label: {
                    Label(language.text("选择 Workspace 文件夹", "Choose Workspace Folder"), systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacingSm)
                }
                .buttonStyle(.borderedProminent)
                .workspaceButton()
                .tint(AppTheme.primary)
                .controlSize(.large)
            }
            .padding(AppTheme.spacingLg)
            .frame(width: 560)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusXl)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusXl)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.24), AppTheme.surfaceElevated.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusXl)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            .shadow(color: AppTheme.cardShadow, radius: 24, x: 0, y: 12)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}
