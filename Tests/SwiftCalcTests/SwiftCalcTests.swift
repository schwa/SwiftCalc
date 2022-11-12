import SwiftCalc
import XCTest

final class SwiftCalcTests: XCTestCase {
    func test1() throws {
        let variables: [String: Value] = [
            "pi": .number(.pi),
            "sin": .function(Math.sin),
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
