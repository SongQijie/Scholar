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
            .background(FullScreenWindowChromeAdapter())
            .onAppear {
                store.prepareForTextInput()
            }
            .frame(minWidth: 1280, idealWidth: 1320, minHeight: 720, idealHeight: 900)
        }
        .defaultSize(width: 1320, height: 900)
        .windowResizability(.automatic)
    }
}

private struct FullScreenWindowChromeAdapter: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowChromeView {
        WindowChromeView()
    }

    func updateNSView(_ nsView: WindowChromeView, context: Context) {
        nsView.refreshWindowAttachment()
    }
}

private final class WindowChromeView: NSView {
    private weak var observedWindow: NSWindow?
    private var originalStyleMask: NSWindow.StyleMask?
    private var originalTitleVisibility: NSWindow.TitleVisibility?
    private var originalTitlebarAppearsTransparent: Bool?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshWindowAttachment()
    }

    deinit {
        removeObservers()
    }

    func refreshWindowAttachment() {
        guard observedWindow !== window else { return }
        removeObservers()
        observedWindow = window

        guard let window else { return }
        originalStyleMask = window.styleMask
        originalTitleVisibility = window.titleVisibility
        originalTitlebarAppearsTransparent = window.titlebarAppearsTransparent

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyChromeForCurrentWindowMode),
            name: NSWindow.didEnterFullScreenNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyChromeForCurrentWindowMode),
            name: NSWindow.didExitFullScreenNotification,
            object: window
        )

        applyChromeForCurrentWindowMode()
    }

    private func removeObservers() {
        if let observedWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didEnterFullScreenNotification, object: observedWindow)
            NotificationCenter.default.removeObserver(self, name: NSWindow.didExitFullScreenNotification, object: observedWindow)
        }
    }

    @objc private func applyChromeForCurrentWindowMode() {
        guard let window = observedWindow else { return }

        if window.styleMask.contains(.fullScreen) {
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
        } else {
            if let originalStyleMask {
                window.styleMask = originalStyleMask
            }
            if let originalTitlebarAppearsTransparent {
                window.titlebarAppearsTransparent = originalTitlebarAppearsTransparent
            }
            if let originalTitleVisibility {
                window.titleVisibility = originalTitleVisibility
            }
        }
    }
}
