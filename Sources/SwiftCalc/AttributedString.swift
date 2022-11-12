//
//  File.swift
//  
//
//  Created by Jonathan Wight on 11/11/22.
//

import Foundation
import SwiftUI

@available(macOS 12, *)
public extension AttributedString {

    init(program: CompiledProgram) {
        let source = program.root.location!.source
        var string = AttributedString(source)
        var nodes: [Node] = [program.root]
        var current = nodes.startIndex
        while current != nodes.endIndex {
            if let children = nodes[current].atom.children {
                nodes += children
            }
            current = nodes.index(after: current)
        }

        for node in nodes {
            guard let location = node.location else {
                continue
            }

            let start = source.distance(from: source.startIndex, to: location.range.lowerBound)
            let end = source.distance(from: source.startIndex, to: location.range.upperBound)

            let astart = string.index(string.startIndex, offsetByCharacters: start)
            let aend = string.index(string.startIndex, offsetByCharacters: end)

            switch node.atom {
            case .value(let value):
                switch value {
                case .variable:
                    string[astart..<aend].foregroundColor = .green
                case .number:
                    string[astart..<aend].foregroundColor = .blue
                default:
                    break
                }
            case .divide, .minus, .plus, .times:
                string[astart..<aend].foregroundColor = .purple
            default:
                string[astart..<aend].foregroundColor = .black
            }
        }

        self = string
    }

}
