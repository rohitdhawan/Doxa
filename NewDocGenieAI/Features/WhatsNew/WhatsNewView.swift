import SwiftUI

struct WhatsNewFeature: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct WhatsNewView: View {
    let version: String
    let features: [WhatsNewFeature]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppSpacing.sm) {
                Text("What's New")
                    .font(.appH1)
                    .foregroundStyle(Color.appText)

                Text("Version \(version)")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextDim)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.appBGCard, in: Capsule())
            }
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        featureRow(feature)
                            .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }

            Spacer()

            PrimaryButton(title: "Continue", icon: "arrow.right") {
                onDismiss()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(Color.appBGDark)
    }

    private func featureRow(_ feature: WhatsNewFeature) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            GlowingIcon(
                systemName: feature.icon,
                color: feature.iconColor,
                size: 20,
                bgSize: 40
            )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(feature.title)
                    .font(.appH3)
                    .foregroundStyle(Color.appText)

                Text(feature.description)
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .glassCard()
    }
}

// MARK: - Version Data

enum WhatsNewData {
    static func features(for version: String) -> [WhatsNewFeature]? {
        switch version {
        case "1.1":
            return [
                WhatsNewFeature(
                    icon: "brain",
                    iconColor: .appPrimary,
                    title: "AI Tools Suite",
                    description: "Summarize PDFs, ask questions about documents, and translate content using on-device AI."
                ),
                WhatsNewFeature(
                    icon: "signature",
                    iconColor: .appDanger,
                    title: "Sign Documents",
                    description: "Draw your signature and apply it to any PDF. No third-party tools needed."
                ),
                WhatsNewFeature(
                    icon: "crop",
                    iconColor: .appWarning,
                    title: "Crop & Metadata Tools",
                    description: "Crop PDF margins and edit document metadata directly on your device."
                ),
                WhatsNewFeature(
                    icon: "lightbulb",
                    iconColor: .appAccent,
                    title: "Smart Tips",
                    description: "Contextual hints help you discover tools as you use the app."
                ),
            ]
        default:
            return nil
        }
    }
}
