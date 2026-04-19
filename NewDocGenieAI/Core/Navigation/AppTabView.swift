import SwiftUI

struct AppTabView: View {
    @State private var router = NavigationRouter()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastWhatsNewVersion") private var lastWhatsNewVersion = ""
    @AppStorage("themeMode") private var themeModeRaw = "system"
    @State private var showWhatsNew = false
    @State private var whatsNewFeatures: [WhatsNewFeature] = []

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some View {
        ZStack {
            Color(red: 13.0 / 255.0, green: 17.0 / 255.0, blue: 23.0 / 255.0)
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                tabContent
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                        lastWhatsNewVersion = appVersion
                    }
                }
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .task {
            if hasCompletedOnboarding && lastWhatsNewVersion != appVersion {
                if let features = WhatsNewData.features(for: appVersion) {
                    whatsNewFeatures = features
                    try? await Task.sleep(for: .seconds(0.5))
                    showWhatsNew = true
                } else {
                    lastWhatsNewVersion = appVersion
                }
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView(version: appVersion, features: whatsNewFeatures) {
                lastWhatsNewVersion = appVersion
                showWhatsNew = false
            }
            .presentationCornerRadius(24)
            .presentationBackground(Color.appBackground)
            .interactiveDismissDisabled()
        }
    }

    private var tabContent: some View {
        TabView(selection: Binding(
            get: { router.selectedTab },
            set: { newTab in
                if router.selectedTab == newTab {
                    router.resetCurrentTab()
                } else {
                    HapticManager.selection()
                    router.selectedTab = newTab
                }
            }
        )) {
            ChatTabView()
                .tabItem {
                    Label(AppTab.chat.title, systemImage: AppTab.chat.systemImage)
                }
                .tag(AppTab.chat)

            ToolsTabView()
                .tabItem {
                    Label(AppTab.tools.title, systemImage: AppTab.tools.systemImage)
                }
                .tag(AppTab.tools)

            FilesTabView()
                .tabItem {
                    Label(AppTab.files.title, systemImage: AppTab.files.systemImage)
                }
                .tag(AppTab.files)

            TransferTabView()
                .tabItem {
                    Label(AppTab.transfer.title, systemImage: AppTab.transfer.systemImage)
                }
                .tag(AppTab.transfer)

            SettingsTabView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage)
                }
                .tag(AppTab.settings)
        }
        .tint(Color.appPrimary)
        .environment(router)
        .onOpenURL { url in
            handleIncomingFile(url: url)
        }
        .fullScreenCover(isPresented: $router.showIncomingPDF) {
            if let url = router.incomingPDFURL {
                PDFViewerToolView(initialURL: url)
            }
        }
    }

    /// Handle files opened from other apps via "Open In" / Share Sheet
    private func handleIncomingFile(url: URL) {
        let ext = url.pathExtension.lowercased()

        if ext == "pdf" {
            // Copy to app sandbox so it persists
            let fileManager = FileManager.default
            let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let inboxDir = docsDir.appendingPathComponent("Inbox", isDirectory: true)

            // Create Inbox directory if needed
            try? fileManager.createDirectory(at: inboxDir, withIntermediateDirectories: true)

            // Access security-scoped resource
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }

            // Copy file to app's Documents directory
            let destURL = docsDir.appendingPathComponent(url.lastPathComponent)
            let finalURL: URL
            if fileManager.fileExists(atPath: destURL.path) {
                // If file already exists, use a unique name
                let baseName = url.deletingPathExtension().lastPathComponent
                let uniqueName = "\(baseName)_\(Int(Date().timeIntervalSince1970)).pdf"
                finalURL = docsDir.appendingPathComponent(uniqueName)
            } else {
                finalURL = destURL
            }

            do {
                try fileManager.copyItem(at: url, to: finalURL)
                router.openIncomingPDF(url: finalURL)
            } catch {
                // If copy fails, try opening directly
                router.openIncomingPDF(url: url)
            }
        }
    }
}
