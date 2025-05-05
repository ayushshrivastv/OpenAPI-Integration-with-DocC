# ``RegistryAPI/PackageMetadata``

A comprehensive representation of metadata for a Swift package.

## Overview

The `PackageMetadata` structure contains all descriptive information about a Swift package, including details about the package's author, license, and available versions.

```swift
// Example: Fetching and using package metadata
let url = URL(string: "https://registry.example.com/mona/LinkedList")!
let (data, _) = try await URLSession.shared.data(from: url)
let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)

// Use metadata properties
print("Package name: \(metadata.name)")
print("Latest version: \(metadata.latestVersion)")
print("Available versions: \(metadata.versions.joined(separator: ", "))")
```

Package metadata provides a complete picture of a package, including:

- Basic information like name, version, and description
- Author and organization information
- License details
- Repository location
- Available versions

## Topics

### Essential Properties

- ``name``
- ``description``
- ``version``
- ``latestVersion``

### Author Information

- ``author``
- ``PackageAuthor``
- ``organization``
- ``PackageOrganization``

### Package Versions

- ``versions``
- ``listedVersions``
- ``ListedRelease``

### Package Resources

- ``repository``
- ``license``
- ``readmeURL``
- ``keywords``

## Structure

```json
{
  "name": "LinkedList",
  "description": "A linked list implementation for Swift",
  "keywords": ["data-structure", "list", "collection"],
  "version": "1.1.1",
  "author": {
    "name": "J. Appleseed",
    "email": "japplseed@example.com",
    "url": "https://example.com/japplseed"
  },
  "organization": {
    "name": "Example Organization",
    "url": "https://example.com",
    "description": "Organization that maintains the package"
  },
  "license": {
    "name": "MIT",
    "url": "https://opensource.org/licenses/MIT"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/mona/LinkedList.git"
  },
  "readmeURL": "https://registry.example.com/mona/LinkedList/1.1.1/README.md",
  "latestVersion": "1.1.1",
  "versions": ["1.0.0", "1.0.1", "1.1.0", "1.1.1"]
}
```

## Accessing Metadata

You can retrieve package metadata using the package identifier endpoint:

```swift
func fetchPackageMetadata(scope: String, name: String) async throws -> PackageMetadata {
    let url = URL(string: "https://registry.example.com/\(scope)/\(name)")!
    
    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200..<300).contains(httpResponse.statusCode) else {
        throw FetchError.invalidResponse
    }
    
    return try JSONDecoder().decode(PackageMetadata.self, from: data)
}
```

## Required and Optional Fields

The following fields are required in every package metadata response:

- `name`: Package name
- `version`: Current version
- `description`: Brief description of the package
- `license`: License information

All other fields are optional and may not be present in all responses.

## Handling Missing Fields

When working with package metadata, it's important to handle optional fields gracefully:

```swift
// Example: Handling optional fields
func displayPackageInfo(_ metadata: PackageMetadata) {
    // Required fields
    print("Package: \(metadata.name)")
    print("Description: \(metadata.description)")
    
    // Optional fields
    if let author = metadata.author {
        print("Author: \(author.name)")
        if let email = author.email {
            print("Contact: \(email)")
        }
    }
    
    if let org = metadata.organization {
        print("Organization: \(org.name)")
    }
    
    // Keywords
    if let keywords = metadata.keywords, !keywords.isEmpty {
        print("Keywords: \(keywords.joined(separator: ", "))")
    }
}
```

## See Also

- ``RegistryAPI/__scope___name_``
- ``RegistryAPI/ReleaseResource``
- ``RegistryAPI/ListedRelease`` 
 