// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "EndpointProcedure",
    products: [
        .library(name: "EndpointProcedure", targets: ["EndpointProcedure"]),
        .library(name: "AlamofireProcedureFactory", targets: ["AlamofireProcedureFactory"]),
        .library(name: "DecodingProcedureFactory", targets: ["DecodingProcedureFactory"])
        ],
    dependencies: [
        .package(url: "https://github.com/ProcedureKit/ProcedureKit.git", from: "5.2.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.8.2"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.3.0")
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
    swiftLanguageVersions: [.v5]
)
