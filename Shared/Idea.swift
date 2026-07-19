import Foundation

/// Describes one of the five Spanish-learning "ideas" so the native hub can
/// render a consistent launcher tile and route into the matching feature view.
public enum Idea: String, CaseIterable, Identifiable {
    case lingoBox, habla, conjugador, hola, cuentos

    public var id: String { rawValue }

    /// Display name of the feature.
    public var title: String {
        switch self {
        case .lingoBox:   return "LingoBox"
        case .habla:      return "Habla"
        case .conjugador: return "Conjugador"
        case .hola:       return "Hola"
        case .cuentos:    return "Cuentos"
        }
    }

    /// One-line tagline shown under the title.
    public var subtitle: String {
        switch self {
        case .lingoBox:   return "Spaced-repetition flashcards"
        case .habla:      return "Offline conversation coach"
        case .conjugador: return "Verb conjugation drills"
        case .hola:       return "Bite-size mini-lessons"
        case .cuentos:    return "Graded story reader"
        }
    }

    /// SF Symbol used as the tile icon.
    public var symbol: String {
        switch self {
        case .lingoBox:   return "rectangle.stack.fill"
        case .habla:      return "bubble.left.and.bubble.right.fill"
        case .conjugador: return "textformat.abc"
        case .hola:       return "graduationcap.fill"
        case .cuentos:    return "book.fill"
        }
    }

    /// Accent color (as a SwiftUI-friendly hex description) for the tile.
    public var accent: String {
        switch self {
        case .lingoBox:   return "#FF6B6B"
        case .habla:      return "#4D96FF"
        case .conjugador: return "#6BCB77"
        case .hola:       return "#FFD93D"
        case .cuentos:    return "#C780FA"
        }
    }
}
