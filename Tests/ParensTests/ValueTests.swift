import Testing

@testable import Parens

/// The closure engine, which mirrors the reference JavaScript and Scheme
/// implementations. `Value` is a class, so a program that hands back the very object
/// it was given is the I combinator, proven by identity.
@Suite("Closure evaluation")
struct ValueTests {
    static func marker() -> Value { Value { $0 } }

    @Test("() is the I combinator")
    func identity() throws {
        let x = Self.marker()
        #expect(try Parens.parse("()").evaluate()(x) === x)
    }

    @Test("((())) is the K combinator")
    func constant() throws {
        let (x, y) = (Self.marker(), Self.marker())
        let k = try Parens.parse("((()))").evaluate()
        #expect(k(x)(y) === x)
        #expect(k(y)(x) === y)
    }

    @Test("(((()))) is the S combinator")
    func substitution() throws {
        let x = Self.marker()
        let s = try Parens.parse("(((())))").evaluate()
        // S K K x = x
        #expect(s(.k)(.k)(x) === x)
        // S x y z = x(z)(y(z)), spelled out on the right.
        #expect(s(.k)(.i)(x) === Value.k(x)(Value.i(x)))
    }

    @Test("the empty program is U")
    func iota() throws {
        let x = Self.marker()
        // U I = I(S)(K) = SK, and S K x y = y.
        let u = try Parens.parse("").evaluate()
        #expect(u(.i)(x)(.k) === Value.k)
    }

    @Test("a free variable needs a binding")
    func unbound() {
        #expect(throws: ParensError.unboundVariable("x")) {
            try Term.variable("x").evaluate()
        }
    }
}
