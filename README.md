# SwiftCalc

A Swift package for parsing and evaluating mathematical expressions.

The parser supports the basic math operators, variables and functions (defined in Swift). Under the hood it uses the wonder Owl Parser Generator <https://github.com/ianh/owl>.

Basic support for syntax coloring is provided in an extension of `AttributedString`.

## Usage

There are three main types in this package: `Compiler` which compiles an expression string into `CompiledProgram` and then `Executor` which evaluates the `CompiledProgram`. The `Executor` can be reused for multiple expressions.

```swift
import SwiftCalc

let variables: [String: Value] = [
    "pi": .number(.pi),
    "sin": .function(Math.sin),
]
let program = try Compiler().compile("sin(1) * 10 * pi")
program.dump()
let executor = Executor(variables: variables)
let result = try executor.execute(program)
guard case let .number(resultValue) = result else {
    fatalError()
}
```

### Demo Screenshot

![Alt text](Documentation/Screenshot%202022-11-12%20at%2015.13.18.png)
