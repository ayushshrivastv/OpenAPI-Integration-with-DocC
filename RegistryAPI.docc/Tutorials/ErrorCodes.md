# Error Codes

Understand how the Swift Package Registry API communicates errors and how to handle them.

## Overview

The Swift Package Registry API uses standard HTTP status codes combined with detailed error responses to provide clear information about what went wrong. All error responses follow the RFC 7807 Problem Details format, allowing both machines and humans to understand the nature of errors.

## Problem Details Response Format

When an error occurs, the API returns a problem details object with the following structure:

```json
{
  "type": "https://registry.example.com/docs/errors/invalid-version",
  "title": "Invalid Version Format",
  "status": 400,
  "detail": "The version '1.x' does not conform to semantic versioning requirements",
  "instance": "urn:uuid:6493675d-9af4-4f9d-b8c3-90c5e33f3db1"
}
```

The object contains these fields:

- `type`: A URI reference that identifies the problem type
- `title`: A short, human-readable summary of the problem
- `status`: The HTTP status code
- `detail`: A human-readable explanation specific to this occurrence of the problem
- `instance`: A URI reference that identifies the specific occurrence of the problem

## Common Error Types

### Authentication Errors (401, 403)

| Status | Type | Description |
|--------|------|-------------|
| 401 | unauthorized | The request lacks valid authentication credentials |
| 403 | forbidden | The authenticated user lacks permission for the requested operation |

```swift
// Example: Handling an authentication error
do {
    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else { return }
    
    if httpResponse.statusCode == 401 {
        // Handle unauthorized error - request new credentials
        refreshCredentials()
    } else if httpResponse.statusCode == 403 {
        // Handle forbidden error - inform user they lack permission
        showPermissionError()
    }
} catch {
    // Handle network errors
}
```

### Resource Errors (404, 410)

| Status | Type | Description |
|--------|------|-------------|
| 404 | not-found | The requested resource does not exist |
| 410 | gone | The resource previously existed but is no longer available |

### Request Validation Errors (400, 422)

| Status | Type | Description |
|--------|------|-------------|
| 400 | bad-request | The request could not be understood or was missing required parameters |
| 422 | validation-failed | The request was well-formed but contained semantic errors |

### Rate Limiting Errors (429)

| Status | Type | Description |
|--------|------|-------------|
| 429 | too-many-requests | The client has sent too many requests in a given time period |

Rate limiting responses include additional headers:

- `RateLimit-Limit`: The maximum number of requests allowed in the current time window
- `RateLimit-Remaining`: The number of requests remaining in the current time window
- `RateLimit-Reset`: The time when the current rate limit window resets (in UTC epoch seconds)

### Server Errors (500, 503)

| Status | Type | Description |
|--------|------|-------------|
| 500 | server-error | An unexpected error occurred on the server |
| 503 | service-unavailable | The service is temporarily unavailable |

## Best Practices for Error Handling

1. **Always check status codes**: Validate HTTP status codes before processing responses
2. **Parse problem details**: Extract the detailed error information from the response body
3. **Implement exponential backoff**: For rate limiting and server errors, use increasing delays between retries
4. **Present meaningful messages**: Translate error responses into user-friendly messages
5. **Log rich error data**: Include the error `type` and `instance` in logs for easier troubleshooting

```swift
// Example: Comprehensive error handling with retry logic
func fetchPackage(scope: String, name: String, version: String) async throws -> Data {
    var retryCount = 0
    let maxRetries = 3
    
    while true {
        do {
            let url = URL(string: "https://registry.example.com/\(scope)/\(name)/\(version).zip")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RegistryError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                return data
            case 429:
                if retryCount >= maxRetries {
                    throw RegistryError.rateLimitExceeded
                }
                
                // Parse retry-after header or use exponential backoff
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(Int.init) ?? Int(pow(2.0, Double(retryCount + 1)))
                
                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                retryCount += 1
                continue
                
            case 400..<500:
                // Parse problem details
                let problem = try JSONDecoder().decode(ProblemDetails.self, from: data)
                throw RegistryError.clientError(problem)
                
            case 500..<600:
                if retryCount >= maxRetries {
                    throw RegistryError.serverError
                }
                
                // Use exponential backoff for server errors
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount + 1)) * 1_000_000_000))
                retryCount += 1
                continue
                
            default:
                throw RegistryError.unknownError
            }
        } catch {
            if retryCount >= maxRetries {
                throw error
            }
            
            // Network error - retry with backoff
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount + 1)) * 1_000_000_000))
            retryCount += 1
        }
    }
}
```

## See Also

- <doc:RateLimiting>
- ``RegistryAPI/ProblemDetails`` 
