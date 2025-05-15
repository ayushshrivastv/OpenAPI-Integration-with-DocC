import Foundation

/// Represents a path in the API
public struct PathItem {
    /// The HTTP GET operation
    public let get: Operation?
    
    /// The HTTP POST operation
    public let post: Operation?
    
    /// The HTTP PUT operation
    public let put: Operation?
    
    /// The HTTP DELETE operation
    public let delete: Operation?
    
    /// The parameters that apply to all operations
    public let parameters: [Parameter]?
    
    /// A description of the path
    public let description: String?
    
    /// The extensions for this object
    public let extensions: [String: Any]?
    
    /// Creates a new path item
    /// - Parameters:
    ///   - get: The HTTP GET operation
    ///   - post: The HTTP POST operation
    ///   - put: The HTTP PUT operation
    ///   - delete: The HTTP DELETE operation
    ///   - parameters: The parameters that apply to all operations
    ///   - description: A description of the path
    ///   - extensions: The extensions for this object
    public init(
        get: Operation? = nil,
        post: Operation? = nil,
        put: Operation? = nil,
        delete: Operation? = nil,
        parameters: [Parameter]? = nil,
        description: String? = nil,
        extensions: [String: Any]? = nil
    ) {
        self.get = get
        self.post = post
        self.put = put
        self.delete = delete
        self.parameters = parameters
        self.description = description
        self.extensions = extensions
    }
    
    /// Returns the operation for the given HTTP method
    /// - Parameter method: The HTTP method
    /// - Returns: The operation for the given method, or nil if not found
    public func operation(for method: HTTPMethod) -> Operation? {
        switch method {
        case .get:
            return get
        case .post:
            return post
        case .put:
            return put
        case .delete:
            return delete
        default:
            return nil
        }
    }
    
    /// Returns all operations in this path item
    /// - Returns: An array of tuples containing the HTTP method and operation
    public func allOperations() -> [(method: HTTPMethod, operation: Operation)] {
        var operations: [(HTTPMethod, Operation)] = []
        
        if let get = get {
            operations.append((.get, get))
        }
        if let post = post {
            operations.append((.post, post))
        }
        if let put = put {
            operations.append((.put, put))
        }
        if let delete = delete {
            operations.append((.delete, delete))
        }
        
        return operations
    }
}

/// HTTP methods supported by OpenAPI
public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    case patch
    case head
    case options
    case trace
} 
