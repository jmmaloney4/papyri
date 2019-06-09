// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "PathKit",
  products: [
    .executable(name: "papyri", targets: ["Papyri"]),
    .library(name: "Villa", targets: ["Villa"])
  ],
  dependencies: [
    
  ],
  targets: [
    .target(name: "Papyri", dependencies: [], path: "Sources/"),
    .target(name: "Villa", dependencies:  [], path: "Sources/Villa/")
  ]
)