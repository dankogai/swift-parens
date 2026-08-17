import Testing

@testable import Parens

@Suite("Reduction")
struct ReductionTests {
    @Test("the combinators fire on their own arities")
    func combinatorAxioms() throws {
        #expect(try Term.i(.s).normalForm() == .s)
        #expect(try Term.k(.s, .u).normalForm() == .s)
        #expect(try Term.u(.k).normalForm() == .k(.s)(.k).normalForm())
        // S K K is the classic identity built from S and K.
        #expect(try Term.s(.k, .k, .u).normalForm() == .u)
    }

    @Test("a combinator with too few arguments is already in normal form")
    func partialApplication() {
        #expect(Term.s(.k).step() == nil)
        #expect(Term.k.step() == nil)
    }

    // The canonical Iota ladder: ιι = I, ι(ιι) = SK, ι(ι(ιι)) = K, ι(ι(ι(ιι))) = S.
    @Test(
        "the canonical programs",
        arguments: [
            ("", Term.u),
            ("()", .s(.k)(.k(.k))),  // extensionally I
            ("(())", .s(.k)),
            ("((()))", .k),
            ("(((())))", .s),
        ]
    )
    func canonicalPrograms(source: String, expected: Term) throws {
        #expect(try Parens.run(source) == expected)
    }

    @Test("() is the identity")
    func identity() throws {
        // Structurally it settles on SK(KK), which returns whatever it is handed.
        #expect(try Parens.parse("()")(.s).normalForm() == .s)
        #expect(try Parens.parse("()")(.k(.u)).normalForm() == .k(.u))
        // ()() is I applied to U.
        #expect(try Parens.run("()()") == .u)
    }

    @Test("K and S behave like K and S")
    func kAndS() throws {
        let k = try Parens.parse("((()))")
        let s = try Parens.parse("(((())))")
        #expect(try k(.s, .u).normalForm() == .s)
        #expect(try s(.k, .k, .u).normalForm() == .u)
    }

    @Test("a program without a normal form hits the step limit")
    func divergence() throws {
        // S I I duplicates its argument: "(((())))" is S, "(())" wraps I as an argument.
        let sii = "(((())))(())(())"
        #expect(try Parens.run("\(sii)(())") == .u(.u)(.u(.u)).normalForm())
        // Applied to itself it is (λx.xx)(λx.xx), which never settles.
        let omega = try Parens.parse("\(sii)(\(sii))")
        #expect(throws: ParensError.stepLimitExceeded(1000)) {
            try omega.normalForm(maxSteps: 1000)
        }
    }
}
