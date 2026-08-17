/// Iota, the mother of `()`: `i` is the `U` combinator and `*xy` applies `x` to `y`.
///
/// Iota and `()` encode exactly the same terms, so translation is lossless in both
/// directions — and a `()` program is always one symbol shorter than its Iota
/// counterpart, since every `*` becomes a paren pair that also delimits its argument.
public enum Iota {
    /// Parses an Iota program in prefix notation into a ``Term``.
    ///
    /// Both `i` and `ι` denote the combinator; whitespace is ignored.
    ///
    /// - Throws: a ``ParensError`` if the program is truncated, contains an
    ///   unexpected character, or is followed by leftover input.
    public static func parse(_ source: some StringProtocol) throws -> Term {
        let characters = Array(source)
        var index = 0

        func next() throws -> Term {
            while index < characters.count, characters[index].isWhitespace {
                index += 1
            }
            guard index < characters.count else { throw ParensError.unexpectedEnd }
            let character = characters[index]
            index += 1
            switch character {
            case "i", "ι":
                return .u
            case "*":
                let function = try next()
                return try function(next())
            default:
                throw ParensError.unexpectedCharacter(character, index: index - 1)
            }
        }

        let term = try next()
        while index < characters.count, characters[index].isWhitespace {
            index += 1
        }
        guard index == characters.count else {
            throw ParensError.trailingInput(index: index)
        }
        return term
    }
}

extension Term {
    /// The `()` source of this term.
    ///
    /// - Throws: ``ParensError/notEncodable(_:)`` if the term mentions any
    ///   combinator besides `U` — reduced terms usually do.
    public func parensSource() throws -> String {
        let (head, arguments) = spine
        guard head == .u else { throw ParensError.notEncodable(self) }
        var source = ""
        for argument in arguments {
            source += try "(\(argument.parensSource()))"
        }
        return source
    }

    /// The Iota source of this term.
    ///
    /// - Throws: ``ParensError/notEncodable(_:)`` if the term mentions any
    ///   combinator besides `U`.
    public func iotaSource() throws -> String {
        let (head, arguments) = spine
        guard head == .u else { throw ParensError.notEncodable(self) }
        var source = "i"
        for argument in arguments {
            source = try "*\(source)\(argument.iotaSource())"
        }
        return source
    }
}
