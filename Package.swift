// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "EndpointProcedure",
    products: [
        .library(name: "EndpointProcedure", targets: ["EndpointProcedure"]),
        .library(name: "AlamofireProcedureFactory", targets: ["AlamofireProcedureFactory"]),
        .library(name: "DecodingProcedureFactory", targets: ["DecodingProcedureFactory"])
        ],
    dependencies: [
        .package(url: "https://github.com/sviatoslav/ProcedureKit.git", from: "4.5.1"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.7.3"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
        ],
    targets: [
        .target(
            name: "EndpointProcedure",
            dependencies: [.product(name: "ProcedureKit", package: "ProcedureKit")],
            path: "Sources/Core"),
        .testTarget(
            name: "EndpointProcedureTests",
            dependencies: ["EndpointProcedure", .product(name: "ProcedureKit", package: "ProcedureKit")],
            path: "Tests/Core"),
        .target(
            name: "AlamofireProcedureFactory",
            dependencies: [.product(name: "ProcedureKit", package: "ProcedureKit"), "Alamofire", "EndpointProcedure"],
            path: "Sources/Alamofire"),
        .testTarget(
            name: "AlamofireProcedureFactoryTests",
            dependencies: ["AlamofireProcedureFactory", .product(name: "ProcedureKit", package: "ProcedureKit"), "Alamofire", "EndpointProcedure", "SwiftyJSON"],
            path: "Tests/Alamofire"),
        .target(
            name: "DecodingProcedureFactory",
            dependencies: [.product(name: "ProcedureKit", package: "ProcedureKit"), "EndpointProcedure"],
            path: "Sources/Decoding"),
        .testTarget(
            name: "DecodingProcedureFactoryTests",
            dependencies: ["DecodingProcedureFactory", .product(name: "ProcedureKit", package: "ProcedureKit"), "EndpointProcedure"],
            path: "Tests/Decoding"),
        ],
    swiftLanguageVersions: [4]
)
