/// The `()` language: source code made of nothing but `(` and `)`.
///
/// A program is a sequence of balanced groups. Every group — including the whole
/// program — is evaluated by folding its children from left to right over `U`:
///
/// ```text
/// eval(g₁ g₂ … gₙ) = U(eval(g₁))(eval(g₂))…(eval(gₙ))
/// ```
///
/// so the empty program is `U`, `()` is `U(U)` (the I combinator), and `()()` is
/// `U(U)(U)`.
public enum Parens {
    /// Parses `()` source into a ``Term``.
    ///
    /// Characters other than `(` and `)` are ignored, which is the only way to
    /// comment a `()` program.
    ///
    /// - Throws: ``ParensError/unbalancedClose(index:)`` or
    ///   ``ParensError/unbalancedOpen(count:)`` if the parentheses do not balance.
    public static func parse(_ source: some StringProtocol) throws -> Term {
        // Each open group is an accumulator seeded with U; closing a group applies
        // the enclosing accumulator to the finished child.
        var stack: [Term] = [.u]
        for (index, character) in source.enumerated() {
            switch character {
            case "(":
                stack.append(.u)
            case ")":
                guard stack.count > 1 else {
                    throw ParensError.unbalancedClose(index: index)
                }
                let child = stack.removeLast()
                stack[stack.endIndex - 1] = stack[stack.endIndex - 1](child)
            default:
                continue
            }
        }
        guard stack.count == 1 else {
            throw ParensError.unbalancedOpen(count: stack.count - 1)
        }
        return stack[0]
    }

    /// Parses `()` source and reduces it to normal form.
    ///
    /// - Throws: a ``ParensError`` if the source is malformed or the program does
    ///   not settle within `maxSteps`.
    public static func run(
        _ source: some StringProtocol,
        maxSteps: Int = 1_000_000
    ) throws -> Term {
        try parse(source).normalForm(maxSteps: maxSteps)
    }
}
