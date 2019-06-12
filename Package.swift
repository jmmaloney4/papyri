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
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "Papyri", dependencies: ["Villa"], path: "Sources/papyri/"),
        .target(name: "Villa", dependencies:  ["CryptoSwift", "PathKit"], path: "Sources/Villa/")
    ]
)
