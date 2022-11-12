import SwiftCalc
import XCTest

final class SwiftCalcTests: XCTestCase {

    func test1() throws {
        let variables: [String: Value] = [
            "pi": .number(.pi),
            "sin": .function(sin),
        ]
        let program = try Compiler().compile("sin(1) * 10 * pi")
        // program.dump()
        let executor = Executor(variables: variables)
        let result = try executor.execute(program)
        guard case let .number(resultValue) = result else {
            fatalError()
        }
        XCTAssertEqual(resultValue, sin(1) * 10 * .pi)
    }

}

func sin(_ parameters: [Value]) -> Value {
    guard parameters.count == 1, let p0 = parameters.first, case .number(let value) = p0 else {
        fatalError()
    }
    return .number(Darwin.sin(value))
}
