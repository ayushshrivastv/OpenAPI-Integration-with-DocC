# Rate Limiting

Learn about the Swift Package Registry's rate limiting mechanisms and how to optimize your usage.

## Overview

The Swift Package Registry API implements rate limiting to ensure fair usage and system stability. Understanding these limits and implementing proper handling will improve your application's reliability when interacting with the registry.

## Rate Limiting Headers

When you make requests to the API, the following headers are included in every response:

| Header | Description |
|--------|-------------|
| `RateLimit-Limit` | Maximum number of requests allowed in the current time window |
| `RateLimit-Remaining` | Number of requests remaining in the current time window |
| `RateLimit-Reset` | Time when the current rate limit window resets (UTC epoch seconds) |

```swift
// Example: Checking rate limiting headers
func checkRateLimits(from response: HTTPURLResponse) -> RateLimitInfo {
    let limit = Int(response.value(forHTTPHeaderField: "RateLimit-Limit") ?? "60") ?? 60
    let remaining = Int(response.value(forHTTPHeaderField: "RateLimit-Remaining") ?? "0") ?? 0
    let resetTime = TimeInterval(response.value(forHTTPHeaderField: "RateLimit-Reset") ?? "0") ?? 0
    
    return RateLimitInfo(
        limit: limit, 
        remaining: remaining, 
        resetDate: Date(timeIntervalSince1970: resetTime)
    )
}
```

## Rate Limit Tiers

The API has different rate limit tiers depending on your authentication status:

| Tier | Requests per Hour | Description |
|------|-------------------|-------------|
| Anonymous | 60 | Unauthenticated requests |
| Authenticated | 1,000 | Requests with a valid user token |
| Service | 5,000 | Requests with a service token |

## Handling Rate Limiting

When you exceed your rate limit, the API responds with a `429 Too Many Requests` status code and includes a `Retry-After` header indicating how many seconds to wait before retrying.

```swift
// Example: Rate limit handling with backoff
func makeRegistryRequest(_ request: URLRequest) async throws -> Data {
    let session = URLSession.shared
    
    do {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegistryError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            // We hit a rate limit
            if let retryAfterString = httpResponse.value(forHTTPHeaderField: "Retry-After"),
               let retryAfter = TimeInterval(retryAfterString) {
                
                // Wait for the specified time before retrying
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                
                // Retry the request
                return try await makeRegistryRequest(request)
            } else {
                throw RegistryError.rateLimitExceeded
            }
        }
        
        // Handle other status codes...
        
        return data
    } catch {
        // Handle network errors
        throw error
    }
}
```

## Best Practices

### 1. Monitor Your Usage

Always check rate limit headers and keep track of your consumption to avoid hitting limits:

```swift
class RegistryClient {
    private var rateLimitInfo: RateLimitInfo?
    
    func updateRateLimitInfo(from response: HTTPURLResponse) {
        rateLimitInfo = checkRateLimits(from: response)
        
        // Log when close to limit
        if let info = rateLimitInfo, info.remaining < info.limit * 0.1 {
            print("Warning: Rate limit nearly reached. \(info.remaining) requests remaining until \(info.resetDate)")
        }
    }
    
    // Other methods...
}
```

### 2. Implement Caching

Reduce your API calls by caching responses appropriately:

```swift
class RegistryClient {
    private var cache = NSCache<NSString, CachedResponse>()
    
    func fetchPackageMetadata(scope: String, name: String) async throws -> PackageMetadata {
        let cacheKey = "\(scope)/\(name)" as NSString
        
        // Check cache first
        if let cachedResponse = cache.object(forKey: cacheKey),
           cachedResponse.expirationDate > Date() {
            return cachedResponse.metadata
        }
        
        // Make API request
        let url = URL(string: "https://registry.example.com/\(scope)/\(name)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Update rate limit info
        if let httpResponse = response as? HTTPURLResponse {
            updateRateLimitInfo(from: httpResponse)
        }
        
        // Parse and cache response
        let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)
        
        // Cache for 5 minutes
        let cachedResponse = CachedResponse(
            metadata: metadata,
            expirationDate: Date().addingTimeInterval(5 * 60)
        )
        cache.setObject(cachedResponse, forKey: cacheKey)
        
        return metadata
    }
}
```

### 3. Use Conditional Requests

When appropriate, use ETag or Last-Modified headers to make conditional requests:

```swift
func fetchPackageWithETag(scope: String, name: String) async throws -> PackageMetadata {
    let url = URL(string: "https://registry.example.com/\(scope)/\(name)")!
    var request = URLRequest(url: url)
    
    // Add ETag if we have it
    if let etag = etagStorage["\(scope)/\(name)"] {
        request.addValue(etag, forHTTPHeaderField: "If-None-Match")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw RegistryError.invalidResponse
    }
    
    // Update rate limit info
    updateRateLimitInfo(from: httpResponse)
    
    // Store new ETag if present
    if let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
        etagStorage["\(scope)/\(name)"] = newETag
    }
    
    // If 304 Not Modified, return cached data
    if httpResponse.statusCode == 304 {
        guard let cachedMetadata = metadataCache["\(scope)/\(name)"] else {
            throw RegistryError.cacheInconsistency
        }
        return cachedMetadata
    }
    
    // Process new data
    let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)
    metadataCache["\(scope)/\(name)"] = metadata
    return metadata
}
```

### 4. Batch Requests When Possible

Instead of making multiple small requests, batch them when the API supports it:

```swift
// Instead of fetching packages one by one
func fetchMultiplePackageIdentifiers(query: String) async throws -> [Identifier] {
    // Use the search endpoint with multiple criteria
    let url = URL(string: "https://registry.example.com/identifiers?query=\(query)&limit=100")!
    let (data, response) = try await URLSession.shared.data(from: url)
    
    if let httpResponse = response as? HTTPURLResponse {
        updateRateLimitInfo(from: httpResponse)
    }
    
    return try JSONDecoder().decode([Identifier].self, from: data)
}
```

### 5. Queue and Prioritize Requests

When working with many requests, implement a queue system that respects rate limits:

```swift
class RegistryRequestQueue {
    private var queue = [RegistryRequest]()
    private var isProcessing = false
    
    func addRequest(_ request: RegistryRequest) {
        queue.append(request)
        processQueue()
    }
    
    private func processQueue() {
        guard !isProcessing, !queue.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            repeat {
                // Sort queue by priority
                queue.sort { $0.priority > $1.priority }
                
                // Take the next request
                let nextRequest = queue.removeFirst()
                
                do {
                    let _ = try await executeRequest(nextRequest)
                    // Handle success
                    await nextRequest.completion(.success(()))
                } catch {
                    // Handle error
                    await nextRequest.completion(.failure(error))
                    
                    if let registryError = error as? RegistryError, 
                       case .rateLimitExceeded = registryError {
                        // Wait before continuing if rate limited
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                    }
                }
            } while !queue.isEmpty
            
            isProcessing = false
        }
    }
    
    // Other methods...
}
```

## See Also

- <doc:ErrorCodes>
- <doc:Performance> 
