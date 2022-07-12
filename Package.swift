// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "localized-strings-symbols",
    platforms: [.macOS("12.0")],
    products: [
        .plugin(name: "Generate Strings File Symbols", targets: ["Generate Strings File Symbols"]),
        .executable(name: "generate-symbols-tool", targets: ["generate-symbols-tool"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(name: "generate-symbols-tool", dependencies: []),
        .plugin(name: "Generate Strings File Symbols", capability: .buildTool(), dependencies: ["generate-symbols-tool"]),
    ]
)
