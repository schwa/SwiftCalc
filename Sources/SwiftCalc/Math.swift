import Foundation

public enum Math {
}

public extension Math {
    static let sin = Function("sin") { parameters in
        guard parameters.count == 1, let p0 = parameters.first, case .number(let value) = p0 else {
            fatalError()
        }
        return .number(Darwin.sin(value))
    }

}
