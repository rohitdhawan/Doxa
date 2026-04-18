import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let attachmentURL: URL?
    let onDismiss: @MainActor () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)

        if let url = attachmentURL, let data = try? Data(contentsOf: url) {
            let mimeType = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "application/octet-stream"
            vc.addAttachmentData(data, mimeType: mimeType, fileName: url.lastPathComponent)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: @MainActor () -> Void
        init(onDismiss: @MainActor @escaping () -> Void) { self.onDismiss = onDismiss }

        nonisolated func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let callback = onDismiss
            Task { @MainActor in
                callback()
            }
        }
    }
}
