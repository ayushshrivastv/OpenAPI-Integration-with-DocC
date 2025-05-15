import Foundation

/// Represents an OpenAPI document
public struct Document {
    /// The OpenAPI version
    public let openapi: String
    
    /// The API metadata
    public let info: Info
    
    /// The available paths
    public let paths: [String: PathItem]
    
    /// The reusable components
    public let components: Components?
    
    /// Creates a new OpenAPI document
    /// - Parameters:
    ///   - openapi: The OpenAPI version
    ///   - info: The API metadata
    ///   - paths: The available paths
    ///   - components: The reusable components
    public init(
        openapi: String,
        info: Info,
        paths: [String: PathItem],
        components: Components? = nil
    ) {
        self.openapi = openapi
        self.info = info
        self.paths = paths
        self.components = components
    }
}

/// Represents API metadata
public struct Info {
    /// The API title
    public let title: String
    
    /// The API version
    public let version: String
    
    /// The API description
    public let description: String?
    
    /// The extensions for this object
    public let extensions: [String: Any]?
    
    /// Creates new API metadata
    /// - Parameters:
    ///   - title: The API title
    ///   - version: The API version
    ///   - description: The API description
    ///   - extensions: The extensions for this object
    public init(
        title: String,
        version: String,
        description: String? = nil,
        extensions: [String: Any]? = nil
    ) {
        self.title = title
        self.version = version
        self.description = description
        self.extensions = extensions
    }
}

/// Represents reusable components
public struct Components {
    /// The reusable schemas
    public let schemas: [String: JSONSchema]?
    
    /// The reusable parameters
    public let parameters: [String: Parameter]?
    
    /// Creates new reusable components
    /// - Parameters:
    ///   - schemas: The reusable schemas
    ///   - parameters: The reusable parameters
    public init(
        schemas: [String: JSONSchema]? = nil,
        parameters: [String: Parameter]? = nil
    ) {
        self.schemas = schemas
        self.parameters = parameters
    }
}
