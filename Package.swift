// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreDataStack",
    platforms: [.iOS("16.4"), .macOS("13.3")],
    products: [
        .library(name: "CoreDataStack", targets: ["CoreDataStack"]),
    ],
    dependencies: [
        .package(url: "git@github.com:iam-bartl/SwiftToolbox.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "CoreDataStack", dependencies: [
            .product(name: "Identifier", package: "SwiftToolbox")
        ]),
    ]
)
