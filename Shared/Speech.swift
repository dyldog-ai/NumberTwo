import AVFoundation

/// A tiny wrapper around `AVSpeechSynthesizer` for speaking Spanish text
/// with a Castilian/Latin-American Spanish voice. Used by every feature so
/// learners can hear correct pronunciation.
///
/// Safe to use from SwiftUI views; it is an `ObservableObject` so callers can
/// observe `isSpeaking` if they want to toggle a button state.
public final class SpeechSynthesizer: ObservableObject {
    public static let shared = SpeechSynthesizer()

    private let synth = AVSpeechSynthesizer()

    @Published public private(set) var isSpeaking = false

    public init() {}

    /// Speak a piece of Spanish text aloud.
    /// - Parameter text: The phrase to pronounce.
    public func speak(_ text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
            ?? AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = AVSpeechUtteranceDefaultRate * 0.9
        utterance.pitchMultiplier = 1.0
        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }

    /// Stop any in-progress speech.
    public func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
