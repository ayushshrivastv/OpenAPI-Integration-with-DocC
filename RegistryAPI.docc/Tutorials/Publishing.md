# Publishing Packages

Learn how to publish your Swift packages to a package registry.

## Overview

Publishing your Swift package to a registry makes it easily accessible to others and enables versioning and dependency management. This guide walks you through the process of preparing and publishing a package.

## Preparing Your Package

Before publishing, ensure your package is properly configured:

1. Verify your Package.swift file has correct metadata:
   ```swift
   // swift-tools-version: 5.7
   import PackageDescription
   
   let package = Package(
       name: "MyLibrary",
       platforms: [.macOS(.v12), .iOS(.v15)],
       products: [
           .library(name: "MyLibrary", targets: ["MyLibrary"]),
       ],
       dependencies: [],
       targets: [
           .target(name: "MyLibrary"),
           .testTarget(name: "MyLibraryTests", dependencies: ["MyLibrary"]),
       ]
   )
   ```

2. Make sure your version tags follow [Semantic Versioning](https://semver.org/) (e.g., `1.0.0`, `1.2.3`)

3. Include a LICENSE file and README.md with clear documentation

## Publishing a New Version

To publish a new version of your package:

```swift
// Create a zip archive of your package
let packageData = createPackageZipArchive() // Implementation depends on your tooling

// Set the authentication token
let authToken = "your-auth-token" // See Authentication guide
let packageScope = "mona"
let packageName = "MyLibrary"
let version = "1.0.0"

// Create publish URL
let publishURL = URL(string: "https://registry.example.com/\(packageScope)/\(packageName)/\(version)")!
var request = URLRequest(url: publishURL)
request.httpMethod = "PUT"
request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
request.setValue("sha256=\(calculateSHA256(packageData))", forHTTPHeaderField: "X-Swift-Package-Signature")

// Set the package data
request.httpBody = packageData

// Send request
let (responseData, response) = try await URLSession.shared.data(for: request)

// Check response status
if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
    print("Package version published successfully!")
}
```

## Handling Responses

The registry returns specific status codes:

| Status Code | Meaning |
|-------------|---------|
| 201 | Created - version published successfully |
| 202 | Accepted - version queued for processing |
| 409 | Conflict - version already exists |
| 422 | Unprocessable - invalid package |

## Version Management

When publishing versions:

- Once a version is published, it cannot be changed
- You can publish new versions with increasing version numbers
- Follow semantic versioning guidelines for compatibility

## Next Steps

- Explore endpoint details for more information on the publishing process
- Learn about managing package releases and metadata 
