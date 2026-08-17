import Testing

@testable import Parens

@Suite("Rendering")
struct RenderingTests {
    @Test("combinator notation is left-associative")
    func description() throws {
        #expect("\(Term.u)" == "U")
        #expect("\(try Parens.parse("()"))" == "UU")
        #expect("\(try Parens.parse("()()"))" == "UUU")
        #expect("\(try Parens.parse("(())"))" == "U(UU)")
        #expect("\(Term.s(.k, .k(.k)))" == "SK(KK)")
        #expect("\(Term.variable("x")(.variable("y")))" == "xy")
    }

    // The reference implementation translates () to JavaScript by rewriting '(' to
    // 'U(', then patching up 'U()' and ')U('. These are its outputs.
    @Test(
        "JavaScript output matches the reference translator",
        arguments: [
            ("()", "U(U)"),
            ("()()", "U(U)(U)"),
            ("(())", "U(U(U))"),
            ("((()))", "U(U(U(U)))"),
            ("(()())", "U(U(U)(U))"),
        ]
    )
    func javaScript(source: String, expected: String) throws {
        #expect(try Parens.parse(source).javaScriptSource == expected)
    }

    @Test("S-expression output nests applications")
    func scheme() throws {
        #expect(try Parens.parse("()").schemeSource == "(U U)")
        #expect(try Parens.parse("()()").schemeSource == "((U U) U)")
        #expect(try Parens.parse("(())").schemeSource == "(U (U U))")
    }
}
