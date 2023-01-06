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
        .package(url: "https://github.com/ProcedureKit/ProcedureKit.git", .exact("5.2.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("4.9.1")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.3.0")
        ],
    targets: [
        .target(
            name: "EndpointProcedure",
            dependencies: ["ProcedureKit"],
            path: "Sources/Core"),
        .testTarget(
            name: "EndpointProcedureTests",
            dependencies: ["EndpointProcedure", "ProcedureKit"],
            path: "Tests/Core"),
        .target(
            name: "AlamofireProcedureFactory",
            dependencies: ["ProcedureKit", "Alamofire", "EndpointProcedure"],
            path: "Sources/Alamofire"),
        .testTarget(
            name: "AlamofireProcedureFactoryTests",
            dependencies: ["AlamofireProcedureFactory", "ProcedureKit", "Alamofire", "EndpointProcedure", "SwiftyJSON"],
            path: "Tests/Alamofire"),
        .target(
            name: "DecodingProcedureFactory",
            dependencies: ["ProcedureKit", "EndpointProcedure"],
            path: "Sources/Decoding"),
        .testTarget(
            name: "DecodingProcedureFactoryTests",
            dependencies: ["DecodingProcedureFactory", "ProcedureKit", "EndpointProcedure"],
            path: "Tests/Decoding"),
        ],
    swiftLanguageVersions: [.v5]
)
