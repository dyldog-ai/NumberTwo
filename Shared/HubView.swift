import SwiftUI

/// The native home screen for NumberTwo.
///
/// Shows the five Spanish-learning features (LingoBox, Habla, Conjugador, Hola,
/// Cuentos) as tappable tiles and routes into the matching feature view. Lives
/// in `Shared/` so both the iOS and macOS apps share one launcher.
public struct HubView: View {
    @State private var selection: Idea?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Idea.allCases) { idea in
                            tile(idea)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 24)
            }
            .navigationTitle("NumberTwo")
            .inlineTitle()
            .navigationDestination(for: Idea.self) { idea in
                destination(for: idea)
            }
        }
    }

    private var columns: [GridItem] {
        #if os(macOS)
        return [GridItem(.adaptive(minimum: 220))]
        #else
        return [GridItem(.adaptive(minimum: 150))]
        #endif
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text("Aprende español")
                .font(.title2.bold())
            Text("Pick a way to practice")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tile(_ idea: Idea) -> some View {
        Button {
            selection = idea
        } label: {
            VStack(spacing: 10) {
                Image(systemName: idea.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: idea.accent))
                Text(idea.title)
                    .font(.headline)
                Text(idea.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: idea.accent).opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: idea.accent).opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func destination(for idea: Idea) -> some View {
        switch idea {
        case .lingoBox:   LingoBoxView()
        case .habla:      HablaView()
        case .conjugador: ConjugadorView()
        case .hola:       HolaView()
        case .cuentos:    CuentosView()
        }
    }
}

// MARK: - Small color helper

extension Color {
    /// Build a `Color` from a 6-digit hex string (e.g. "#FF6B6B").
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        string.removeFirst() // drop '#'
        var rgb: UInt64 = 0
        Scanner(string: string).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
