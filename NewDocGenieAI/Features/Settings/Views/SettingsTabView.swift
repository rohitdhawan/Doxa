import SwiftUI
import StoreKit
import MessageUI

struct SettingsTabView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    @State private var showOnboardingReset = false
    @State private var showMailComposer = false
    @State private var showMailFallbackAlert = false
    @State private var supportMailSubject = ""
    @State private var supportMailBody = ""
    @Environment(\.openURL) private var openURL
    private var tipJar = TipJarService.shared
    private let supportEmail = "rohit.dhawan02@gmail.com"

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    private var storageUsed: String {
        let dir = FileStorageService.shared.appFilesDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return "0 MB" }
        var total: Int64 = 0
        for file in files {
            let path = dir.appendingPathComponent(file).path
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        return total.formattedFileSize
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // App Icon + Name
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(Color.appGradientPrimary)
                            .symbolEffect(.pulse, options: .repeating)

                        Text("Doxa")
                            .font(.appH2)
                            .foregroundStyle(Color.appText)

                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.appCaption)
                            .foregroundStyle(Color.appTextDim)
                    }
                    .padding(.top, AppSpacing.lg)

                    // Theme
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Theme", systemImage: "paintbrush")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            Picker("Appearance", selection: $themeMode) {
                                ForEach(ThemeMode.allCases, id: \.self) { mode in
                                    Label(mode.title, systemImage: mode.icon)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    if tipJar.isDonationAvailable {
                        // Support the Developer
                        AppCard(style: .glass) {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                Label("Support Doxa", systemImage: "heart.fill")
                                    .font(.appH3)
                                    .foregroundStyle(Color.appDanger)

                                Text("Need your help to continue this application. A small tip keeps development going!")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appText)

                                supportButton
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                        }
                        .padding(.horizontal, AppSpacing.md)
                    }

                    // User Guide
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("User Guide", systemImage: "book.closed")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            guideRow(
                                icon: "house.fill",
                                title: "Home",
                                detail: "Chat with Doxa and attach PDFs, photos, or scans."
                            )

                            guideRow(
                                icon: "wrench.and.screwdriver",
                                title: "Tools",
                                detail: "Open scanners, converters, OCR, and PDF tools."
                            )

                            guideRow(
                                icon: "doc.on.doc",
                                title: "Files",
                                detail: "View documents you imported or created."
                            )

                            guideRow(
                                icon: "arrow.left.arrow.right",
                                title: "Transfer",
                                detail: "Share with nearby devices running Doxa."
                            )

                            Button {
                                HapticManager.light()
                                showOnboardingReset = true
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appPrimary)
                                    Text("Replay Full Guide")
                                        .font(.appBody)
                                        .foregroundStyle(Color.appPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.appCaption)
                                        .foregroundStyle(Color.appTextDim)
                                }
                                .padding(.top, AppSpacing.xs)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // AI Status
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("AI Engine", systemImage: "brain")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            HStack {
                                let isAI = AIService.shared.isOnDeviceAIAvailable
                                Image(systemName: isAI ? "checkmark.circle.fill" : "info.circle.fill")
                                    .foregroundStyle(isAI ? Color.appSuccess : Color.appWarning)
                                Text(isAI ? "On-Device AI (Apple Intelligence)" : "Smart Keyword Matching")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextMuted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // Storage
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Storage", systemImage: "internaldrive")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            HStack {
                                Text("Documents size:")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appTextMuted)
                                Spacer()
                                Text(storageUsed)
                                    .font(.appH3)
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // Tools Summary
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Capabilities", systemImage: "wrench.and.screwdriver")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            Group {
                                capabilityRow(icon: "doc.viewfinder", text: "Document Scanner")
                                capabilityRow(icon: "doc.on.doc.fill", text: "23+ PDF, AI & Conversion Tools")
                                capabilityRow(icon: "text.viewfinder", text: "OCR Text Extraction")
                                capabilityRow(icon: "bubble.left.and.bubble.right.fill", text: "AI Document Assistant")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // About
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("About", systemImage: "info.circle")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            Text("Doxa is your all-in-one document management app. Scan, organize, edit, and convert documents with the power of on-device AI.")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // Support
                    AppCard(style: .glass) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Label("Support", systemImage: "lifepreserver")
                                .font(.appH3)
                                .foregroundStyle(Color.appText)

                            Text("Found a bug or want a new feature? Send feedback directly from the app.")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextMuted)

                            Button {
                                presentSupportMail(
                                    subject: "Doxa Bug Report",
                                    body: supportBody(prefix: "Describe the issue you found:")
                                )
                            } label: {
                                supportActionRow(
                                    icon: "ladybug.fill",
                                    title: "Report an Error",
                                    detail: "Email the issue details and what happened."
                                )
                            }
                            .buttonStyle(.plain)

                            Divider().background(Color.appBorder)

                            Button {
                                presentSupportMail(
                                    subject: "Doxa Feature Request",
                                    body: supportBody(prefix: "Describe the feature you would like to see:")
                                )
                            } label: {
                                supportActionRow(
                                    icon: "sparkles",
                                    title: "Request a Feature",
                                    detail: "Share ideas for improvements or new tools."
                                )
                            }
                            .buttonStyle(.plain)

                            Text("Support email: \(supportEmail)")
                                .font(.appCaption)
                                .foregroundStyle(Color.appTextDim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                    }
                    .padding(.horizontal, AppSpacing.md)

                    Spacer(minLength: AppSpacing.xxl)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Settings")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Replay Onboarding?", isPresented: $showOnboardingReset) {
                Button("Replay", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will show the onboarding walkthrough again.")
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    subject: supportMailSubject,
                    body: supportMailBody,
                    attachmentURL: nil,
                    onDismiss: {
                        showMailComposer = false
                    }
                )
            }
            .alert("Mail Not Available", isPresented: $showMailFallbackAlert) {
                Button("Open Mail App") {
                    openMailAppFallback()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Set up a Mail account on this device, or open the Mail app with a prefilled support email.")
            }
        }
    }

    @ViewBuilder
    private var supportButton: some View {
        switch tipJar.purchaseState {
        case .loading:
            EmptyView()

        case .ready:
            Button {
                HapticManager.light()
                Task { await tipJar.purchase() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 20))
                    Text("Donate \(tipJar.tipProduct?.displayPrice ?? "")")
                        .font(.appBody.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.appDanger.opacity(0.15))
                .foregroundStyle(Color.appDanger)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

        case .purchasing:
            HStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .tint(Color.appDanger)
                Text("Processing...")
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)

        case .success:
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appSuccess)
                Text("Thank you for your support!")
                    .font(.appBody.bold())
                    .foregroundStyle(Color.appSuccess)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .transition(.scale.combined(with: .opacity))

        case .failed(let message):
            Text(message)
                .font(.appCaption)
                .foregroundStyle(Color.appDanger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)

        case .unavailable:
            EmptyView()
        }
    }

    private func capabilityRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(Color.appAccent)
                .frame(width: 20)
            Text(text)
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
        }
    }

    private func guideRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24, height: 24)
                .background(Color.appPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appBody)
                    .foregroundStyle(Color.appText)

                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
            }

            Spacer()
        }
    }

    private func supportActionRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .frame(width: 24, height: 24)
                .background(Color.appAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: AppCornerRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appBody)
                    .foregroundStyle(Color.appText)

                Text(detail)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.appCaption)
                .foregroundStyle(Color.appTextDim)
        }
    }

    private func presentSupportMail(subject: String, body: String) {
        supportMailSubject = subject
        supportMailBody = body

        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailFallbackAlert = true
        }
    }

    private func supportBody(prefix: String) -> String {
        """
        \(prefix)



        App Version: \(appVersion) (\(buildNumber))
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
    }

    private func openMailAppFallback() {
        let encodedSubject = supportMailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = supportMailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)") else { return }
        openURL(url)
    }
}
