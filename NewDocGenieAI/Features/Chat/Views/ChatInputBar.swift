import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isInputFocused: FocusState<Bool>.Binding
    let isTyping: Bool
    let pendingAttachment: PendingAttachment?
    let isRecording: Bool
    let audioLevel: Float
    let onSend: () -> Void
    let onAttachTapped: () -> Void
    let onVoiceToggle: () -> Void
    let onRemoveAttachment: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Attachment preview strip
            if let attachment = pendingAttachment {
                AttachmentPreviewStrip(
                    attachment: attachment,
                    onRemove: onRemoveAttachment
                )
                .padding(.bottom, AppSpacing.xs)
            }

            // Main input row
            HStack(spacing: AppSpacing.sm) {
                // Attachment button
                Button {
                    HapticManager.light()
                    onAttachTapped()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.appPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 4)
                }
                .buttonStyle(.scale)
                .accessibilityLabel("Attach file")
                .accessibilityHint("Double tap to choose a file, photo, or scan")

                // Text field
                TextField("Ask Doxa...", text: $text, axis: .vertical)
                    .font(.appBody)
                    .lineLimit(1...4)
                    .focused(isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend && !isTyping {
                            onSend()
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .glassCard(cornerRadius: AppCornerRadius.lg)

                // Voice / Send toggle
                if canSend || isTyping {
                    // Send button
                    Button {
                        HapticManager.medium()
                        onSend()
                    } label: {
                        Image(systemName: isTyping ? "ellipsis.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? Color.appPrimary : Color.appTextDim)
                            .shadow(color: canSend ? Color.appPrimary.opacity(0.4) : .clear, radius: 8)
                    }
                    .disabled(!canSend || isTyping)
                    .accessibilityLabel("Send message")
                    .accessibilityHint(canSend ? "Double tap to send" : "Type a message first")
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Mic button
                    if isRecording {
                        VoicePulseView(audioLevel: audioLevel)
                            .onTapGesture {
                                HapticManager.medium()
                                onVoiceToggle()
                            }
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityLabel("Stop recording")
                    } else {
                        Button {
                            HapticManager.light()
                            onVoiceToggle()
                        } label: {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.scale)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Voice input")
                        .accessibilityHint("Double tap to start dictation")
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(Color.appBGDark)
        .animation(AppAnimations.springQuick, value: canSend)
        .animation(AppAnimations.springQuick, value: isRecording)
        .animation(AppAnimations.springSmooth, value: pendingAttachment != nil)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingAttachment != nil
    }
}
