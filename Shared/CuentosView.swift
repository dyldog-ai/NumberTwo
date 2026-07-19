import SwiftUI

/// Cuentos — a graded, tappable Spanish story reader.
///
/// Shows a short A1/A2 story sentence by sentence. Each Spanish sentence is
/// tappable to reveal its English translation and to hear it spoken aloud.
/// Driven by `SeedData.stories`.
public struct CuentosView: View {
    @StateObject private var speech = SpeechSynthesizer.shared
    @State private var storyIndex = 0
    @State private var revealed: Set<String> = []

    public init() {}

    public var body: some View {
        content
            .navigationTitle("Cuentos")
            .inlineTitle()
    }

    @ViewBuilder
    private var content: some View {
        if SeedData.stories.isEmpty {
            FeatureEmptyState("No stories",
                systemImage: "book",
                description: "Add stories to SeedData.stories to begin.")
        } else {
            let story = SeedData.stories[storyIndex]
            VStack(spacing: 0) {
                Picker("Story", selection: $storyIndex) {
                    ForEach(Array(SeedData.stories.enumerated()), id: \.element.id) { i, s in
                        Text("\(s.title) (\(s.level))").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: storyIndex) { _ in revealed.removeAll() }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(story.sentences) { sentence in
                            sentenceRow(sentence)
                        }
                    }
                    .padding()
                }
                Button {
                    revealed = Set(SeedData.stories[storyIndex].sentences.map(\.id))
                } label: {
                    Label("Reveal all", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }

    private func sentenceRow(_ sentence: StorySentence) -> some View {
        let isOpen = revealed.contains(sentence.id)
        return Button {
            if isOpen {
                speech.speak(sentence.es)
            } else {
                revealed.insert(sentence.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "speaker.wave.2")
                    .foregroundStyle(Color(hex: "#C780FA"))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(sentence.es)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if isOpen {
                        Text(sentence.en)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap to reveal translation")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "#C780FA").opacity(isOpen ? 0.12 : 0.06))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(sentence.es). \(isOpen ? sentence.en : "Translation hidden")")
    }
}
