# ``RegistryAPI``

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

### Getting Started

- <doc:GettingStarted>
- <doc:Authentication>
- <doc:Publishing>

### Core Concepts

- ``RegistryAPI/PackageMetadata``
- ``RegistryAPI/ReleaseResource``
- ``RegistryAPI/Identifier``

### Package Discovery

- ``RegistryAPI/_identifiers``
- ``RegistryAPI/__scope___name_``

### Package Retrieval

- ``RegistryAPI/__scope___name___version_``
- ``RegistryAPI/__scope___name___version_.zip``
- ``RegistryAPI/__scope___name___version__package.swift``

### Package Publishing

- ``RegistryAPI/__scope___name___version_/put``

### Authentication

- ``RegistryAPI/_login``

### Error Handling

- ``RegistryAPI/ProblemDetails``
- <doc:ErrorCodes>

### Best Practices

- <doc:RateLimiting>
- <doc:Security>
- <doc:Performance>
