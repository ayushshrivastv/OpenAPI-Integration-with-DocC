import Foundation
import OpenAPI

/// A generator that converts OpenAPI documents to DocC symbol graphs
public struct SymbolGraphGenerator {
    /// Creates a new symbol graph generator
    public init() {}
    
    /// Generates a symbol graph from an OpenAPI document
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated symbol graph
    public func generate(from document: Document) -> SymbolGraph {
        var symbols: [Symbol] = []
        var relationships: [Relationship] = []
        
        // Add module symbol
        let moduleSymbol = createModuleSymbol(from: document.info)
        symbols.append(moduleSymbol)
        
        // Add path symbols
        for (path, pathItem) in document.paths {
            // Add path symbol
            let pathSymbol = createPathSymbol(path: path, pathItem: pathItem)
            symbols.append(pathSymbol)
            
            // Add relationship from module to path
            relationships.append(Relationship(
                source: moduleSymbol.identifier,
                target: pathSymbol.identifier,
                kind: .contains,
                targetFallback: path
            ))
            
            // Add operation symbols
            for (method, operation) in pathItem.allOperations() {
                // Add operation symbol
                let operationSymbol = createOperationSymbol(method: method, operation: operation, path: path)
                symbols.append(operationSymbol)
                
                // Add relationship from path to operation
                relationships.append(Relationship(
                    source: pathSymbol.identifier,
                    target: operationSymbol.identifier,
                    kind: .contains,
                    targetFallback: "\(method.rawValue.uppercased()) \(path)"
                ))
                
                // Add parameter symbols
                if let parameters = operation.parameters {
                    for parameter in parameters {
                        // Add parameter symbol
                        let parameterSymbol = createParameterSymbol(parameter: parameter, operation: operationSymbol)
                        symbols.append(parameterSymbol)
                        
                        // Add relationship from operation to parameter
                        relationships.append(Relationship(
                            source: operationSymbol.identifier,
                            target: parameterSymbol.identifier,
                            kind: .hasParameter,
                            targetFallback: parameter.name
                        ))
                    }
                }
                
                // Add response symbols
                for (statusCode, response) in operation.responses {
                    // Add response symbol
                    let responseSymbol = createResponseSymbol(statusCode: statusCode, response: response, operation: operationSymbol)
                    symbols.append(responseSymbol)
                    
                    // Add relationship from operation to response
                    relationships.append(Relationship(
                        source: operationSymbol.identifier,
                        target: responseSymbol.identifier,
                        kind: .returnsType,
                        targetFallback: statusCode
                    ))
                }
            }
        }
        
        // Add schema symbols
        if let components = document.components, let schemas = components.schemas {
            for (name, schema) in schemas {
                // Add schema symbol
                let schemaSymbol = createSchemaSymbol(name: name, schema: schema)
                symbols.append(schemaSymbol)
                
                // Add relationship from module to schema
                relationships.append(Relationship(
                    source: moduleSymbol.identifier,
                    target: schemaSymbol.identifier,
                    kind: .contains,
                    targetFallback: name
                ))
            }
        }
        
        return SymbolGraph(
            metadata: createMetadata(from: document),
            module: createModule(from: document.info),
            symbols: symbols,
            relationships: relationships
        )
    }
    
    private func createModuleSymbol(from info: Info) -> Symbol {
        return Symbol(
            identifier: "module",
            names: Names(title: info.title, navigator: [info.title]),
            pathComponents: [info.title],
            docComment: info.description,
            kind: .module
        )
    }
    
    private func createPathSymbol(path: String, pathItem: PathItem) -> Symbol {
        return Symbol(
            identifier: "path:\(path)",
            names: Names(title: path, navigator: [path]),
            pathComponents: [path],
            docComment: nil,
            kind: .group
        )
    }
    
    private func createOperationSymbol(method: HTTPMethod, operation: OpenAPI.Operation, path: String) -> Symbol {
        let title = "\(method.rawValue.uppercased()) \(path)"
        return Symbol(
            identifier: "operation:\(method.rawValue):\(path)",
            names: Names(title: title, navigator: [title]),
            pathComponents: [path, method.rawValue],
            docComment: operation.description,
            kind: .endpoint
        )
    }
    
    private func createParameterSymbol(parameter: Parameter, operation: Symbol) -> Symbol {
        return Symbol(
            identifier: "parameter:\(parameter.name)",
            names: Names(title: parameter.name, navigator: [parameter.name]),
            pathComponents: operation.pathComponents + [parameter.name],
            docComment: nil,
            kind: .parameter
        )
    }
    
    private func createResponseSymbol(statusCode: String, response: Response, operation: Symbol) -> Symbol {
        return Symbol(
            identifier: "response:\(statusCode)",
            names: Names(title: "\(statusCode) Response", navigator: ["\(statusCode) Response"]),
            pathComponents: operation.pathComponents + [statusCode],
            docComment: response.description,
            kind: .response
        )
    }
    
    private func createSchemaSymbol(name: String, schema: JSONSchema) -> Symbol {
        return Symbol(
            identifier: "schema:\(name)",
            names: Names(title: name, navigator: [name]),
            pathComponents: [name],
            docComment: nil,
            kind: .structType
        )
    }
    
    private func createMetadata(from document: Document) -> Metadata {
        return Metadata(
            formatVersion: "1.0",
            generator: "OpenAPItoSymbolGraph"
        )
    }
    
    private func createModule(from info: Info) -> Module {
        return Module(
            name: info.title,
            platform: "OpenAPI"
        )
    }
}

/// Represents a DocC symbol graph
public struct SymbolGraph {
    /// The metadata of the symbol graph
    public let metadata: Metadata
    
    /// The module information
    public let module: Module
    
    /// The symbols in the graph
    public let symbols: [Symbol]
    
    /// The relationships between symbols
    public let relationships: [Relationship]
}

/// Represents metadata about the symbol graph
public struct Metadata {
    /// The format version
    public let formatVersion: String
    
    /// The generator that created the symbol graph
    public let generator: String
}

/// Represents a module in the symbol graph
public struct Module {
    /// The name of the module
    public let name: String
    
    /// The platform the module is for
    public let platform: String
}

/// Represents a symbol in the symbol graph
public struct Symbol {
    /// The unique identifier of the symbol
    public let identifier: String
    
    /// The names of the symbol
    public let names: Names
    
    /// The path components of the symbol
    public let pathComponents: [String]
    
    /// The documentation comment of the symbol
    public let docComment: String?
    
    /// The kind of the symbol
    public let kind: SymbolKind
}

/// Represents the names of a symbol
public struct Names {
    /// The title of the symbol
    public let title: String
    
    /// The navigator name of the symbol
    public let navigator: [String]
    
    /// Creates new names for a symbol
    /// - Parameters:
    ///   - title: The title of the symbol
    ///   - navigator: The navigator names for the symbol
    public init(title: String, navigator: [String]) {
        self.title = title
        self.navigator = navigator
    }
}

/// Represents a relationship between symbols
public struct Relationship {
    /// The source symbol identifier
    public let source: String
    
    /// The target symbol identifier
    public let target: String
    
    /// The kind of relationship
    public let kind: RelationshipKind
    
    /// The fallback target if the relationship is not explicitly defined
    public let targetFallback: String?
}

/// The kind of a symbol
public enum SymbolKind {
    case module
    case group
    case endpoint
    case structType
    case parameter
    case response
}

/// The kind of a relationship
public enum RelationshipKind {
    case contains
    case hasParameter
    case returnsType
} 
