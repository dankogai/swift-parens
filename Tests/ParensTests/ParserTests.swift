import Testing

@testable import Parens

@Suite("Parsing () source")
struct ParserTests {
    @Test("the empty program is U")
    func emptyProgram() throws {
        #expect(try Parens.parse("") == .u)
    }

    @Test("groups fold from the left over U")
    func folding() throws {
        #expect(try Parens.parse("()") == .u(.u))
        #expect(try Parens.parse("(())") == .u(.u(.u)))
        #expect(try Parens.parse("()()") == .u(.u)(.u))
        #expect(try Parens.parse("()()()") == .u(.u)(.u)(.u))
        #expect(try Parens.parse("(()())") == .u(.u(.u)(.u)))
        #expect(try Parens.parse("((()))") == .u(.u(.u(.u))))
    }

    @Test("everything that is not a paren is ignored")
    func ignoresOtherCharacters() throws {
        #expect(try Parens.parse(" ( ) \n ; the I combinator") == Parens.parse("()"))
        #expect(try Parens.parse("λx.x") == .u)
    }

    @Test("unbalanced parens are rejected")
    func unbalanced() {
        #expect(throws: ParensError.unbalancedClose(index: 2)) {
            try Parens.parse("())")
        }
        #expect(throws: ParensError.unbalancedOpen(count: 1)) {
            try Parens.parse("(()")
        }
        #expect(throws: ParensError.unbalancedOpen(count: 2)) {
            try Parens.parse("((()")
        }
    }
}
