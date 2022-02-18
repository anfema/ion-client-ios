// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IONClient",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IONClient",
            targets: ["ion_client"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            .exact("0.12.0")
        ),
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            .exact("4.9.0")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ion_client",
            path: "IONClientSample/IONClient"
        ),
    ]
)
