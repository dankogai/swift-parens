extension Term {
    /// The term as a JavaScript expression, matching the reference implementation's
    /// `translate()` output: `()` renders as `U(U)`.
    ///
    /// Evaluating it needs the combinators in scope:
    /// ```js
    /// const S = x => y => z => x(z)(y(z));
    /// const K = x => y => x;
    /// const I = x => x;
    /// const U = x => x(S)(K);
    /// ```
    public var javaScriptSource: String {
        switch self {
        case .apply(let function, let argument):
            "\(function.javaScriptSource)(\(argument.javaScriptSource))"
        default:
            description
        }
    }

    /// The term as an S-expression: `()` renders as `(U U)`.
    public var schemeSource: String {
        switch self {
        case .apply(let function, let argument):
            "(\(function.schemeSource) \(argument.schemeSource))"
        default:
            description
        }
    }
}
