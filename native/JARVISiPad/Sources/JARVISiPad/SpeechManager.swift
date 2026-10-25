import AVFoundation
import Speech
import Foundation

@MainActor
final class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var status = "Готовий"

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()

    func startListening() {
        guard !isListening else { return }
        Task {
            let speechStatus = await SFSpeechRecognizer.requestAuthorization()
            guard speechStatus == .authorized else {
                status = "Дозволь розпізнавання мовлення в Налаштуваннях iPad."
                return
            }
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard granted else {
                status = "Немає дозволу на мікрофон."
                return
            }
            beginRecognition()
        }
    }

    private func beginRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizedText = ""

        let locale = Locale(identifier: "uk-UA")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            status = "Українське розпізнавання зараз недоступне."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            status = "Слухаю…"
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result {
                        self?.recognizedText = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal == true) {
                        self?.stopListening()
                    }
                }
            }
        } catch {
            status = "Не вдалося запустити мікрофон: \(error.localizedDescription)"
            stopListening()
        }
    }

    func stopListening() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isListening = false
        if status == "Слухаю…" { status = "Готовий" }
    }

    func speak(_ text: String) {
        stopListening()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "uk-UA")
        utterance.rate = 0.48
        synthesizer.speak(utterance)
    }
}
