// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppRouterPlus",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "AppRouterPlus", targets: ["AppRouterPlus"])
    ],
    targets: [
        .target(name: "AppRouterPlus")
    ]
)
