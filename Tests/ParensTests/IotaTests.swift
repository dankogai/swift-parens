import Testing

@testable import Parens

@Suite("Iota translation")
struct IotaTests {
    static let pairs: [(parens: String, iota: String)] = [
        ("", "i"),
        ("()", "*ii"),
        ("(())", "*i*ii"),
        ("()()", "**iii"),
        ("((()))", "*i*i*ii"),
        ("(((())))", "*i*i*i*ii"),
        ("(()())", "*i**iii"),
    ]

    @Test("the two syntaxes denote the same term", arguments: pairs)
    func agreement(pair: (parens: String, iota: String)) throws {
        #expect(try Parens.parse(pair.parens) == Iota.parse(pair.iota))
    }

    @Test("terms round-trip through both syntaxes", arguments: pairs)
    func roundTrip(pair: (parens: String, iota: String)) throws {
        let term = try Parens.parse(pair.parens)
        #expect(try term.parensSource() == pair.parens)
        #expect(try term.iotaSource() == pair.iota)
    }

    @Test("a () program is one symbol shorter than its Iota program", arguments: pairs)
    func oneSymbolShorter(pair: (parens: String, iota: String)) {
        #expect(pair.parens.count + 1 == pair.iota.count)
    }

    @Test("ι is accepted for i, and whitespace is ignored")
    func alternateSpelling() throws {
        #expect(try Iota.parse("* ι ι") == Parens.parse("()"))
    }

    @Test("malformed Iota is rejected")
    func malformed() {
        #expect(throws: ParensError.unexpectedEnd) { try Iota.parse("*i") }
        #expect(throws: ParensError.trailingInput(index: 3)) { try Iota.parse("*iii") }
        #expect(throws: ParensError.unexpectedCharacter("j", index: 1)) {
            try Iota.parse("*ji")
        }
    }

    @Test("terms outside the U fragment have no () source")
    func notEncodable() {
        #expect(throws: ParensError.notEncodable(.k)) { try Term.k.parensSource() }
        // The error names the offending subterm, wherever it sits.
        #expect(throws: ParensError.notEncodable(.s)) { try Term.u(.s).iotaSource() }
        #expect(throws: ParensError.notEncodable(.variable("x"))) {
            try Term.u(.u(.variable("x"))).parensSource()
        }
    }
}
