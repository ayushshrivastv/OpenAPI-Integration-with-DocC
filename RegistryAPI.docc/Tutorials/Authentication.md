# Authentication

Learn how to authenticate with the Swift Package Registry API for accessing private packages and publishing.

## Overview

The Swift Package Registry API uses token-based authentication to secure access to private packages and privileged operations like publishing. This guide explains how to authenticate your requests.

## Obtaining an Authentication Token

To get an authentication token, you'll typically use the login endpoint:

```swift
// Create login request
let loginURL = URL(string: "https://registry.example.com/login")!
var request = URLRequest(url: loginURL)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

// Set credentials - implementation depends on registry provider
let credentials = ["username": "your-username", "password": "your-password"]
request.httpBody = try JSONEncoder().encode(credentials)

// Send request
let (data, response) = try await URLSession.shared.data(for: request)

// Parse token from response
let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
let authToken = tokenResponse.token
```

## Using Authentication Tokens

Once you have a token, include it in your request headers:

```swift
// Create authenticated request
let packageURL = URL(string: "https://registry.example.com/mona/LinkedList/1.1.1")!
var request = URLRequest(url: packageURL)

// Add the authorization header
request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

// Send request
let (data, response) = try await URLSession.shared.data(for: request)
```

## Token Management

Authentication tokens typically have an expiration period. You should:

1. Store tokens securely (e.g., in the keychain on Apple platforms)
2. Handle token refresh when tokens expire
3. Never expose tokens in client-side code for public applications

## Authentication for Different Operations

Different operations may require different scopes or permissions:

| Operation | Required Permissions |
|-----------|---------------------|
| Read public packages | None (anonymous access) |
| Read private packages | `read` scope |
| Publish packages | `write` scope |
| Manage organization | `admin` scope |

## Next Steps

- Learn how to <doc:Publishing> packages to the registry
- Review specific endpoint documentation for authorization requirements 
