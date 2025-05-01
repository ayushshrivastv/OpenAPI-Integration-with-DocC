# Getting Started with Swift Package Registry

Learn how to use the Swift Package Registry API to discover and retrieve packages.

## Overview

The Swift Package Registry API provides a standardized way to interact with package repositories. This guide will help you understand the basic operations and how to make your first API calls.

## Discovering Packages

To find a package in the registry, you can use the package identifier lookup endpoint:

```swift
// Find all packages matching a partial name
let url = URL(string: "https://registry.example.com/identifiers?query=networking")!
let (data, _) = try await URLSession.shared.data(from: url)
// Parse the JSON response
let identifiers = try JSONDecoder().decode([Identifier].self, from: data)
```

## Retrieving Package Information

Once you have a package identifier, you can retrieve detailed information:

```swift
// Get information about a specific package
let packageScope = "mona"
let packageName = "LinkedList"
let url = URL(string: "https://registry.example.com/\(packageScope)/\(packageName)")!
let (data, _) = try await URLSession.shared.data(from: url)
// Parse the JSON response
let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)
```

## Downloading a Package Version

To download a specific version of a package:

```swift
// Download a specific version
let packageScope = "mona"
let packageName = "LinkedList"
let version = "1.1.1"
let url = URL(string: "https://registry.example.com/\(packageScope)/\(packageName)/\(version).zip")!
let (zipData, _) = try await URLSession.shared.data(from: url)
// Save or process the zip file
try zipData.write(to: zipFileURL)
```

## Next Steps

- Learn about <doc:Authentication> to access private packages
- Explore how to <doc:Publishing> your own packages to the registry
- Review the full API reference for detailed endpoint information 
