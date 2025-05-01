# Performance Optimization

Learn how to optimize your Swift Package Registry API usage for maximum performance.

## Overview

Optimizing your interactions with the Swift Package Registry API can significantly improve your application's performance and user experience. This guide covers best practices for efficient API usage, including caching strategies, concurrent requests, and optimizing data transfers.

![Diagram showing performance optimization techniques](performance_diagram.png)

## Caching Strategies

Implementing effective caching is one of the most important ways to improve performance when working with the Registry API.

### Memory Caching

For frequently accessed data that doesn't change often, implement in-memory caching:

```swift
class RegistryAPIClient {
    // Simple memory cache with expiration support
    private class Cache<K: Hashable, V> {
        private struct CacheEntry {
            let value: V
            let expirationDate: Date
        }
        
        private var storage = [K: CacheEntry]()
        private let lock = NSLock()
        
        func set(_ value: V, forKey key: K, expirationInterval: TimeInterval) {
            lock.lock()
            defer { lock.unlock() }
            
            let expirationDate = Date().addingTimeInterval(expirationInterval)
            storage[key] = CacheEntry(value: value, expirationDate: expirationDate)
        }
        
        func get(forKey key: K) -> V? {
            lock.lock()
            defer { lock.unlock() }
            
            guard let entry = storage[key], entry.expirationDate > Date() else {
                // Remove expired entry if it exists
                storage.removeValue(forKey: key)
                return nil
            }
            
            return entry.value
        }
        
        func removeAll() {
            lock.lock()
            defer { lock.unlock() }
            storage.removeAll()
        }
    }
    
    // Cache for package metadata (larger TTL since metadata changes less frequently)
    private let metadataCache = Cache<String, PackageMetadata>()
    
    // Cache for package identifiers (shorter TTL since search results may change)
    private let identifierCache = Cache<String, [Identifier]>()
    
    func fetchPackageMetadata(scope: String, name: String) async throws -> PackageMetadata {
        let cacheKey = "\(scope)/\(name)"
        
        // Check cache first
        if let cachedMetadata = metadataCache.get(forKey: cacheKey) {
            return cachedMetadata
        }
        
        // Fetch from network
        let url = URL(string: "https://registry.example.com/\(scope)/\(name)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let metadata = try JSONDecoder().decode(PackageMetadata.self, from: data)
        
        // Cache result (30 minute TTL)
        metadataCache.set(metadata, forKey: cacheKey, expirationInterval: 30 * 60)
        
        return metadata
    }
}
```

### Persistent Caching

For data that should persist between app launches:

```swift
class PersistentCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() throws {
        let cacheURL = try fileManager.url(
            for: .cachesDirectory, 
            in: .userDomainMask, 
            appropriateFor: nil, 
            create: true
        )
        cacheDirectory = cacheURL.appendingPathComponent("RegistryCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func cacheData(_ data: Data, forKey key: String, expirationInterval: TimeInterval) throws {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try data.write(to: fileURL)
        
        // Store metadata including expiration
        let metadata: [String: Any] = [
            "key": key,
            "expiration": Date().addingTimeInterval(expirationInterval).timeIntervalSince1970
        ]
        let metadataURL = fileURL.appendingPathExtension("metadata")
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try metadataData.write(to: metadataURL)
    }
    
    func getData(forKey key: String) throws -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path),
              fileManager.fileExists(atPath: metadataURL.path) else {
            return nil
        }
        
        // Check expiration
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
        
        if let expirationTimestamp = metadata?["expiration"] as? TimeInterval,
           Date(timeIntervalSince1970: expirationTimestamp) > Date() {
            // Not expired, return data
            return try Data(contentsOf: fileURL)
        } else {
            // Expired, clean up files
            try? fileManager.removeItem(at: fileURL)
            try? fileManager.removeItem(at: metadataURL)
            return nil
        }
    }
}
```

### Conditional Requests

Use HTTP conditional requests with ETag or Last-Modified headers to avoid downloading unchanged data:

```swift
class ConditionalRequestClient {
    private var etagStorage: [String: String] = [:]
    
    func fetchWithConditionalRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        
        // Add conditional header if we have an ETag
        let resourceKey = url.absoluteString
        if let etag = etagStorage[resourceKey] {
            request.addValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Store ETag if present
        if let newETag = httpResponse.value(forHTTPHeaderField: "ETag") {
            etagStorage[resourceKey] = newETag
        }
        
        if httpResponse.statusCode == 304 {
            // Resource not modified, return cached data
            guard let cachedData = try PersistentCache().getData(forKey: resourceKey) else {
                throw APIError.cacheInconsistency
            }
            return cachedData
        } else if (200..<300).contains(httpResponse.statusCode) {
            // New or modified data
            try PersistentCache().cacheData(data, forKey: resourceKey, expirationInterval: 3600)
            return data
        } else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}
```

## Optimizing Data Transfers

### Compression

The Registry API supports gzip compression. Enable it in your requests:

```swift
var request = URLRequest(url: url)
request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
```

### Request Only What You Need

Use query parameters to limit the data you retrieve:

```swift
// Example: Limiting the number of results
func searchPackages(query: String, limit: Int = 20) async throws -> [Identifier] {
    let urlString = "https://registry.example.com/identifiers?query=\(query)&limit=\(limit)"
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Identifier].self, from: data)
}
```

### Avoiding Redundant Requests

Track in-flight requests to avoid duplicate network calls:

