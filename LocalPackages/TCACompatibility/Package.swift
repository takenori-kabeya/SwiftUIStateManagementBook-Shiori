// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport


/// TCA 1.26.1 compatibility shim
let package = Package(
    name: "TCACompatibility",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "TCACompatibility",
            targets: ["TCACompatibility"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0-latest"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.1"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.0.2"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.5.4"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.4"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.2"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.4.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", "1.3.4"..<"3.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", "1.0.0"..<"3.0.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.3.0"),
        
    ],
    targets: [
        .macro(
            name: "TCACompatibilityMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        .target(name: "TCACompatibility",
                dependencies: [
                    "TCACompatibilityMacros",
                    .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                    .product(name: "CasePaths", package: "swift-case-paths"),
                    .product(name: "Clocks", package: "swift-clocks"),
                    .product(name: "CombineSchedulers", package: "combine-schedulers"),
                    .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                    .product(name: "CustomDump", package: "swift-custom-dump"),
                    .product(name: "Dependencies", package: "swift-dependencies"),
                    .product(name: "DependenciesMacros", package: "swift-dependencies"),
                    .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                    .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                    .product(name: "OrderedCollections", package: "swift-collections"),
                    .product(name: "Perception", package: "swift-perception"),
                    .product(name: "Sharing", package: "swift-sharing"),
                    .product(name: "SwiftUINavigation", package: "swift-navigation"),
                    .product(name: "UIKitNavigation", package: "swift-navigation"),
                ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
