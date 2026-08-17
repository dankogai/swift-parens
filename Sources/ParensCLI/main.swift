import Foundation
import Parens

let usage = """
parens — an interpreter for the () esoteric programming language

USAGE:
  parens [options] [file]

  With no file and no --eval, the program is read from standard input.

OPTIONS:
  -e, --eval <source>    Run <source> instead of reading a file or stdin
  -a, --apply <source>   Apply the program to <source>; repeatable, left to right
  -v, --var <name>       Apply the program to a free variable; repeatable
  -f, --from <syntax>    parens (default) | iota
  -t, --to <syntax>      normal (default) | term | parens | iota | js | scheme
      --steps <n>        Reduction step limit (default 1000000)
  -h, --help             Show this help

SYNTAXES:
  normal   the program's normal form, in combinator notation
  term     the program as parsed, unreduced
  parens   () source
  iota     Iota source
  js       a JavaScript expression
  scheme   an S-expression

EXAMPLES:
  parens -e '()'                     # SK(KK), the I combinator
  parens -e '((()))'                 # K
  parens -e '(((())))'               # S
  parens -e '()' -v x                # x — the program is the identity
  parens -e '((()))' -v x -v y       # x — the program discards its second argument
  parens -e '(((())))' -v x -v y -v z  # xz(yz)
  parens -e '((()))' -t iota         # *i*i*ii
  parens -f iota -e '*ii' -t parens  # ()
"""

enum Syntax: String {
    case normal, term, parens, iota, js, scheme
}

/// Something the program gets applied to, in command-line order.
enum Operand {
    case program(String)
    case variable(String)
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("parens: \(message)\n".utf8))
    exit(1)
}

var inputSyntax = "parens"
var outputSyntax = Syntax.normal
var literalSource: String?
var path: String?
var operands: [Operand] = []
var maxSteps = 1_000_000

var arguments = CommandLine.arguments.dropFirst().makeIterator()

@MainActor
func value(for option: String) -> String {
    guard let value = arguments.next() else { fail("\(option) requires a value") }
    return value
}

while let argument = arguments.next() {
    switch argument {
    case "-h", "--help":
        print(usage)
        exit(0)
    case "-e", "--eval":
        literalSource = value(for: argument)
    case "-a", "--apply":
        operands.append(.program(value(for: argument)))
    case "-v", "--var":
        operands.append(.variable(value(for: argument)))
    case "-f", "--from":
        inputSyntax = value(for: argument)
    case "-t", "--to":
        let raw = value(for: argument)
        guard let syntax = Syntax(rawValue: raw) else { fail("unknown syntax '\(raw)'") }
        outputSyntax = syntax
    case "--steps":
        guard let steps = Int(value(for: argument)), steps > 0 else {
            fail("--steps requires a positive integer")
        }
        maxSteps = steps
    default:
        guard !argument.hasPrefix("-") || argument == "-" else {
            fail("unknown option '\(argument)'")
        }
        guard path == nil else { fail("more than one input file") }
        path = argument
    }
}

let parse: (String) throws -> Term
switch inputSyntax {
case "parens": parse = Parens.parse
case "iota": parse = Iota.parse
default: fail("unknown input syntax '\(inputSyntax)'")
}

let source: String
switch (literalSource, path) {
case (let literal?, nil):
    source = literal
case (nil, let path?) where path != "-":
    do {
        source = try String(contentsOfFile: path, encoding: .utf8)
    } catch {
        fail("cannot read \(path): \(error.localizedDescription)")
    }
case (nil, _):
    source = String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
case (_?, _?):
    fail("--eval and a file cannot be combined")
}

do {
    var program = try parse(source)
    for operand in operands {
        switch operand {
        case .program(let source): program = try program(parse(source))
        case .variable(let name): program = program(.variable(name))
        }
    }
    switch outputSyntax {
    case .normal: print(try program.normalForm(maxSteps: maxSteps))
    case .term: print(program)
    case .parens: print(try program.parensSource())
    case .iota: print(try program.iotaSource())
    case .js: print(program.javaScriptSource)
    case .scheme: print(program.schemeSource)
    }
} catch let error as ParensError {
    fail(error.description)
} catch {
    fail("\(error)")
}
