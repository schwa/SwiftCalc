public extension Atom {
    var s: String? {
        switch self {
        case .value(let value):
            return String(describing: value)
        case .plus:
            return "operator +"
        case .minus:
            return "operator -"
        case .times:
            return "operator *"
        case .negate:
            return "operator unary -"
        case .divide:
            return "operator /"
        case .call:
            return "function"
        }
    }

    var children: [Node]? {
        switch self {
        case .value:
            return nil
        case .plus(let left, let right):
            return [left, right]
        case .minus(let left, let right):
            return [left, right]
        case .times(let left, let right):
            return [left, right]
        case .negate(let left):
            return [left]
        case .divide(let left, let right):
            return [left, right]
        case .call(let name, let parameters):
            return [name] + parameters
        }
    }
}
