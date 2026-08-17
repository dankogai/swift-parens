import Testing

@testable import Parens

/// What a `()` program *does*, observed the only way a language with no I/O allows:
/// apply it to free variables and reduce.
@Suite("Extensional behaviour")
struct SemanticsTests {
    let x = Term.variable("x")
    let y = Term.variable("y")
    let z = Term.variable("z")

    @Test("() is I: it returns its argument")
    func identity() throws {
        let program = try Parens.parse("()")
        #expect(try program(x).normalForm() == x)
        #expect(try program(y(z)).normalForm() == y(z))
    }

    @Test("((())) is K: it discards its second argument")
    func constant() throws {
        let program = try Parens.parse("((()))")
        #expect(try program(x, y).normalForm() == x)
        #expect(try program(y, x).normalForm() == y)
    }

    @Test("(((()))) is S: it distributes its third argument")
    func substitution() throws {
        let program = try Parens.parse("(((())))")
        #expect(try program(x, y, z).normalForm() == x(z)(y(z)))
    }

    @Test("the empty program is U: it feeds S and K to its argument")
    func iota() throws {
        #expect(try Parens.parse("")(x).normalForm() == x(.s)(.k))
    }

    @Test("(()) is SK, which is K applied to nothing useful")
    func skAndFriends() throws {
        // S K x y → K y (x y) → y, so SK is another identity in disguise.
        #expect(try Parens.parse("(())")(x, y).normalForm() == y)
    }

    @Test("programs compose: K x y stays x however it is spelled")
    func composition() throws {
        // "((()))" is K; wrapping a program in parens makes it an argument.
        let kx = try Parens.parse("((()))")(x)
        #expect(try kx(y).normalForm() == x)
        #expect(try kx(y(z)).normalForm() == x)
    }

    @Test("closure evaluation matches reduction on the same variables")
    func closuresAgree() throws {
        let markers = ["x": Value { $0 }, "y": Value { $0 }, "z": Value { $0 }]
        for source in ["()", "()()", "(())", "((()))", "(((())))", "(()())"] {
            let program = try Parens.parse(source)(x, y, z)
            let reduced = try program.normalForm()
            // Both engines land on the same variable, compared by object identity.
            #expect(try program.evaluate(markers) === reduced.evaluate(markers))
        }
    }
}
