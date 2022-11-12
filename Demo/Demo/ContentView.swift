import SwiftCalc
import SwiftUI

struct ContentView: View {
    @State
    var expression: String = ""

    @State
    var result: Result<Value, Error>?

    @State
    var root: Node?

    var body: some View {
        HStack {
            Form {
                TextField("Expression", text: $expression)
                switch result {
                case .success(let value):
                    Text(String(describing: value))
                case .failure(let error):
                    Text(String(describing: error))
                case .none:
                    Text("?")
                }
            }
            tree
                .frame(width: 320)
        }
        .onChange(of: expression) { expression in
            let variables: [String: Value] = [
                "pi": .number(.pi),
                "sin": .function(sin),
            ]

            do {
                let program = try Compiler().compile(expression)
                self.root = program.root
                // program.dump()
                let executor = Executor(variables: variables)
                result = .success(try executor.execute(program))
            }
            catch {
                result = .failure(error)
            }
        }
    }

    @ViewBuilder
    var tree: some View {
        if let root {
            List([root], id: \.location, children: \.atom.children) { node in
                Text(node.atom.s ?? "<??>")
            }
        }
        else {
            Text("NO NODE")
        }
    }
}

func sin(_ parameters: [Value]) -> Value {
    guard parameters.count == 1, let p0 = parameters.first, case .number(let value) = p0 else {
        fatalError()
    }
    return .number(Darwin.sin(value))
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
