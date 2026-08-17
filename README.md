# swift-parens

An implementation of [`()`](https://esolangs.org/wiki/()) — the esoteric language whose
source code is nothing but `(` and `)` — in Swift.

`()` is a daughter of [Iota](https://esolangs.org/wiki/Iota): a Turing tarpit built from
a single combinator, with no I/O whatsoever. This package provides a parser, a
normal-order reducer, a closure-based evaluator, translators to and from Iota,
JavaScript and Scheme, and a command-line interpreter.

## The language

There is one primitive, `U`, and one operation, application:

```
S = λx.λy.λz.x(z)(y(z))
K = λx.λy.x
U = λx.x(S)(K)
```

A program is a sequence of balanced groups. Every group — the whole program
included — is evaluated by folding its children from left to right over `U`:

```
eval(g₁ g₂ … gₙ) = U(eval(g₁))(eval(g₂))…(eval(gₙ))
```

So the empty program is `U`, `()` is `U(U)`, and `()()` is `U(U)(U)`. Characters that
are neither `(` nor `)` are ignored, which is the only way to comment a program.

That is enough for everything:

| program      | is         | because                |
| ------------ | ---------- | ---------------------- |
| ``           | `U`        | the empty fold         |
| `()`         | `I`        | `U(U)`                 |
| `(())`       | `SK`       | `U(U(U))`              |
| `((()))`     | `K`        | `U(U(U(U)))`           |
| `(((())))`   | `S`        | `U(U(U(U(U))))`        |

Since `S` and `K` are enough to express any lambda term, so is `()`. A `()` program is
always exactly one symbol shorter than the Iota program it encodes.

## Command line

```bash
swift run parens -e '((()))'
```

```
K
```

A language with no I/O has to be observed some other way: apply the program to free
variables and read off the normal form.

```bash
swift run parens -e '(((())))' -v x -v y -v z
```

```
xz(yz)
```

```
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
```

`--to` doubles as a transpiler:

```bash
swift run parens -e '((()))' -t iota      # *i*i*ii
swift run parens -e '((()))' -t js        # U(U(U(U)))
swift run parens -e '((()))' -t scheme    # (U (U (U U)))
swift run parens -f iota -e '*i*i*ii'     # K
```

## Library

```swift
import Parens

let program = try Parens.parse("((()))")     // U(U(U(U)))

// Reduce, in normal order.
try program.normalForm()                     // K
try program(.variable("x"), .variable("y")).normalForm()   // x

// Or run it as a Swift closure, the way the reference implementations do.
let k = try program.evaluate()
let (x, y) = (Value { $0 }, Value { $0 })
k(x)(y) === x                                // true

// Translate.
try program.iotaSource()                     // "*i*i*ii"
program.javaScriptSource                     // "U(U(U(U)))"
try Iota.parse("*ii").parensSource()         // "()"
```

`Term` is the core type — the four combinators, free variables, and application.
`Term.step()` performs one leftmost-outermost reduction, so a normal form is found
whenever one exists; `normalForm(maxSteps:)` throws once the step limit is hit, since
plenty of `()` programs never settle.

`Value` is the second engine: a `()` program as a live Swift closure, mirroring the
reference JavaScript and Scheme implementations. It is call-by-value, so it can
diverge where reduction would not. It is a class, which makes results comparable by
identity — handing a program a fresh value and getting the same object back is a proof
that the program is `I`.

## Building

```bash
swift build
swift test
```

## See also

- [`()` on Esolang](https://esolangs.org/wiki/())
- [Iota](https://esolangs.org/wiki/Iota)
- [404 Blog Not Found: ()](http://blog.livedoor.jp/dankogai/archives/51524639.html)

## License

MIT. See [LICENSE](LICENSE).
