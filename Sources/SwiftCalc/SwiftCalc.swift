import Foundation
import parser

public enum ParseError: Error {
    case invalidFile
    case invalidOptions
    case invalidToken
    case unexpectedToken
    case moreInputNeeded

    static func underlying(_ error: owl_error) -> ParseError {
        switch error {
        case ERROR_INVALID_FILE:
            return .invalidFile
        case ERROR_INVALID_OPTIONS:
            return .invalidOptions
        case ERROR_INVALID_TOKEN:
            return .invalidToken
        case ERROR_UNEXPECTED_TOKEN:
            return .unexpectedToken
        case ERROR_MORE_INPUT_NEEDED:
            return .moreInputNeeded
        default:
            fatalError("Unknown error type \(error).")
        }
    }
}

public enum ExecutionError: Error {
    case unknownError
    case unknownVariable(String)
    case parameterError
    case typeMismatch
}

public enum Value {
    case function(Function)
    case number(Double)
    case integer(Int)
    case string(String)
    case variable(String)
}

public struct Function: Identifiable {
    public let id: String
    public let closure: ([Value]) throws -> Value

    public func callAsFunction(_ parameters: [Value]) throws -> Value {
        return try closure(parameters)
    }

    public init(_ id: String, _ closure: @escaping ([Value]) throws -> Value) {
        self.id = id
        self.closure = closure
    }
}

extension Value: Equatable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        switch (lhs, rhs) {
        case (.function(let lhs), .function(let rhs)):
            return lhs.id == rhs.id
        case (.number(let lhs), .number(let rhs)):
            return lhs == rhs
        case (.integer(let lhs), .integer(let rhs)):
            return lhs == rhs
        case (.string(let lhs), .string(let rhs)):
            return lhs == rhs
        case (.variable(let lhs), .variable(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

public struct Location: Hashable {
    public let source: String
    public let range: Range<String.Index>
}

public struct Node {
    public let location: Location?
    public let atom: Atom
}

public indirect enum Atom {
    case value(Value)
    case plus(Node, Node)
    case minus(Node, Node)
    case times(Node, Node)
    case negate(Node)
    case divide(Node, Node)
    case call(Node, [Node])
}

// MARK: -

public struct Compiler {
    public init() {
    }

    public func compile(_ source: String) throws -> CompiledProgram {
        let session = CompilerSession(source: source)
        return try session.compile()
    }
}

// MARK: -

internal struct CompilerSession {
    let source: String

    init(source: String) {
        self.source = source
    }

    func compile() throws -> CompiledProgram {
        let tree = owl_tree_create_from_string(source)

        var range = source_range()
        let error = owl_tree_get_error(tree, &range)
        guard error == ERROR_NONE else {
            throw ParseError.underlying(error)
        }

        let expression = owl_tree_get_parsed_expression(tree)
        let root = try atomize(expression)
        owl_tree_destroy(tree)
        return CompiledProgram(source: source, root: root)
    }

    func atomize(_ expression: parsed_expression) throws -> Node {
        let atom: Atom
        switch expression.type {
        case PARSED_NUMBER:
            atom = .value(.number(parsed_number_get(expression.number).number))
        case PARSED_VARIABLE:
            let identifier = parsed_identifier_get(expression.identifier)
            //            let d = Data(bytes: identifier.identifier, count: identifier.length)
            //            let s = String(data: d, encoding: .utf8)!
            let s = source[identifier.range]
            atom = .value(.variable(s))
        case PARSED_ADD:
            let left = try atomize(expression.left)
            let right = try atomize(expression.right)
            atom = .plus(left, right)
        case PARSED_SUBTRACT:
            let left = try atomize(expression.left)
            let right = try atomize(expression.right)
            atom = .minus(left, right)
        case PARSED_MULTIPLY:
            let left = try atomize(expression.left)
            let right = try atomize(expression.right)
            atom = .times(left, right)
        case PARSED_NEGATE:
            let operand = try atomize(expression.operand)
            atom = .negate(operand)
        case PARSED_PARENS:
            atom = try atomize(expression.expression).atom
        case PARSED_DIVIDE:
            let left = try atomize(expression.left)
            let right = try atomize(expression.right)
            atom = .divide(left, right)
        case PARSED_CALL:
            let operand = try atomize(expression.operand)
            var parameters: [Node] = []
            var parameter = expression.expression
            while !parameter.empty {
                parameters.append(try atomize(parameter))
                parameter = owl_next(parameter)
            }
            atom = .call(operand, parameters)
        default:
            fatalError("Error: \(expression.type)")
        }

        let location = Location(source: source, range: source.range(expression.range))
        return Node(location: location, atom: atom)
    }

    func atomize(_ ref: owl_ref) throws -> Node {
        let expression = parsed_expression_get(ref)
        return try atomize(expression)
    }
}

public struct CompiledProgram {
    public let source: String
    public let root: Node

    public func dump() {
        Swift.dump(root)
    }
}

public struct Executor {
    let variables: [String: Value]

    public init(variables: [String: Value] = [:]) {
        self.variables = variables
    }

    public func execute(_ program: CompiledProgram) throws -> Value {
        let value = try evaluate(program.root)
        let resolved = try resolve(value)

        return resolved
    }

    public func evaluate(_ node: Node) throws -> Value {
        switch node.atom {
        case .value(let num):
            return num
        case .plus(let left, let right):
            switch (try resolve(evaluate(left)), try resolve(evaluate(right))) {
            case (.number(let left), .number(let right)):
                return .number(left + right)
            default:
                throw ExecutionError.typeMismatch
            }
        case .minus(let left, let right):
            switch (try resolve(evaluate(left)), try resolve(evaluate(right))) {
            case (.number(let left), .number(let right)):
                return .number(left - right)
            default:
                throw ExecutionError.typeMismatch
            }
        case .times(let left, let right):
            let (left, right) = (try resolve(evaluate(left)), try resolve(evaluate(right)))
            switch (left, right) {
            case (.number(let left), .number(let right)):
                return .number(left * right)
            default:
                throw ExecutionError.typeMismatch
            }
        case .negate(let value):
            switch try resolve(evaluate(value)) {
            case .number(let value):
                return .number(-value)
            default:
                throw ExecutionError.typeMismatch
            }
        case .divide(let left, let right):
            switch (try resolve(evaluate(left)), try resolve(evaluate(right))) {
            case (.number(let left), .number(let right)):
                return .number(left / right)
            default:
                throw ExecutionError.typeMismatch
            }
        case .call(let callee, let parameters):
            switch try resolve(evaluate(callee)) {
            case .function(let function):
                let parameters = try parameters.map { try resolve(evaluate($0)) }
                return try function(parameters)
            default:
                throw ExecutionError.typeMismatch
            }
        }
    }

    public func resolve(_ value: Value) throws -> Value {
        switch value {
        case .variable(let variable):
            guard let value = variables[variable] else {
                throw ExecutionError.unknownVariable(variable)
            }
            return try resolve(value)
        default:
            return value
        }
    }
}

// MARK: -

internal extension String {
    func range(_ r: source_range) -> Range<Index> {
        index(startIndex, offsetBy: r.start) ..< index(startIndex, offsetBy: r.end)
    }

    subscript(r: source_range) -> String {
        String(utf8[utf8.index(utf8.startIndex, offsetBy: r.start) ..< utf8.index(utf8.startIndex, offsetBy: r.end)])!
    }
}
