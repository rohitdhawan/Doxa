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

    init(locale: Locale = .current) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return false
        }

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

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
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available on this device."
            return
        }

        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

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

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level from buffer
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frames = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frames {
                sum += abs(channelData[i])
            }
            let avg = sum / Float(max(frames, 1))
            let normalized = min(avg * 10, 1.0) // Normalize to 0-1

            Task { @MainActor [weak self] in
                self?.audioLevel = normalized
            }
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.cleanupAudioEngine()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        transcribedText = ""
        errorMessage = nil
        #endif
    }

    func stopRecording() {
        #if !targetEnvironment(simulator)
        cleanupAudioEngine()
        #endif
        isRecording = false
        audioLevel = 0
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task {
                if !isAuthorized {
                    let authorized = await requestAuthorization()
                    guard authorized else { return }
                }
                try? startRecording()
            }
        }
    }

    func reset() {
        transcribedText = ""
        errorMessage = nil
        audioLevel = 0
    }

    private func cleanupAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
