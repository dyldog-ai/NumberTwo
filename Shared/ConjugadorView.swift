import SwiftUI

/// Conjugador — a verb conjugation drill.
///
/// Picks a random verb + tense + person, asks the learner to type the form,
/// and gives immediate feedback against the pre-computed correct answer.
/// Covers 21 high-frequency verbs × 4 tenses × 6 persons.
public struct ConjugadorView: View {
    @StateObject private var speech = SpeechSynthesizer.shared
    @State private var question = Question(verb: SeedData.verbs[0], tense: .present, person: .yo)
    @State private var answer = ""
    @State private var feedback: Feedback = .idle
    @State private var streak = 0
    @State private var attempts = 0

    public init() {}

    public var body: some View {
        content
            .navigationTitle("Conjugador")
            .inlineTitle()
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 24) {
            HStack {
                Label("Streak: \(streak)", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Label("\(attempts) done", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal)

            VStack(spacing: 8) {
                Text(question.verb.inf)
                    .font(.system(size: 44, weight: .bold))
                Text(question.verb.en)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Pill(text: question.tense.label)
                    Pill(text: question.person.label)
                }
            }
            .padding()
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "#6BCB77").opacity(0.12))
            )

            HStack {
                TextField("Type the conjugation…", text: $answer)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    #endif
                    .onSubmit { check() }
                Button(action: check) { Image(systemName: "checkmark") }
                    .disabled(answer.isEmpty)
            }
            .padding(.horizontal)

            feedbackView
                .frame(minHeight: 48)

            Spacer()
        }
        .padding(.top)
        .onAppear(perform: next)
    }

    @ViewBuilder
    private var feedbackView: some View {
        switch feedback {
        case .idle:
            EmptyView()
        case .correct:
            Label("¡Correcto!", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .wrong(let correct):
            VStack(spacing: 2) {
                Label("Not quite — it's \"\(correct)\"", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Button { speech.speak(correct) } label: { Label("Listen", systemImage: "speaker.wave.2") }
                    .font(.caption)
            }
        }
    }

    // MARK: - Logic

    private func check() {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        attempts += 1
        let correct = question.verb.form(question.tense, question.person)
        if trimmed.localizedLowercase == correct.localizedLowercase {
            feedback = .correct
            streak += 1
        } else {
            feedback = .wrong(correct)
            streak = 0
        }
        answer = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation { next() }
        }
    }

    private func next() {
        feedback = .idle
        guard let verb = SeedData.verbs.randomElement() else { return }
        let tense = Tense.allCases.randomElement()!
        let person = Person.allCases.randomElement()!
        question = Question(verb: verb, tense: tense, person: person)
        speech.speak(verb.inf)
    }

    // MARK: - Types

    struct Question {
        let verb: SpanishVerb
        let tense: Tense
        let person: Person
    }

    enum Feedback {
        case idle, correct, wrong(String)
    }

    struct Pill: View {
        let text: String
        var body: some View {
            Text(text)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "#6BCB77").opacity(0.25)))
                .foregroundStyle(Color(hex: "#3a9d4a"))
        }
    }
}
