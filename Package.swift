// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "papyri",
    dependencies: [
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", from: "5.2.0"),
        
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        // .package(url: "https://github.com/mindbody/Conduit.git", from: "0.16.0")
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "Content", dependencies: ["Vapor"]),
        .target(name: "App", dependencies: ["Content", "FluentSQLite", "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .target(name: "CLI", dependencies: ["App", "SwiftCLI", "Alamofire"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

