/// A term of combinatory logic: a primitive combinator, or one term applied to another.
///
/// A `()` program parses into a `Term` built solely out of ``u`` and ``apply(_:_:)``.
/// ``s``, ``k`` and ``i`` never occur in source; they show up once reduction starts,
/// because `U` unfolds into `S` and `K`.
public indirect enum Term: Hashable, Sendable {
    /// `S = λx.λy.λz.x(z)(y(z))`
    case s
    /// `K = λx.λy.x`
    case k
    /// `I = λx.x`
    case i
    /// `U = λx.x(S)(K)` — the sole primitive of Iota, and of `()`.
    case u
    /// A free variable. `()` source cannot produce one, but since the language has no
    /// I/O, applying a program to variables and reducing is how you see what it does.
    case variable(String)
    /// Application. `.apply(f, x)` is `f(x)`; application associates to the left.
    case apply(Term, Term)

    /// How many arguments the combinator consumes, or `nil` if it never reduces.
    var arity: Int? {
        switch self {
        case .s: 3
        case .k: 2
        case .i, .u: 1
        case .variable, .apply: nil
        }
    }

    /// Splits `f(x)(y)(z)` into its head `f` and its arguments `[x, y, z]`.
    ///
    /// The head is always a combinator, never an application.
    public var spine: (head: Term, arguments: [Term]) {
        var head = self
        var arguments: [Term] = []
        while case .apply(let function, let argument) = head {
            arguments.append(argument)
            head = function
        }
        return (head, arguments.reversed())
    }

    /// Applies this term to `arguments`, left to right.
    ///
    /// ```swift
    /// Term.s(.k, .k)  // S(K)(K)
    /// ```
    public func callAsFunction(_ arguments: Term...) -> Term {
        arguments.reduce(self, Term.apply)
    }

    static func applying(_ head: Term, _ arguments: some Sequence<Term>) -> Term {
        arguments.reduce(head, Term.apply)
    }

    /// Fires the given combinator on exactly `arity` arguments.
    private static func contract(_ combinator: Term, _ arguments: [Term]) -> Term {
        switch combinator {
        case .i:
            arguments[0]
        case .k:
            arguments[0]
        case .u:
            // U x → x(S)(K)
            arguments[0](.s, .k)
        case .s:
            // S x y z → x(z)(y(z))
            arguments[0](arguments[2])(arguments[1](arguments[2]))
        case .variable, .apply:
            preconditionFailure("\(combinator) is not a combinator")
        }
    }

    /// Performs one reduction step in normal order — leftmost, outermost redex first.
    ///
    /// Returns `nil` when the term is already in normal form.
    public func step() -> Term? {
        let (head, arguments) = spine
        if let arity = head.arity, arguments.count >= arity {
            let contracted = Term.contract(head, Array(arguments.prefix(arity)))
            return Term.applying(contracted, arguments.dropFirst(arity))
        }
        for index in arguments.indices {
            guard let reduced = arguments[index].step() else { continue }
            var arguments = arguments
            arguments[index] = reduced
            return Term.applying(head, arguments)
        }
        return nil
    }

    /// Reduces the term until no redex is left.
    ///
    /// Normal order guarantees that a normal form is reached whenever one exists — but
    /// plenty of `()` programs have none, hence `maxSteps`.
    ///
    /// - Throws: ``ParensError/stepLimitExceeded(_:)`` if the limit is hit first.
    public func normalForm(maxSteps: Int = 1_000_000) throws -> Term {
        var term = self
        for _ in 0..<maxSteps {
            guard let next = term.step() else { return term }
            term = next
        }
        throw ParensError.stepLimitExceeded(maxSteps)
    }
}

extension Term: CustomStringConvertible {
    /// The term in conventional combinator notation, e.g. `SK(KK)`.
    public var description: String {
        switch self {
        case .s: "S"
        case .k: "K"
        case .i: "I"
        case .u: "U"
        case .variable(let name): name
        case .apply(let function, let argument):
            if case .apply = argument {
                "\(function)(\(argument))"
            } else {
                "\(function)\(argument)"
            }
        }
    }
}
