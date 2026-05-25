// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Axiom",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Axiom", targets: ["Axiom"]),
        .library(name: "AxiomCore", targets: ["AxiomCore"]),
        .library(name: "AxiomRelayBridge", targets: ["AxiomRelayBridge"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/AgentWorkforce/relay.git",
            revision: "0a2c878748dc34af8b617c8da5ce70af447dfa37"
        )
    ],
    targets: [
        .target(
            name: "AxiomCore",
            path: "Sources/AxiomCore"
        ),
        .target(
            name: "AxiomRelayBridge",
            dependencies: [
                "AxiomCore",
                .product(name: "AgentRelaySDK", package: "relay")
            ],
            path: "Sources/AxiomRelayBridge"
        ),
        .executableTarget(
            name: "Axiom",
            dependencies: [
                "AxiomCore",
                "AxiomRelayBridge",
                .product(name: "AgentRelaySDK", package: "relay")
            ],
            path: "Sources/Axiom"
        ),
        .testTarget(
            name: "AxiomCoreTests",
            dependencies: ["AxiomCore"],
            path: "Tests/AxiomCoreTests"
        )
    ]
)
