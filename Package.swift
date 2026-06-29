// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tessera",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "TesseraCore", targets: ["TesseraCore"])
    ],
    targets: [
        .target(name: "TesseraCore", path: "Sources/TesseraCore"),
        .testTarget(name: "TesseraCoreTests", dependencies: ["TesseraCore"], path: "Tests/TesseraCoreTests")
    ]
)
