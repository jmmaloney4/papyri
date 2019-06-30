// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Papyri",
    products: [
        .executable(name: "papyri", targets: ["Papyri"]),
        .library(name: "Villa", targets: ["Villa"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", from: "5.3.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.5.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "Papyri", dependencies: ["Villa", "SwiftCLI", "SwiftyTextTable", "PathKit"], path: "Sources/papyri/"),
        .target(name: "Villa", dependencies:  ["CryptoSwift", "PathKit", "Yams"], path: "Sources/Villa/")
    ]
)
