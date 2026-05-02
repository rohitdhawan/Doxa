import SwiftUI
import SwiftData
import MessageUI

struct EmailPDFView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFiles: [DocumentFile] = []
    @State private var showPicker = false
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var showMailComposer = false
    @State private var shareItem: ShareItem?
    @State private var isGenerating = false

    private var selectedFile: DocumentFile? { selectedFiles.first }
    private var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Select PDF") {
                    Button { showPicker = true } label: {
                        if let file = selectedFile {
                            HStack {
                                FileTypeIcon(fileExtension: "pdf")
                                Text(file.fullFileName).font(.appBody).lineLimit(1)
                            }
                        } else {
                            Label("Choose a PDF", systemImage: "doc.richtext").font(.appBody)
                        }
                    }
                }

                if selectedFile != nil {
                    Section("Email Details") {
                        TextField("Subject", text: $emailSubject)
                            .font(.appBody)
                        TextEditor(text: $emailBody)
                            .font(.appBody)
                            .frame(minHeight: 80)

                        if AIService.shared.isOnDeviceAIAvailable {
                            Button {
                                generateDescription()
                            } label: {
                                HStack {
                                    if isGenerating {
                                        ProgressView().controlSize(.small)
                                    }
                                    Text("Generate with AI")
                                }
                            }
                            .font(.appCaption)
                            .disabled(isGenerating)
                        }
                    }

                    if canSendMail {
                        Section {
                            Button {
                                HapticManager.medium()
                                showMailComposer = true
                            } label: {
                                Label("Send Email", systemImage: "envelope")
                                    .font(.appBody)
                                    .foregroundStyle(Color.appPrimary)
                            }
                            .disabled(emailSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Section {
                            Label("Mail not configured on this device", systemImage: "exclamationmark.triangle")
                                .font(.appCaption).foregroundStyle(Color.appWarning)
                            Button("Share via...") {
                                if let url = selectedFile?.fileURL {
                                    shareItem = ShareItem(url: url)
                                }
                            }
                            .font(.appBody)
                        }
                    }
                }
            }
            .navigationTitle("Email PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showPicker) {
                PDFFilePickerView(title: "Select PDF", allowsMultiple: false, selectedFiles: $selectedFiles)
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    subject: emailSubject,
                    body: emailBody,
                    attachmentURL: selectedFile?.fileURL,
                    onDismiss: { showMailComposer = false; dismiss() }
                )
            }
            .sheet(item: $shareItem) { item in
                ActivityView(activityItems: [item.url])
            }
            .onChange(of: selectedFiles) { _, _ in
                if let file = selectedFile {
                    emailSubject = file.name
                    emailBody = "Please find the attached document."
                }
            }
        }
    }

    private func generateDescription() {
        guard let url = selectedFile?.fileURL else { return }
        isGenerating = true
        Task {
            do {
                let text = try await OCRService.shared.extractText(from: url)
                let prompt = "Write a brief 1-2 sentence email description for sharing this document. Just the description, no subject line:\n\n\(String(text.prefix(1000)))"
                let response = try await AIService.shared.generateResponse(for: prompt, conversationHistory: [])
                emailBody = response.text
            } catch {
                emailBody = "Please find the attached document."
            }
            isGenerating = false
        }
    }
}
