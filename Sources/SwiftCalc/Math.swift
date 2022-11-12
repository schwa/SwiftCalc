import Foundation

public enum Math {
}

extension Array where Element == Value {
    var doubles: [Double] {
        get throws {
            return try map {
                guard case let .number(value) = $0 else {
                    throw ExecutionError.parameterError
                }
                return value
            }
        }
    }
}

extension Array {
    var onlyElement: Element {
        get throws {
            guard count == 1, let first else {
                throw ExecutionError.parameterError
            }
            return first
        }
    }
}

public extension Math {

    static let all = [
        Function("sin") { parameters in
            return try .number(Darwin.sin(parameters.doubles.onlyElement))
        },
        Function("cos") { parameters in
            return try .number(Darwin.cos(parameters.doubles.onlyElement))
        },
        Function("random") { parameters in
            guard parameters.isEmpty else {
                throw ExecutionError.parameterError
            }
            return .number(Double.random(in: 0...1))
        }
    ]

}
