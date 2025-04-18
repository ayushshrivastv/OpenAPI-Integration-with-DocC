import Foundation
import OpenAPI
import SymbolKit

/// A generator that converts OpenAPI documents to DocC symbol graphs
public struct SymbolGraphGenerator {
    /// The name to use for the module
    public var moduleName: String?
    
    /// Creates a new symbol graph generator
    public init(moduleName: String? = nil) {
        self.moduleName = moduleName
    }
    
    /// Generates a symbol graph from an OpenAPI document
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated symbol graph
    public func generate(from document: Document) -> SymbolKit.SymbolGraph {
        var symbols: [SymbolKit.SymbolGraph.Symbol] = []
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []
        
        // Add module symbol
        let moduleSymbol = createModuleSymbol(from: document.info)
        symbols.append(moduleSymbol)
        
        // Add path symbols
        for (path, pathItem) in document.paths {
            // Add path symbol
            let pathSymbol = createPathSymbol(path: path, pathItem: pathItem)
            symbols.append(pathSymbol)
            
            // Add relationship from module to path
            relationships.append(SymbolKit.SymbolGraph.Relationship(
                source: moduleSymbol.identifier.precise,
                target: pathSymbol.identifier.precise,
                kind: .memberOf,
                targetFallback: path
            ))
            
            // Add operation symbols
            for (method, operation) in pathItem.allOperations() {
                // Add operation symbol
                let operationSymbol = createOperationSymbol(method: method, operation: operation, path: path)
                symbols.append(operationSymbol)
                
                // Add relationship from path to operation
                relationships.append(SymbolKit.SymbolGraph.Relationship(
                    source: operationSymbol.identifier.precise,
                    target: pathSymbol.identifier.precise,
                    kind: .memberOf,
                    targetFallback: "\(method.rawValue.uppercased()) \(path)"
                ))
                
                // Add parameter symbols
                if let parameters = operation.parameters {
                    for parameter in parameters {
                        // Add parameter symbol
                        let parameterSymbol = createParameterSymbol(parameter: parameter, operation: operationSymbol)
                        symbols.append(parameterSymbol)
                        
                        // Add relationship from operation to parameter
                        relationships.append(SymbolKit.SymbolGraph.Relationship(
                            source: parameterSymbol.identifier.precise,
                            target: operationSymbol.identifier.precise,
                            kind: .memberOf,
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
                    relationships.append(SymbolKit.SymbolGraph.Relationship(
                        source: responseSymbol.identifier.precise,
                        target: operationSymbol.identifier.precise,
                        kind: .memberOf,
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
                relationships.append(SymbolKit.SymbolGraph.Relationship(
                    source: schemaSymbol.identifier.precise,
                    target: moduleSymbol.identifier.precise,
                    kind: .memberOf,
                    targetFallback: name
                ))
            }
        }
        
        return SymbolKit.SymbolGraph(
            metadata: createMetadata(from: document),
            module: createModule(from: document.info),
            symbols: symbols,
            relationships: relationships
        )
    }
    
    private func createModuleSymbol(from info: Info) -> SymbolKit.SymbolGraph.Symbol {
        let moduleName = self.moduleName ?? info.title
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "module",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: moduleName,
            navigator: [.init(kind: .text, spelling: moduleName, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        
        if let description = info.description {
            let line = SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            docComment = SymbolKit.SymbolGraph.LineList([line])
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [moduleName],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .module, displayName: "Module"),
            mixins: [:]
        )
    }
    
    private func createPathSymbol(path: String, pathItem: PathItem) -> SymbolKit.SymbolGraph.Symbol {
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "path:\(path)",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: path,
            navigator: [.init(kind: .text, spelling: path, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [path],
            docComment: nil,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .protocol, displayName: "Path"),
            mixins: [:]
        )
    }
    
    private func createOperationSymbol(method: HTTPMethod, operation: OpenAPI.Operation, path: String) -> SymbolKit.SymbolGraph.Symbol {
        let title = "\(method.rawValue.uppercased()) \(path)"
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "operation:\(method.rawValue):\(path)",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: title,
            navigator: [.init(kind: .text, spelling: title, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        
        if let description = operation.description {
            let line = SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            docComment = SymbolKit.SymbolGraph.LineList([line])
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [path, method.rawValue],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .method, displayName: "Operation"),
            mixins: [:]
        )
    }
    
    private func createParameterSymbol(parameter: Parameter, operation: SymbolKit.SymbolGraph.Symbol) -> SymbolKit.SymbolGraph.Symbol {
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "parameter:\(parameter.name)",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: parameter.name,
            navigator: [.init(kind: .text, spelling: parameter.name, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        
        if let description = parameter.schema.description {
            let line = SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            docComment = SymbolKit.SymbolGraph.LineList([line])
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: operation.pathComponents + [parameter.name],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .property, displayName: "Parameter"),
            mixins: [:]
        )
    }
    
    private func createResponseSymbol(statusCode: String, response: Response, operation: SymbolKit.SymbolGraph.Symbol) -> SymbolKit.SymbolGraph.Symbol {
        let title = "\(statusCode) Response"
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "response:\(statusCode)",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: title,
            navigator: [.init(kind: .text, spelling: title, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        // Create doc comment with the non-optional description
        let line = SymbolKit.SymbolGraph.LineList.Line(text: response.description, range: nil)
        let docComment = SymbolKit.SymbolGraph.LineList([line])
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: operation.pathComponents + [statusCode],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .struct, displayName: "Response"),
            mixins: [:]
        )
    }
    
    private func createSchemaSymbol(name: String, schema: JSONSchema) -> SymbolKit.SymbolGraph.Symbol {
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "schema:\(name)",
            interfaceLanguage: "openapi"
        )
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: name,
            navigator: [.init(kind: .text, spelling: name, preciseIdentifier: nil)],
            subHeading: nil,
            prose: nil
        )
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        
        if let description = schema.description {
            let line = SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            docComment = SymbolKit.SymbolGraph.LineList([line])
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [name],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .struct, displayName: "Schema"),
            mixins: [:]
        )
    }
    
    private func createMetadata(from document: Document) -> SymbolKit.SymbolGraph.Metadata {
        return SymbolKit.SymbolGraph.Metadata(
            formatVersion: SymbolKit.SymbolGraph.SemanticVersion(major: 0, minor: 5, patch: 3),
            generator: "OpenAPItoSymbolGraph"
        )
    }
    
    private func createModule(from info: Info) -> SymbolKit.SymbolGraph.Module {
        return SymbolKit.SymbolGraph.Module(
            name: self.moduleName ?? info.title,
            platform: SymbolKit.SymbolGraph.Platform(
                architecture: nil,
                vendor: "OpenAPI",
                operatingSystem: nil
            )
        )
    }
} 
