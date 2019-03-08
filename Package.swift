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
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.0.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.8.0")
    ],
    targets: [
        .target(name: "Content", dependencies: ["Vapor"]),
        .target(name: "Client", dependencies: ["Content", "Alamofire"]),

        .target(name: "CLI", dependencies: ["Content", "SwiftCLI", "Alamofire", "SwiftyTextTable", "Client"]),

        .target(name: "Server", dependencies: ["Content", "FluentSQLite", "Vapor"]),
        .target(name: "Run", dependencies: ["Server"]),
        .testTarget(name: "AppTests", dependencies: ["Server"])
    ]
)

