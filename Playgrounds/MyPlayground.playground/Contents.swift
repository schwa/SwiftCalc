//: A Cocoa based Playground to present user interface

import PlaygroundSupport
import SwiftCalc
import SwiftUI

struct ContentView: View {
    @State
    var expression: String = "1 + 1"

    @State
    var result: String = "?"

    var body: some View {
        Form {
            TextField("Expression", text: $expression)
            Text(result)
        }
        .onChange(of: expression) { _ in
            let variables: [String: Value] = [
                "pi": .number(3.14),
                "sin": .function(sin),
            ]

            let program = try Compiler().compile("sin(1) * 10 * pi")
            // program.dump()
            let executor = Executor(variables: variables)
            result = String(describing: try executor.execute(program))
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())

func sin(_ parameters: [Value]) -> Value {
    guard parameters.count == 1, let p0 = parameters.first, case .number(let value) = p0 else {
        fatalError()
    }
    return .number(Darwin.sin(value))
}
