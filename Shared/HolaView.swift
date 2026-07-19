import SwiftUI

/// Hola — bite-size, Duolingo-style mini-lessons.
///
/// Walks through a sequence of exercises (multiple-choice, tap-to-build,
/// match-pairs, listen-and-choose) and shows a final score. Fully offline,
/// driven by `SeedData.lessons`.
public struct HolaView: View {
    @StateObject private var speech = SpeechSynthesizer.shared
    @State private var lessonIndex = 0
    @State private var exerciseIndex = 0
    @State private var correct = 0
    @State private var selected: String?
    @State private var taps: [String] = []
    @State private var matches: [String: String] = [:]
    @State private var showResult = false

    public init() {}

    public var body: some View {
        content
            .navigationTitle("Hola")
            .inlineTitle()
    }

    @ViewBuilder
    private var content: some View {
        if SeedData.lessons.isEmpty {
            FeatureEmptyState("No lessons",
                systemImage: "graduationcap",
                description: "Add lessons to SeedData.lessons to begin.")
        } else {
            let lesson = SeedData.lessons[lessonIndex]
            VStack(spacing: 0) {
                Picker("Lesson", selection: $lessonIndex) {
                    ForEach(Array(SeedData.lessons.enumerated()), id: \.element.id) { i, l in
                        Text("\(l.emoji) \(l.title)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: lessonIndex) { _ in resetLesson() }

                if showResult {
                    resultView(lesson)
                } else {
                    exerciseView(lesson)
                }
            }
            .onAppear { resetLesson() }
        }
    }

    @ViewBuilder
    private func exerciseView(_ lesson: Lesson) -> some View {
        let exercise = lesson.exercises[exerciseIndex]
        ScrollView {
            VStack(spacing: 20) {
                ProgressView(value: Double(exerciseIndex), total: Double(lesson.exercises.count))
                    .padding(.horizontal)
                Text(exercise.title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if case .choice(let id, let prompt, let options, let answer, let hint) = exercise {
                    choiceExercise(id: id, prompt: prompt, options: options, answer: answer, hint: hint)
                } else if case .tap(let id, let prompt, let source, let bank, let answer) = exercise {
                    tapExercise(id: id, prompt: prompt, source: source, bank: bank, answer: answer)
                } else if case .match(let id, let prompt, let pairs) = exercise {
                    matchExercise(id: id, prompt: prompt, pairs: pairs)
                } else if case .listen(let id, let prompt, let audioText, let options, let answer) = exercise {
                    listenExercise(id: id, prompt: prompt, audioText: audioText, options: options, answer: answer)
                }
            }
            .padding()
        }
    }

    // MARK: Choice

    @ViewBuilder
    private func choiceExercise(id: String, prompt: String, options: [String],
                                answer: String, hint: String) -> some View {
        Text(prompt).font(.title3.bold())
        ForEach(options, id: \.self) { opt in
            Button {
                selected = opt
                commit(answer: opt == answer, correctAnswer: answer)
            } label: {
                Text(opt)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor))
            }
            .buttonStyle(.plain)
        }
        if let selected {
            let isRight = selected == answer
            Text(isRight ? "✓ Correcto" : "💡 \(hint)")
                .foregroundStyle(isRight ? .green : .secondary)
        }
    }

    // MARK: Tap to build

    @ViewBuilder
    private func tapExercise(id: String, prompt: String, source: String,
                             bank: [String], answer: [String]) -> some View {
        Text(prompt).font(.title3.bold())
        Text(source).font(.callout).foregroundStyle(.secondary)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
            ForEach(bank, id: \.self) { word in
                Button {
                    if let idx = taps.firstIndex(of: word) {
                        taps.remove(at: idx)
                    } else {
                        taps.append(word)
                    }
                } label: {
                    Text(word)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(taps.contains(word)
                                    ? Color.accentColor.opacity(0.25)
                                    : RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.4)))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        Button("Check") {
            let ok = taps == answer
            commit(answer: ok, correctAnswer: answer.joined(separator: " "))
        }
        .buttonStyle(.borderedProminent)
        .disabled(taps.isEmpty)
    }

    // MARK: Match pairs

    @ViewBuilder
    private func matchExercise(id: String, prompt: String, pairs: [MatchPair]) -> some View {
        Text(prompt).font(.title3.bold())
        let es = pairs.map(\.es)
        let en = pairs.map(\.en)
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 10) {
                ForEach(es, id: \.self) { word in
                    Text(word).font(.headline)
                }
            }
            VStack(spacing: 10) {
                ForEach(en, id: \.self) { word in
                    Picker("", selection: Binding(
                        get: { matches[word] ?? "" },
                        set: { matches[word] = $0 }
                    )) {
                        Text("—").tag("")
                        ForEach(es, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 160)
                }
            }
        }
        Button("Check") {
            let ok = pairs.allSatisfy { matches[$0.en] == $0.es }
            commit(answer: ok, correctAnswer: "all matched")
        }
        .buttonStyle(.borderedProminent)
        .disabled(matches.count < pairs.count)
    }

    // MARK: Listen

    @ViewBuilder
    private func listenExercise(id: String, prompt: String, audioText: String,
                                options: [String], answer: String) -> some View {
        Text(prompt).font(.title3.bold())
        Button { speech.speak(audioText) } label: {
            Label("Play audio", systemImage: "speaker.wave.2.fill")
                .font(.title2)
        }
        .buttonStyle(.borderedProminent)
        ForEach(options, id: \.self) { opt in
            Button {
                selected = opt
                commit(answer: opt == answer, correctAnswer: answer)
            } label: {
                Text(opt).frame(maxWidth: .infinity).padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Result + flow

    @ViewBuilder
    private func resultView(_ lesson: Lesson) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill").font(.system(size: 50)).foregroundStyle(.yellow)
            Text("Lesson complete!").font(.title2.bold())
            Text("\(correct) / \(lesson.exercises.count) correct")
                .font(.title3)
            Button("Try again") { resetLesson() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func commit(answer ok: Bool, correctAnswer: String) {
        if ok { correct += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            advanceOrFinish()
        }
    }

    private func advanceOrFinish() {
        let lesson = SeedData.lessons[lessonIndex]
        selected = nil
        taps = []
        matches = [:]
        if exerciseIndex + 1 < lesson.exercises.count {
            exerciseIndex += 1
        } else {
            showResult = true
        }
    }

    private func resetLesson() {
        exerciseIndex = 0
        correct = 0
        selected = nil
        taps = []
        matches = [:]
        showResult = false
    }
}
