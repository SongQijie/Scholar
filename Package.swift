// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Scholar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Scholar",
            targets: ["ScholarApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ScholarApp",
            path: "Scholar",
            exclude: ["Assets.xcassets", "Info.plist"],
            resources: [.process("Resources")]
        )
    ]
)
