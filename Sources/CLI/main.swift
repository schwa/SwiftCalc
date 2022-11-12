import Darwin
import SwiftCalc

func sin(_ parameters: [Value]) -> Value {
    guard parameters.count == 1, let p0 = parameters.first, case .number(let value) = p0 else {
        fatalError()
    }
    return .number(Darwin.sin(value))
}

let variables: [String: Value] = [
    "pi": .number(3.14),
    "sin": .function(sin),
]

let program = try Compiler().compile("sin(1) * 10 * pi")
// program.dump()
let executor = Executor(variables: variables)
print(try executor.execute(program))
