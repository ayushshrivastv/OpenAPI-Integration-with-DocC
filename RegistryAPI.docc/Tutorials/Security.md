# Security Best Practices

Learn how to securely interact with the Swift Package Registry API.

## Overview

Security is a critical aspect of package management. This guide covers best practices for securely interacting with the Swift Package Registry API, protecting sensitive information, and verifying package authenticity.

## Secure Authentication

### Token Management

When working with authentication tokens:

- **Never hardcode tokens** in your application source code
- Use environment variables, secure storage, or a secrets management solution
- Rotate tokens regularly following the principle of least privilege
- Set appropriate token expiration times

```swift
// ❌ INCORRECT: Hardcoded token
let apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// ✅ BETTER: Load from secure storage
let apiToken = try KeychainManager.getToken(forService: "registry-api")

// ✅ BEST: Use a token provider with automatic rotation
let apiToken = try await TokenProvider.shared.getValidToken()
```

### Secure Token Storage

Store your tokens securely using platform-appropriate mechanisms:

```swift
// Example: Secure token storage using keychain on Apple platforms
class KeychainTokenStorage: TokenStorage {
    func saveToken(_ token: String, forService service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api-token",
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Save the new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStorageError.saveFailed(status)
        }
    }
    
    func getToken(forService service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api-token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw TokenStorageError.retrievalFailed(status)
        }
        
        guard let tokenData = result as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw TokenStorageError.invalidData
        }
        
        return token
    }
}
```

## Package Integrity Verification

Always verify package integrity using the provided checksums:

```swift
// Example: Verify package checksum
func verifyPackageIntegrity(packageData: Data, expectedChecksum: String) throws -> Bool {
    // Calculate the SHA-256 hash of the package data
    let computedHash = SHA256.hash(data: packageData)
    let computedChecksum = computedHash.compactMap { String(format: "%02x", $0) }.joined()
    
    // Compare with the expected checksum (case-insensitive)
    return computedChecksum.lowercased() == expectedChecksum.lowercased()
}

// Usage example
func downloadAndVerifyPackage(scope: String, name: String, version: String) async throws -> Data {
    // 1. Get package metadata with checksum information
    let metadataURL = URL(string: "https://registry.example.com/\(scope)/\(name)/\(version)")!
    let (metadataData, _) = try await URLSession.shared.data(from: metadataURL)
    let release = try JSONDecoder().decode(ReleaseResource.self, from: metadataData)
    
    // 2. Find the source archive resource and its checksum
    guard let sourceArchive = release.resources.first(where: { $0.name == "source-archive" }),
          let checksum = sourceArchive.checksum else {
        throw VerificationError.missingChecksumInfo
    }
    
    // 3. Download the package
    let packageURL = URL(string: "https://registry.example.com/\(scope)/\(name)/\(version).zip")!
    let (packageData, _) = try await URLSession.shared.data(from: packageURL)
    
    // 4. Verify the integrity
    guard try verifyPackageIntegrity(packageData: packageData, expectedChecksum: checksum) else {
        throw VerificationError.checksumMismatch
    }
    
    return packageData
}
```

## Transport Security

Always use secure connections when communicating with the registry:

- Ensure your URL connections use HTTPS
- Verify TLS certificates
- Enable certificate pinning for critical applications

```swift
// Example: URL Session configuration with certificate pinning
func createSecureURLSession() -> URLSession {
    let configuration = URLSessionConfiguration.default
    
    // Ensure only HTTPS connections are allowed
    configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
    
    // Create a delegate for certificate pinning
    let delegate = CertificatePinningDelegate()
    
    return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
}

class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, 
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host.hasSuffix("registry.example.com") else {
            // Reject invalid challenges
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get the server's certificate data
        let serverCertificatesData = certificateData(for: serverTrust)
        
        // Get the pinned certificate data
        guard let pinnedCertificateData = loadPinnedCertificateData() else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Compare certificates
        if serverCertificatesData.contains(pinnedCertificateData) {
            // Certificate matched, proceed with connection
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Certificate mismatch, cancel connection
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // Helper methods...
}
```

## Secure Dependency Resolution

Follow these guidelines when resolving package dependencies:

1. **Define exact versions** when possible to prevent unexpected changes
2. **Use package checksums** to validate package integrity during resolution
3. **Lock dependencies** in your Package.resolved file
4. **Audit dependencies** regularly for vulnerabilities

