import Foundation

/// Represents a parameter in an operation
public struct Parameter {
    /// The name of the parameter
    public let name: String
    
    /// The location of the parameter
    public let `in`: ParameterLocation
    
    /// Whether the parameter is required
    public let required: Bool
    
    /// The schema of the parameter
    public let schema: JSONSchema
    
    /// Creates a new parameter
    /// - Parameters:
    ///   - name: The name of the parameter
    ///   - in: The location of the parameter
    ///   - required: Whether the parameter is required
    ///   - schema: The schema of the parameter
    public init(
        name: String,
        `in`: ParameterLocation,
        required: Bool = false,
        schema: JSONSchema
    ) {
        self.name = name
        self.in = `in`
        self.required = required
        self.schema = schema
    }
}

/// The location of a parameter
public enum ParameterLocation: String {
    case query
    case header
    case path
    case cookie
} 
