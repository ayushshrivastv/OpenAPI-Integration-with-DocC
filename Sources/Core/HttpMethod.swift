import Foundation
import OpenAPIKit

/// An enumeration of HTTP methods that are valid in OpenAPI specifications.
public enum HttpMethod: String, Codable, CaseIterable {
    case get = "get"
    case post = "post"
    case put = "put"
    case delete = "delete"
    case options = "options"
    case head = "head"
    case patch = "patch"
    case trace = "trace"
    
    /// Creates a new HttpMethod from an OpenAPI.HttpMethod
    /// 
    /// - Parameter openAPIMethod: The OpenAPI method to convert
    /// - Returns: The corresponding HttpMethod, or nil if the conversion is not possible
    public static func from(_ openAPIMethod: OpenAPI.HttpMethod) -> HttpMethod? {
        return HttpMethod(rawValue: openAPIMethod.rawValue)
    }
    
    /// Returns a human-readable description of the HTTP method.
    public var description: String {
        switch self {
        case .get:
            return "Retrieve a resource or collection of resources"
        case .post:
            return "Create a new resource"
        case .put:
            return "Replace an existing resource"
        case .delete:
            return "Delete a resource"
        case .options:
            return "Get supported HTTP methods"
        case .head:
            return "Same as GET without the response body"
        case .patch:
            return "Partially update a resource"
        case .trace:
            return "Perform a message loop-back test"
        }
    }
} 
