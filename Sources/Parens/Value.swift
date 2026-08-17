/// A `()` program as a live Swift function.
///
/// This mirrors the reference JavaScript and Scheme implementations, which hand the
/// combinators straight to the host language's closures. It is call-by-value, so
/// unlike ``Term/normalForm(maxSteps:)`` it can diverge on a term that has a normal
/// form — `K(x)(⊥)` being the classic example.
///
/// `Value` is a class, so results can be compared by identity: feeding a program a
/// freshly made value and getting the very same object back is a proof that the
/// program is the I combinator.
public final class Value: @unchecked Sendable {
    private let body: @Sendable (Value) -> Value

    public init(_ body: @escaping @Sendable (Value) -> Value) {
        self.body = body
    }

    public func callAsFunction(_ argument: Value) -> Value {
        body(argument)
    }

    /// `S = λx.λy.λz.x(z)(y(z))`
    public static let s = Value { x in Value { y in Value { z in x(z)(y(z)) } } }
    /// `K = λx.λy.x`
    public static let k = Value { x in Value { _ in x } }
    /// `I = λx.x`
    public static let i = Value { x in x }
    /// `U = λx.x(S)(K)`
    public static let u = Value { x in x(.s)(.k) }
}

extension Term {
    /// Evaluates the term to a Swift closure, applicative order.
    ///
    /// - Parameter environment: bindings for any free variables in the term.
    /// - Throws: ``ParensError/unboundVariable(_:)`` for a variable the environment
    ///   does not cover.
    public func evaluate(_ environment: [String: Value] = [:]) throws -> Value {
        switch self {
        case .s: return .s
        case .k: return .k
        case .i: return .i
        case .u: return .u
        case .variable(let name):
            guard let value = environment[name] else {
                throw ParensError.unboundVariable(name)
            }
            return value
        case .apply(let function, let argument):
            return try function.evaluate(environment)(argument.evaluate(environment))
        }
    }
}
