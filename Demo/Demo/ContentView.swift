import SwiftCalc
import SwiftUI

struct ContentView: View {
    @State
    var expression: String = ""

    @State
    var result: Result<(Value, Node), Error>?

    var body: some View {
        HStack {
            Form {
                TextField("Expression", text: $expression)
                LabeledContent("Result") {
                    switch result {
                    case .none:
                        Text("")
                    case .success((let value, let node)):
                        if case let .number(value) = value {
                            Text(String(describing: value))
                        } else {
                            Text("Not a number")
                        }
                    case .failure(let error):
                        Text(String(describing: error))
                    }
                }
            }
        }
        .onChange(of: expression) { expression in
            result = Self.parse(expression: expression)
        }
        .padding()
    }

    static func parse(expression: String) -> Result<(Value, Node), Error> {
        let variables: [String: Value] = Dictionary(uniqueKeysWithValues: Math.all.map { ($0.id, .function($0)) })

        do {
            let program = try Compiler().compile(expression)
            let executor = Executor(variables: variables)
            let value = try executor.execute(program)
            return .success((value, program.root))
        } catch {
            return .failure(error)
        }
    }

//    @ViewBuilder
//    var tree: some View {
//        if let root {
//            List([root], id: \.location, children: \.atom.children) { node in
//                Text(node.atom.s ?? "<??>")
//            }
//        }
//        else {
//            Text("NO NODE")
//        }
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
