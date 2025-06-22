// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "Revelio",
  products: [
    .library(
      name: "Revelio",
      targets: ["Revelio"]
    ),
  ],
  targets: [
    .target(
      name: "Revelio",
      dependencies: [
        "RevelioC",
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("StrictConcurrency"),
      ],
    ),
    .target(name: "RevelioC"),
    .testTarget(
      name: "RevelioTests",
      dependencies: [
        "Revelio",
      ]
    ),
  ],
)
