import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.viewfinder",
            title: "Scan & Digitize",
            description: "Scan documents with your camera. Smart edge detection and auto-enhancement create crisp results instantly.",
            gradient: [Color.appAccent, Color.appPrimary],
            badges: ["Auto-Detect Edges", "Multi-Page", "PDF Export"],
            guideItems: [
                GuideItem(icon: "doc.viewfinder", title: "Open Tools", detail: "Use the Scanner to capture pages."),
                GuideItem(icon: "square.and.arrow.down", title: "Save Scan", detail: "Your PDF is stored automatically in Files.")
            ]
        ),
        OnboardingPage(
            icon: "wrench.and.screwdriver",
            title: "23+ Professional Tools",
            description: "Merge, split, compress, sign, watermark, and convert — all on your device, no cloud needed.",
            gradient: [Color.appPrimary, Color.appPrimaryLight],
            badges: ["PDF Tools", "AI Tools", "Converters"],
            guideItems: [
                GuideItem(icon: "wrench.and.screwdriver", title: "Choose a Tool", detail: "Merge, split, lock, sign, crop, OCR, and more."),
                GuideItem(icon: "iphone.gen3", title: "Pick From Device", detail: "Import PDFs directly from your iPhone or Files app.")
            ]
        ),
        OnboardingPage(
            icon: "brain",
            title: "AI-Powered Assistant",
            description: "Summarize PDFs, ask questions about documents, and translate content with on-device AI.",
            gradient: [Color.appSuccess, Color.appAccent],
            badges: ["Summarize", "Ask PDF", "Translate"],
            guideItems: [
                GuideItem(icon: "house.fill", title: "Open Home", detail: "Ask Doxa to scan, convert, summarize, or find tools for you."),
                GuideItem(icon: "paperclip", title: "Attach a File", detail: "Add a PDF, photo, or scan before asking a question.")
            ]
        ),
        OnboardingPage(
            icon: "list.bullet.rectangle",
            title: "How To Use Doxa",
            description: "A quick guide to the main tabs so first-time users know exactly where to start.",
            gradient: [Color.appPrimaryLight, Color.appSuccess],
            badges: ["Home", "Tools", "Files", "Transfer"],
            guideItems: [
                GuideItem(icon: "house.fill", title: "Home", detail: "Chat with Doxa and attach documents."),
                GuideItem(icon: "wrench.and.screwdriver", title: "Tools", detail: "Open scanners, converters, and PDF tools."),
                GuideItem(icon: "doc.on.doc", title: "Files", detail: "View everything you imported or created."),
                GuideItem(icon: "arrow.left.arrow.right", title: "Transfer", detail: "Share with nearby devices running Doxa.")
            ]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: AppSpacing.lg) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.appPrimary : Color.appTextDim.opacity(0.4))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                Button {
                    HapticManager.medium()
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.appH3)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appGradientPrimary, in: RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, AppSpacing.xl)

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextMuted)
                }
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(
            ZStack {
                Color.appBackground
                AnimatedGradientView(
                    colors: pages[currentPage].gradient.map { $0.opacity(0.06) } + [.clear]
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private func pageView(_ page: OnboardingPage, index: Int) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            // Icon with layered glow rings
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.gradient.first!.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Inner gradient circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { $0.opacity(0.25) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: page.gradient.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)

            Text(page.title)
                .font(.appH1)
                .foregroundStyle(Color.appText)

            Text(page.description)
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
                .lineSpacing(4)

            // Feature badges
            HStack(spacing: AppSpacing.sm) {
                ForEach(page.badges, id: \.self) { badge in
                    Text(badge)
                        .font(.appMicro)
                        .foregroundStyle(page.gradient.first ?? Color.appPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            (page.gradient.first ?? Color.appPrimary).opacity(0.12),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    (page.gradient.first ?? Color.appPrimary).opacity(0.2),
                                    lineWidth: 0.5
                                )
                        )
                    }
            }

            if !page.guideItems.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(page.guideItems) { item in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(page.gradient.first ?? Color.appPrimary)
                                .frame(width: 32, height: 32)
                                .background(
                                    (page.gradient.first ?? Color.appPrimary).opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.appBody)
                                    .foregroundStyle(Color.appText)

                                Text(item.detail)
                                    .font(.appCaption)
                                    .foregroundStyle(Color.appTextMuted)
                            }

                            Spacer()
                        }
                        .padding(AppSpacing.md)
                        .background(Color.appBGCard, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                                .stroke(Color.appBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let badges: [String]
    let guideItems: [GuideItem]
}

private struct GuideItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}
