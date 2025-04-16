# Getting Started

Learn how to integrate with our REST API.

## Overview

This guide will help you get started with integrating our REST API into your application. Our API uses standard HTTP methods and JSON for request and response bodies.

## Authentication

All endpoints require authentication. Include your API key in the headers of each request:

```swift
var request = URLRequest(url: url)
request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
```

## Using the API

### Swift Example

Here's a Swift example of how to get a list of users:

```swift
import Foundation

func fetchUsers(completion: @escaping ([User]?, Error?) -> Void) {
    let url = URL(string: "https://api.example.com/users")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "No data", code: 0, userInfo: nil))
            return
        }
        
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            completion(users, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    task.resume()
}
```

### Swift Async/Await Example

Using modern Swift concurrency:

```swift
import Foundation

func fetchUsers() async throws -> [User] {
    let url = URL(string: "https://api.example.com/users")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([User].self, from: data)
}
```

## Error Handling

Our API uses standard HTTP status codes:

- 200 - OK: Request succeeded
- 400 - Bad Request: Invalid parameters
- 401 - Unauthorized: Authentication failed
- 404 - Not Found: Resource not found
- 500 - Server Error: Something went wrong on our side

## Rate Limits

API requests are limited to 100 requests per minute per API key. 
