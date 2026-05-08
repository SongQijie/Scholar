import SwiftUI

@main
struct ScholarApp: App {
    @StateObject private var store = AppDataStore.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if store.hasSelectedWorkspace {
                    MainContentView()
                } else {
                    WorkspaceSelectionView()
                }
            }
            .environmentObject(store)
            .onAppear {
                store.prepareForTextInput()
            }
            .frame(minWidth: 980, idealWidth: 1280, minHeight: 720, idealHeight: 900)
        }
        .defaultSize(width: 1280, height: 900)
        .windowResizability(.contentSize)
    }
}
