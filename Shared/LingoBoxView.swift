import SwiftUI

/// LingoBox — a spaced-repetition style flashcard trainer.
///
/// Shows the Spanish side of a card, lets the learner flip to reveal the
/// English translation and an example sentence, hear it pronounced, then move
/// on. Lives in the core so it runs on both iOS and macOS.
public struct LingoBoxView: View {
    @StateObject private var speech = SpeechSynthesizer.shared
    @State private var index = 0
    @State private var flipped = false

    private let cards = SeedData.flashcards

    public init() {}

    public var body: some View {
        content
            .navigationTitle("LingoBox")
            .inlineTitle()
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !cards.isEmpty {
                        Text("\(index + 1)/\(cards.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                #endif
            }
    }

    @ViewBuilder
    private var content: some View {
        if cards.isEmpty {
            emptyState
        } else {
            let card = cards[index]
            VStack(spacing: 24) {
                Spacer()
                cardFace(card)
                controls
                Spacer()
            }
            .padding()
        }
    }

    private var emptyState: some View {
        FeatureEmptyState("No flashcards yet",
            systemImage: "rectangle.stack",
            description: "Add cards to SeedData.flashcards to begin.")
    }

    private func cardFace(_ card: Flashcard) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                flipped.toggle()
            }
        } label: {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(flipped ? Color.accentColor.opacity(0.15) : Color(hex: "#FF6B6B").opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(flipped ? Color.accentColor.opacity(0.5) : Color(hex: "#FF6B6B").opacity(0.5),
                                lineWidth: 1.5)
                )
                .overlay(
                    VStack(spacing: 12) {
                        Text(flipped ? card.en : card.es)
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                        if flipped {
                            Text(card.example)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Tap to flip")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                )
                .frame(maxWidth: 420, minHeight: 240)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(flipped ? "Translation: \(card.en)" : "Word: \(card.es)")
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Button {
                speech.speak(cards[index].es)
            } label: {
                Label("Listen", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack {
                Button {
                    withAnimation { go(to: index - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Prev")
                }
                .disabled(index == 0)

                Spacer()

                Button {
                    withAnimation { go(to: index + 1) }
                } label: {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .disabled(index == cards.count - 1)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: 420)
    }

    private func go(to newIndex: Int) {
        guard cards.indices.contains(newIndex) else { return }
        flipped = false
        index = newIndex
    }
}
