import Speech
import AVFoundation

@MainActor
@Observable
final class SpeechRecognitionService {
    var transcribedText: String = ""
    var isRecording: Bool = false
    var isAuthorized: Bool = false
    var errorMessage: String?
    var audioLevel: Float = 0.0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var hasInstalledTap = false

    init(locale: Locale = .current) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        let speechStatus = await Self.requestSpeechRecognitionAuthorization()

        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return false
        }

        let micGranted = await Self.requestMicrophoneAuthorization()

        guard micGranted else {
            errorMessage = "Microphone access not granted."
            return false
        }

        isAuthorized = true
        return true
    }

    func startRecording() throws {
        #if targetEnvironment(simulator)
        errorMessage = "Voice input is not available in the Simulator. Please use a physical device."
        return
        #else
        guard !isRecording else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available on this device."
            return
        }

        // Reset any previous audio pipeline before starting a fresh recording session.
        cleanupAudioEngine(resetRecordingState: false)

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Guard against invalid audio format (e.g. no mic)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            errorMessage = "No microphone available. Please use a physical device."
            recognitionRequest.endAudio()
            self.recognitionRequest = nil
            return
        }

        Self.installRecognitionTap(
            on: inputNode,
            recognitionRequest: recognitionRequest,
            format: recordingFormat
        )
        hasInstalledTap = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            let bestText = result?.bestTranscription.formattedString
            let shouldCleanup = error != nil || (result?.isFinal ?? false)

            Task { @MainActor [weak self] in
                guard let self else { return }

                if let bestText {
                    self.transcribedText = bestText
                }

                if shouldCleanup {
                    self.cleanupAudioEngine()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        transcribedText = ""
        errorMessage = nil
        audioLevel = 0.35
        #endif
    }

    func stopRecording() {
        #if !targetEnvironment(simulator)
        cleanupAudioEngine()
        #endif
        isRecording = false
        audioLevel = 0
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            if !isAuthorized {
                let authorized = await requestAuthorization()
                guard authorized else { return }
            }

            do {
                try startRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func reset() {
        transcribedText = ""
        errorMessage = nil
        audioLevel = 0
    }

    nonisolated private static func requestSpeechRecognitionAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated private static func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    nonisolated private static func installRecognitionTap(
        on inputNode: AVAudioInputNode,
        recognitionRequest: SFSpeechAudioBufferRecognitionRequest,
        format: AVAudioFormat
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }
    }

    private func cleanupAudioEngine(resetRecordingState: Bool = true) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        audioLevel = 0

        if resetRecordingState {
            isRecording = false
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
