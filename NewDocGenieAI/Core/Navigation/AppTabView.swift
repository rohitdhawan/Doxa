import SwiftUI

struct AppTabView: View {
    @State private var router = NavigationRouter()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastWhatsNewVersion") private var lastWhatsNewVersion = ""
    @AppStorage("themeMode") private var themeModeRaw = "system"
    @State private var showSplash = true
    @State private var showWhatsNew = false
    @State private var whatsNewFeatures: [WhatsNewFeature] = []

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    private var splashBackgroundColor: Color {
        Color(red: 13.0 / 255.0, green: 17.0 / 255.0, blue: 23.0 / 255.0)
    }

    private var splashBlue: Color {
        Color(red: 95.0 / 255.0, green: 149.0 / 255.0, blue: 216.0 / 255.0)
    }

    private var splashWarmGray: Color {
        Color(red: 201.0 / 255.0, green: 188.0 / 255.0, blue: 157.0 / 255.0)
    }

    private var splashAmber: Color {
        Color(red: 240.0 / 255.0, green: 169.0 / 255.0, blue: 58.0 / 255.0)
    }

    private var splashIconGray: Color {
        Color(red: 167.0 / 255.0, green: 173.0 / 255.0, blue: 183.0 / 255.0)
    }

    var body: some View {
        ZStack {
            splashBackgroundColor
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

            if showSplash {
                splashOverlay
            }
        }
        .preferredColorScheme(themeMode.colorScheme)
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
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

    private var splashOverlay: some View {
        ZStack {
            splashBackgroundColor
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 190
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 32)
                .offset(y: -8)

            VStack(spacing: AppSpacing.lg) {
                splashMark

                Text("Doxa")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text("Your AI Document Assistant")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.34))
            }
            .offset(y: 18)
        }
        .transition(.opacity)
    }

    private var splashMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appPrimary.opacity(0.08))
                .frame(width: 116, height: 116)
                .blur(radius: 18)

            ZStack {
                splashCorner(stroke: splashBlue, rotation: .degrees(0))
                    .offset(x: -24, y: -24)

                splashCorner(stroke: splashWarmGray, rotation: .degrees(90))
                    .offset(x: 24, y: -24)

                splashCorner(stroke: splashWarmGray, rotation: .degrees(180))
                    .offset(x: -24, y: 24)

                splashCorner(stroke: splashAmber, rotation: .degrees(270))
                    .offset(x: 24, y: 24)

                Image(systemName: "document")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(splashIconGray)
            }
            .symbolEffect(.pulse, options: .repeating)
        }
        .frame(width: 120, height: 120)
        .scaleEffect(showSplash ? 1.0 : 0.94)
    }

    private func splashCorner(stroke: Color, rotation: Angle) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(stroke)
                .frame(width: 20, height: 5)

            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(stroke)
                    .frame(width: 5, height: 20)
                Spacer(minLength: 0)
            }
        }
        .frame(width: 24, height: 24)
        .rotationEffect(rotation)
    }
}
