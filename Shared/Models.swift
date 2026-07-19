import Foundation

// MARK: - Verb conjugation domain

/// The four tenses drilled by the Conjugador feature.
public enum Tense: String, CaseIterable, Codable, Hashable, Identifiable {
    case present, preterite, imperfect, future

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .present:  return "Present"
        case .preterite: return "Preterite"
        case .imperfect: return "Imperfect"
        case .future:    return "Future"
        }
    }

    /// A one-line hint describing when the tense is used.
    public var hint: String {
        switch self {
        case .present:  return "right now / habitual"
        case .preterite: return "completed past action"
        case .imperfect: return "ongoing / repeated past"
        case .future:    return "what will happen"
        }
    }
}

/// The six grammatical persons, in the canonical conjugation order.
public enum Person: Int, CaseIterable, Codable, Hashable, Identifiable {
    case yo = 0
    case tu
    case el
    case nosotros
    case vosotros
    case ellos

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .yo:       return "yo"
        case .tu:       return "tú"
        case .el:       return "él / ella / usted"
        case .nosotros: return "nosotros / nosotras"
        case .vosotros: return "vosotros / vosotras"
        case .ellos:    return "ellos / ellas / ustedes"
        }
    }
}

/// A single Spanish verb with its four tenses x six persons already conjugated.
public struct SpanishVerb: Identifiable, Hashable {
    public var id: String { inf }

    public let inf: String
    public let en: String
    /// Conjugated forms keyed by tense; each value is the six persons in `Person` order.
    public let forms: [Tense: [String]]

    public init(inf: String, en: String,
                present: [String], preterite: [String], imperfect: [String], future: [String]) {
        self.inf = inf
        self.en = en
        self.forms = [
            .present: present,
            .preterite: preterite,
            .imperfect: imperfect,
            .future: future,
        ]
    }

    /// Returns the conjugated form for a given tense + person.
    public func form(_ tense: Tense, _ person: Person) -> String {
        forms[tense]?[person.rawValue] ?? ""
    }
}

// MARK: - Mini-lesson domain (Hola)

public struct MatchPair: Identifiable, Hashable {
    public let id = UUID()
    public let es: String
    public let en: String
}

/// A single exercise inside a Duolingo-style mini-lesson.
public enum Exercise: Identifiable, Hashable {
    case choice(id: String, prompt: String, options: [String], answer: String, hint: String)
    case tap(id: String, prompt: String, source: String, bank: [String], answer: [String])
    case listen(id: String, prompt: String, audioText: String, options: [String], answer: String)
    case match(id: String, prompt: String, pairs: [MatchPair])

    public var id: String {
        switch self {
        case .choice(let id, _, _, _, _),
             .tap(let id, _, _, _, _),
             .listen(let id, _, _, _, _),
             .match(let id, _, _):
            return id
        }
    }

    public var title: String {
        switch self {
        case .choice: return "Choose"
        case .tap:    return "Tap to translate"
        case .listen: return "Listen"
        case .match:  return "Match pairs"
        }
    }
}

public struct Lesson: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let emoji: String
    public let exercises: [Exercise]
}

// MARK: - Story reader domain (Cuentos)

public struct StorySentence: Codable, Hashable, Identifiable {
    /// Stable id derived from the Spanish text (sentences are unique within a story).
    public var id: String { es }

    public let es: String
    public let en: String

    public init(es: String, en: String) {
        self.es = es
        self.en = en
    }
}

public struct Story: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let level: String
    public let sentences: [StorySentence]
}

// MARK: - Flashcards domain (LingoBox)

public struct Flashcard: Identifiable, Hashable {
    public let id: String
    public let es: String
    public let en: String
    public let example: String
}

// MARK: - Conversation domain (Habla)

public struct ScenarioVocab: Identifiable, Hashable {
    public var id: String { es }
    public let es: String
    public let en: String
}

public struct ScenarioTurn: Hashable {
    public let botEs: String
    public let botEn: String
    public let expects: [String]
    public let hintEs: String
    public let coachEn: String
}

public struct Scenario: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let level: String
    public let icon: String
    public let vocab: [ScenarioVocab]
    public let turns: [ScenarioTurn]
    public let introEs: String
    public let introEn: String
    public let outroEs: String
    public let outroEn: String
}