```swift
class APIRequestCoordinator {
    private var inFlightRequests = [URL: Task<Data, Error>]()
    private let lock = NSLock()
    
    func performRequest(for url: URL) async throws -> Data {
        lock.lock()
        
        // Check if there's already an in-flight request for this URL
        if let existingTask = inFlightRequests[url] {
            lock.unlock()
            return try await existingTask.value
        }
        
        // Create a new task for this request
        let task = Task<Data, Error> {
            defer {
                lock.lock()
                inFlightRequests[url] = nil
                lock.unlock()
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        // Store the task
        inFlightRequests[url] = task
        lock.unlock()
        
        return try await task.value
    }
}
```

## Concurrent Operations

### Parallel Downloads

Download multiple packages in parallel for faster bulk operations:

```swift
func downloadMultiplePackages(packages: [(scope: String, name: String, version: String)]) async throws -> [String: Data] {
    // Create a task for each package
    let tasks = packages.map { package in
        Task {
            let (scope, name, version) = package
            let url = URL(string: "https://registry.example.com/\(scope)/\(name)/\(version).zip")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return (key: "\(scope)/\(name)/\(version)", data: data)
        }
    }
    
    // Wait for all tasks to complete
    var results = [String: Data]()
    for task in tasks {
        do {
            let (key, data) = try await task.value
            results[key] = data
        } catch {
            // Handle individual download failures
            print("Failed to download package: \(error.localizedDescription)")
        }
    }
    
    return results
}
```

### Task Prioritization

Use task priorities for critical vs. background operations:

```swift
// High-priority task (e.g., user-initiated download)
let highPriorityTask = Task(priority: .userInitiated) {
    let url = URL(string: "https://registry.example.com/\(scope)/\(name)/\(version).zip")!
    return try await URLSession.shared.data(from: url)
}

// Background task (e.g., prefetching)
let backgroundTask = Task(priority: .background) {
    let url = URL(string: "https://registry.example.com/\(scope)/\(name)")!
    return try await URLSession.shared.data(from: url)
}
```

## Network Efficiency

### Connection Pooling

Configure your URLSession for connection reuse:

```swift
let configuration = URLSessionConfiguration.default
configuration.httpMaximumConnectionsPerHost = 6  // Default is 6
configuration.timeoutIntervalForRequest = 30.0   // 30 seconds
configuration.timeoutIntervalForResource = 60.0  // 60 seconds

let session = URLSession(configuration: configuration)
```

### Batch Operations

When possible, use batch operations to reduce round trips:

```swift
// Instead of multiple separate requests
func batchFetchIdentifiers(queries: [String]) async throws -> [String: [Identifier]] {
    let queryString = queries.joined(separator: ",")
    let url = URL(string: "https://registry.example.com/identifiers?queries=\(queryString)")!
    
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([String: [Identifier]].self, from: data)
}
```

## Prefetching and Predictive Loading

Implement predictive loading for a smoother user experience:

```swift
class PredictiveLoader {
    private let prefetchQueue = OperationQueue()
    private var prefetchedData = [URL: Data]()
    
    init() {
        prefetchQueue.maxConcurrentOperationCount = 2
        prefetchQueue.qualityOfService = .utility
    }
    
    func prefetchRelatedPackages(for package: PackageMetadata) {
        guard let dependencies = package.dependencies else { return }
        
        for dependency in dependencies {
            let dependencyURL = URL(string: "https://registry.example.com/\(dependency.scope)/\(dependency.name)")!
            
            Task(priority: .background) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: dependencyURL)
                    prefetchedData[dependencyURL] = data
                } catch {
                    // Silently fail for prefetching
                    print("Failed to prefetch \(dependencyURL): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getPrefetchedData(for url: URL) -> Data? {
        return prefetchedData[url]
    }
}
```

## Monitoring and Analytics

Implement performance monitoring to identify bottlenecks:

```swift
class PerformanceMonitor {
    private var requestTimings = [String: [TimeInterval]]()
    private let lock = NSLock()
    
    func recordRequestStart(endpoint: String) -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
    
    func recordRequestEnd(endpoint: String, startTime: CFAbsoluteTime) {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        lock.lock()
        defer { lock.unlock() }
        
        if requestTimings[endpoint] == nil {
            requestTimings[endpoint] = [duration]
        } else {
            requestTimings[endpoint]?.append(duration)
        }
        
        // Log slow requests
        if duration > 1.0 {
            print("⚠️ Slow request to \(endpoint): \(String(format: "%.2f", duration))s")
        }
    }
    
    func getAverageResponseTime(for endpoint: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let timings = requestTimings[endpoint], !timings.isEmpty else {
            return nil
        }
        
        return timings.reduce(0, +) / Double(timings.count)
    }
    
    func generatePerformanceReport() -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        
        var report = [String: Any]()
        
        for (endpoint, timings) in requestTimings {
            guard !timings.isEmpty else { continue }
            
            let avgTime = timings.reduce(0, +) / Double(timings.count)
            let maxTime = timings.max() ?? 0
            let minTime = timings.min() ?? 0
            
            report[endpoint] = [
                "avg": avgTime,
                "min": minTime,
                "max": maxTime,
                "count": timings.count
            ]
        }
        
        return report
    }
}
```

## Best Practices Summary

1. **Implement comprehensive caching**:
   - Use memory caching for frequently accessed data
   - Add persistent caching for larger or less frequently changing data
   - Implement conditional requests with ETags

2. **Optimize network usage**:
   - Enable compression in requests
   - Limit response size with query parameters
   - Deduplicate in-flight requests

3. **Use concurrency effectively**:
   - Download resources in parallel
   - Prioritize user-initiated tasks
   - Implement connection pooling

4. **Implement predictive loading**:
   - Prefetch likely-to-be-needed resources
   - Load related packages in the background

5. **Monitor performance**:
   - Track request timings
   - Identify slow operations
   - Generate reports for optimization opportunities

## See Also

- <doc:RateLimiting>
- <doc:ErrorCodes> 
