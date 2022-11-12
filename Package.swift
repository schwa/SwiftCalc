// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCalc",
    products: [
        .library(
            name: "SwiftCalc",
            targets: ["SwiftCalc"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "parser"),
        .target(name: "SwiftCalc", dependencies: ["parser"]),
        .testTarget(name: "SwiftCalcTests", dependencies: ["SwiftCalc"]),
    ]
)
