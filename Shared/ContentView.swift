import SwiftUI

/// The main random-number generator screen.
struct ContentView: View {
    @EnvironmentObject private var gen: RandomGenerator

    private let gradient = LinearGradient(
        colors: [Color(hex: "#6C5CE7"), Color(hex: "#00CEC9")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        VStack(spacing: 20) {
            header
            modeChips
            controlPanel
            generateButton
            resultsList
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            Color(hex: "#0F1020")
                .overlay(gradient.opacity(0.10))
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("🎲")
                .font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text("NumberTwo")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("Random Number Generator")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
    }

    private var modeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GeneratorMode.allCases) { m in
                    Button {
                        withAnimation(.spring(response: 0.3)) { gen.mode = m }
                    } label: {
                        Text(m.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(gen.mode == m ? gradient : Color.white.opacity(0.08))
                            .foregroundStyle(gen.mode == m ? .white : .white.opacity(0.7))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 14) {
            switch gen.mode {
            case .integer, .decimal:
                rangeRow
                if gen.mode == .decimal { decimalRow }
            case .dice:
                labeledStepper("Sides", value: $gen.diceSides, range: 2...1000)
            case .hex:
                labeledStepper("Hex length", value: $gen.hexLength, range: 1...256)
            case .coin, .uuid:
                EmptyView()
            }
            quantityRow
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.06)))
    }

    private var rangeRow: some View {
        HStack(spacing: 12) {
            numberField("Min", text: $gen.minValue)
            Text("–").foregroundStyle(.white.opacity(0.5))
            numberField("Max", text: $gen.maxValue)
        }
    }

    private var decimalRow: some View {
        labeledStepper("Decimal places", value: $gen.decimalPlaces, range: 0...10)
    }

    private var quantityRow: some View {
        labeledStepper("Quantity", value: $gen.quantity, range: 1...1000)
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.5))
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .keyboardType(.numberPad)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func labeledStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)").foregroundStyle(.white)
            }
        }
    }

    private var generateButton: some View {
        Button {
            gen.generate()
        } label: {
            Text("Generate")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: Color(hex: "#6C5CE7").opacity(0.4), radius: 12, y: 6)
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Results")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !gen.results.isEmpty {
                    Button { gen.copyResults() } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(gradient)
                    Button { gen.clear() } label: {
                        Label("Clear", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
            if gen.results.isEmpty {
                Text("Tap Generate to roll some numbers.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(gen.results.enumerated()), id: \.offset) { i, r in
                            HStack {
                                Text("#\(i + 1)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 34, alignment: .leading)
                                Text(r)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            if let err = gen.lastError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Hex color helper (shared across views)

extension Color {
    /// Build a `Color` from a 6-digit hex string (e.g. "#6C5CE7").
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: string).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    ContentView().environmentObject(RandomGenerator())
        .preferredColorScheme(.dark)
}