```swift
// Example: Package.swift with pinned dependencies
dependencies: [
    .package(
        url: "https://github.com/apple/swift-algorithms",
        exact: "1.0.0"  // Pin to exact version
    ),
    .package(
        url: "https://github.com/apple/swift-collections",
        revision: "a281e8b846a354fca484a08abbc657dfe39c9b1c"  // Pin to specific commit
    )
]
```

## Content Security

### XSS Protection

When displaying package metadata or README content in your application:

1. Always sanitize content before rendering
2. Use a secure rendering library that handles escaping
3. Consider Content Security Policy (CSP) for web applications

```swift
// Example: Content sanitization for package metadata
func sanitizeHTMLContent(_ html: String) -> String {
    // Use a proper HTML sanitizer library here
    // This is a simplified example
    let disallowedTags = ["script", "iframe", "object", "embed"]
    
    var sanitized = html
    for tag in disallowedTags {
        let openTagPattern = "<\(tag)[^>]*>"
        let closeTagPattern = "</\(tag)>"
        
        sanitized = sanitized.replacingOccurrences(of: openTagPattern, 
                                                  with: "", 
                                                  options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: closeTagPattern, 
                                                  with: "", 
                                                  options: .regularExpression)
    }
    
    return sanitized
}
```

### Input Validation

Always validate input parameters before sending them to the API:

```swift
// Example: Parameter validation
func validatePackageParameters(scope: String, name: String, version: String?) throws {
    // Validate scope
    guard scope.range(of: "^[a-zA-Z0-9][-a-zA-Z0-9_.]*$", options: .regularExpression) != nil else {
        throw ValidationError.invalidScope
    }
    
    // Validate name
    guard name.range(of: "^[a-zA-Z0-9][-a-zA-Z0-9_.]*$", options: .regularExpression) != nil else {
        throw ValidationError.invalidName
    }
    
    // Validate version if provided
    if let version = version {
        guard version.range(of: "^\\d+\\.\\d+\\.\\d+$", options: .regularExpression) != nil else {
            throw ValidationError.invalidVersion
        }
    }
}
```

## Additional Security Measures

### API Key Rotation

Implement regular key rotation to minimize risk:

```swift
// Example: Token rotation schedule
class TokenRotationManager {
    private let tokenStorage: TokenStorage
    private let tokenProvider: TokenProvider
    
    // Rotate tokens every 30 days
    private let rotationInterval: TimeInterval = 30 * 24 * 60 * 60
    
    func scheduleRotation() {
        // Check when the current token was created
        let currentTokenCreationDate = tokenStorage.getTokenCreationDate()
        
        // Calculate time until next rotation
        let timeUntilRotation = max(0, 
            (currentTokenCreationDate.addingTimeInterval(rotationInterval).timeIntervalSince1970 - 
             Date().timeIntervalSince1970))
        
        // Schedule rotation
        DispatchQueue.global().asyncAfter(deadline: .now() + timeUntilRotation) { [weak self] in
            self?.rotateToken()
        }
    }
    
    private func rotateToken() {
        do {
            // Generate new token
            let newToken = try tokenProvider.generateNewToken()
            
            // Save the new token
            try tokenStorage.saveToken(newToken)
            
            // Revoke the old token
            try tokenProvider.revokeToken(tokenStorage.getOldToken())
            
            // Schedule the next rotation
            scheduleRotation()
        } catch {
            // Handle rotation failure
            // Log error and retry after a short delay
        }
    }
}
```

### Logging and Monitoring

Implement secure logging practices:

- Never log sensitive information such as tokens or private package data
- Use structured logging for easy analysis
- Implement monitoring for unusual access patterns

```swift
// Example: Secure logging
enum LogLevel: String {
    case debug, info, warning, error
}

class SecureLogger {
    static func log(_ message: String, level: LogLevel = .info, sensitiveData: Bool = false) {
        // Don't log sensitive data in production
        #if DEBUG
        let logEntry = "[\(level.rawValue.uppercased())] \(Date()): \(message)"
        print(logEntry)
        #else
        if !sensitiveData {
            let logEntry = "[\(level.rawValue.uppercased())] \(Date()): \(message)"
            print(logEntry)
            // In a real implementation, send to logging service
        }
        #endif
    }
    
    static func logAPIRequest(endpoint: String, statusCode: Int?, error: Error?) {
        var message = "API Request: \(endpoint)"
        
        if let statusCode = statusCode {
            message += ", Status: \(statusCode)"
        }
        
        if let error = error {
            message += ", Error: \(error.localizedDescription)"
        }
        
        log(message)
    }
}
```

## See Also

- <doc:Authentication>
- <doc:ErrorCodes> 
