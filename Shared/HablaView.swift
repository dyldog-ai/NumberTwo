import SwiftUI

/// Habla — an offline, rule-based Spanish conversation coach.
///
/// Presents a scripted scenario (ordering coffee, buying a ticket, checking
/// into a hotel). The bot speaks in Spanish; the learner types a reply. A
/// simple keyword matcher accepts any expected phrase, then the coach gives
/// friendly feedback and advances. No network required.
public struct HablaView: View {
    @StateObject private var speech = SpeechSynthesizer.shared
    @State private var scenarioIndex = 0
    @State private var turnIndex = 0
    @State private var reply = ""
    @State private var log: [ChatLine] = []
    @State private var done = false

    public init() {}

    public var body: some View {
        content
            .navigationTitle("Habla")
            .inlineTitle()
    }

    @ViewBuilder
    private var content: some View {
        if SeedData.scenarios.isEmpty {
            FeatureEmptyState("No scenarios",
                systemImage: "bubble.left.and.bubble.right",
                description: "Add scenarios to SeedData.scenarios to begin.")
        } else {
            let scenario = SeedData.scenarios[scenarioIndex]
            VStack(spacing: 0) {
                pickerBar(scenario)
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(log) { line in
                                bubble(line)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: log.count) { _ in
                        if let last = log.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                Divider()
                composer(scenario)
            }
            .onAppear { startIfNeeded(scenario) }
        }
    }

    @ViewBuilder
    private func pickerBar(_ scenario: Scenario) -> some View {
        Picker("Scenario", selection: $scenarioIndex) {
            ForEach(Array(SeedData.scenarios.enumerated()), id: \.element.id) { i, s in
                Text(s.title).tag(i)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: scenarioIndex) { _ in
            turnIndex = 0
            log = []
            done = false
            startIfNeeded(SeedData.scenarios[scenarioIndex])
        }

        // Helpful vocabulary chips for the active scenario.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scenario.vocab) { word in
                    Button {
                        speech.speak(word.es)
                    } label: {
                        VStack(spacing: 2) {
                            Text(word.es).font(.caption.bold())
                            Text(word.en).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#4D96FF").opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func bubble(_ line: ChatLine) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if line.role == .user {
                Spacer(minLength: 40)
            }
            VStack(alignment: line.role == .user ? .trailing : .leading, spacing: 3) {
                Text(line.text)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(line.role == .user ? Color.accentColor : Color.secondary.opacity(0.18))
                    )
                    .foregroundStyle(line.role == .user ? Color.white : Color.primary)
                if !line.note.isEmpty {
                    Text(line.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 280, alignment: line.role == .user ? .trailing : .leading)
                }
            }
            if line.role == .bot {
                Spacer(minLength: 40)
            }
        }
        .id(line.id)
    }

    private func composer(_ scenario: Scenario) -> some View {
        VStack(spacing: 8) {
            if done {
                Button {
                    restart(scenario)
                } label: {
                    Label("Start over", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            } else {
                HStack {
                    TextField("Your reply in Spanish…", text: $reply)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        #endif
                        .onSubmit { submit(scenario) }
                    Button(action: { submit(scenario) }) {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(reply.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Logic

    private func startIfNeeded(_ scenario: Scenario) {
        guard log.isEmpty else { return }
        log.append(.init(role: .bot, text: scenario.introEs, note: scenario.introEn))
        pushTurn(scenario.turns.first)
    }

    private func pushTurn(_ turn: ScenarioTurn?) {
        guard let turn else {
            let scenario = SeedData.scenarios[scenarioIndex]
            log.append(.init(role: .bot, text: scenario.outroEs, note: scenario.outroEn))
            done = true
            return
        }
        log.append(.init(role: .bot, text: turn.botEs, note: turn.botEn))
        speech.speak(turn.botEs)
    }

    private func submit(_ scenario: Scenario) {
        let raw = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        log.append(.init(role: .user, text: raw, note: ""))
        reply = ""

        let turn = scenario.turns[turnIndex]
        let accepted = turn.expects.contains { expect in
            raw.localizedLowercase.contains(expect.localizedLowercase)
        }
        log.append(.init(role: .bot, text: accepted ? turn.coachEn : turn.hintEs,
                         note: accepted ? "✓ Nice!" : "💡 Hint"))
        if accepted {
            turnIndex += 1
            pushTurn(scenario.turns[safe: turnIndex])
        }
    }

    private func restart(_ scenario: Scenario) {
        turnIndex = 0
        log = []
        done = false
        startIfNeeded(scenario)
    }
}

// MARK: - Helpers

struct ChatLine: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    let note: String

    enum Role { case bot, user }
}

extension Collection {
    /// Safe subscript that returns nil for out-of-range indices.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
