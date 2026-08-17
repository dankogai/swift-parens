/// Everything that can go wrong while reading, translating or running a `()` program.
public enum ParensError: Error, Hashable, Sendable, CustomStringConvertible {
    /// A `)` appeared with no matching `(`.
    case unbalancedClose(index: Int)
    /// The source ended while `count` groups were still open.
    case unbalancedOpen(count: Int)
    /// An Iota program ended in the middle of an application.
    case unexpectedEnd
    /// A character that the grammar does not allow.
    case unexpectedCharacter(Character, index: Int)
    /// The program was complete but more input followed.
    case trailingInput(index: Int)
    /// Reduction did not reach a normal form within the allowed number of steps.
    case stepLimitExceeded(Int)
    /// The term uses combinators other than `U`, so it has no `()`/Iota source.
    case notEncodable(Term)
    /// A free variable was evaluated without a binding.
    case unboundVariable(String)

    public var description: String {
        switch self {
        case .unbalancedClose(let index):
            "unbalanced ')' at offset \(index)"
        case .unbalancedOpen(let count):
            "unexpected end of program: \(count) unclosed '('"
        case .unexpectedEnd:
            "unexpected end of program"
        case .unexpectedCharacter(let character, let index):
            "unexpected character '\(character)' at offset \(index)"
        case .trailingInput(let index):
            "trailing input at offset \(index)"
        case .stepLimitExceeded(let limit):
            "no normal form after \(limit) reduction steps"
        case .notEncodable(let term):
            "\(term) is not expressible in () — it uses combinators other than U"
        case .unboundVariable(let name):
            "unbound variable '\(name)'"
        }
    }
}
