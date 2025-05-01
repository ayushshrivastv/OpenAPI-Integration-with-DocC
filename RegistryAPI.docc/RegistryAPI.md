# ``RegistryAPI``

@Metadata {
    @DisplayName("Registry API")
    @TitleHeading("Swift Package Registry API")
    @DocumentationExtension(mergeBehavior: append)
}

Interact with Swift packages through a standardized API for publishing, discovering, and retrieving packages.

## Overview

The Swift Package Registry API provides a robust interface for package management that follows open standards. Using this API, you can:

- **Discover** packages through search and metadata
- **Retrieve** package releases including source code and manifests
- **Publish** your own packages for others to use
- **Authenticate** to access private packages or perform privileged operations

![A diagram showing the workflow of package discovery, retrieval and publishing](registry_workflow.png)

The API follows RESTful principles with well-defined endpoints for each resource type. All requests and responses use standard HTTP methods and status codes, with JSON-formatted data.

```swift
// Example: Retrieve package metadata
let url = URL(string: "https://registry.example.com/mona/LinkedList")!
let (data, response) = try await URLSession.shared.data(from: url)
let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)

print("Package: \(metadata.name)")
print("Latest version: \(metadata.latestVersion)")
print("Available versions: \(metadata.versions.joined(separator: ", "))")
```

## Topics

### API Endpoints

- <doc:GettingStarted>
- ``_identifiers``
- ``_login``
- ``__scope___name_``
- ``__scope___name___version_``
- ``__scope___name___version_.zip``
- ``__scope___name___version__package.swift``

### Data Models

- ``PackageMetadata``
- ``ReleaseResource``
- ``ProblemDetails``
- ``Identifier``
- ``Identifiers``
- ``Releases``
- ``ReleaseMetadata``
- ``ReleaseSignature``
- ``PublishResponse``

### Guides

- <doc:Authentication>
- <doc:Publishing>
- <doc:ErrorCodes>
- <doc:RateLimiting>
- <doc:Security>
- <doc:Performance>
