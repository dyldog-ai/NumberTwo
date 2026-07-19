import Foundation
import SwiftUI

/// The operating modes the generator supports.
enum GeneratorMode: String, CaseIterable, Identifiable {
    case integer = "Integer"
    case decimal = "Decimal"
    case dice = "Dice"
    case coin = "Coin"
    case uuid = "UUID"
    case hex = "Hex"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .integer: return "123"
        case .decimal: return "1.0"
        case .dice: return "⚄"
        case .coin: return "⚀"
        case .uuid: return "⧉"
        case .hex: return "⌗"
        }
    }
}

/// Observable engine that produces random values and keeps a short history.
@MainActor
final class RandomGenerator: ObservableObject {
    @Published var mode: GeneratorMode = .integer
    @Published var minValue: String = "1"
    @Published var maxValue: String = "100"
    @Published var quantity: Int = 1
    @Published var decimalPlaces: Int = 2
    @Published var diceSides: Int = 6
    @Published var hexLength: Int = 16
    @Published var results: [String] = []
    @Published var lastError: String?

    /// Generate and append new results for the current configuration.
    func generate() {
        lastError = nil
        var out: [String] = []
        for _ in 0..<max(1, min(quantity, 1000)) {
            switch mode {
            case .integer:
                guard let lo = Int(minValue), let hi = Int(maxValue), lo <= hi else {
                    lastError = "Min must be ≤ Max, and both must be integers."; return
                }
                out.append(String(Int.random(in: lo...hi)))
            case .decimal:
                guard let lo = Double(minValue), let hi = Double(maxValue), lo <= hi else {
                    lastError = "Min must be ≤ Max, and both must be numbers."; return
                }
                let v = Double.random(in: lo...hi)
                let spec = "%." + String(max(0, min(decimalPlaces, 10))) + "f"
                out.append(String(format: spec, v)))
            case .dice:
                let sides = max(2, min(diceSides, 1000))
                out.append(String(Int.random(in: 1...sides)))
            case .coin:
                out.append(Bool.random() ? "Heads" : "Tails")
            case .uuid:
                out.append(UUID().uuidString)
            case .hex:
                let len = max(1, min(hexLength, 256))
                out.append((0..<len).map { _ in "0123456789ABCDEF".randomElement()! }.joined())
            }
        }
        results.insert(contentsOf: out, at: 0)
        if results.count > 100 { results.removeSubrange(100...) }
    }

    /// Copy every current result to the system pasteboard.
    func copyResults() {
        #if os(macOS)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(results.joined(separator: "\n"), forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = results.joined(separator: "\n")
        #endif
    }

    func clear() { results.removeAll() }
}
