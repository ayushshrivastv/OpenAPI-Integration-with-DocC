import Foundation
import OpenAPI
import SymbolKit

// Helper function to safely get vendor extensions from different types
private func getVendorExtension(key: String, from object: Any) -> Any? {
    // Use reflection to check for extensions property
    if let mirror = Mirror(reflecting: object).children.first(where: { $0.label == "extensions" }) {
        if let extensions = mirror.value as? [String: Any] {
            return extensions[key]
        }
    }
    
    return nil
}

/// A generator that converts OpenAPI documents to DocC symbol graphs
public struct SymbolGraphGenerator {
    /// The name to use for the module
    public var moduleName: String?
    /// Base URL for the API
    public var baseURL: URL?
    /// Whether to include examples in the documentation
    public var includeExamples: Bool

    /// Creates a new symbol graph generator
    /// - Parameters:
    ///   - moduleName: The name to use for the module
    ///   - baseURL: The base URL for the API
    ///   - includeExamples: Whether to include examples in the documentation
    public init(moduleName: String? = nil, baseURL: URL? = nil, includeExamples: Bool = true) {
        self.moduleName = moduleName
        self.baseURL = baseURL
        self.includeExamples = includeExamples
    }

    /// Generates a symbol graph from an OpenAPI document
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated symbol graph
    public func generate(from document: Document) -> SymbolKit.SymbolGraph {
        // For now, we'll skip the mixin registration as it requires more work to implement correctly
        // We're still generating valid symbol graphs, just without the HTTP-specific enhancements

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
            var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            ]
            // Add examples if present and enabled
            if includeExamples, let extensions = info.extensions, let example = extensions["x-example"] as? String {
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
            }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        } else if includeExamples, let extensions = info.extensions, let example = extensions["x-example"] as? String {
            let lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil),
                SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil)
            ]
            docComment = SymbolKit.SymbolGraph.LineList(lines)
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

        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        if let description = pathItem.description {
            var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            ]
            // Add examples if present and enabled
            if includeExamples, let extensions = pathItem.extensions, let example = extensions["x-example"] as? String {
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
            }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        } else if includeExamples, let extensions = pathItem.extensions, let example = extensions["x-example"] as? String {
            let lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil),
                SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil)
            ]
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        }

        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [path],
            docComment: docComment,
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
            var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            ]
            // Add examples if present and enabled
            if includeExamples, let example = getVendorExtension(key: "x-example", from: operation) as? String {
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
            }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        } else if includeExamples, let example = getVendorExtension(key: "x-example", from: operation) as? String {
            let lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil),
                SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil)
            ]
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        }

        // Create mixins for HTTP endpoint
        var mixins: [String: SymbolKit.Mixin] = [:]

        // Add HTTP endpoint mixin if baseURL is provided
        if let baseURL = self.baseURL {
            let httpEndpoint = SymbolKit.SymbolGraph.Symbol.HTTP.Endpoint(
                method: method.rawValue,
                baseURL: baseURL,
                path: path
            )
            mixins[SymbolKit.SymbolGraph.Symbol.HTTP.endpointMixinKey] = httpEndpoint
        }

        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [path, method.rawValue],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .method, displayName: "Operation"),
            mixins: mixins
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
            var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            ]
            // Add examples if present and enabled
            if includeExamples, let example = getVendorExtension(key: "x-example", from: parameter) as? String {
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
            }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        } else if includeExamples, let example = getVendorExtension(key: "x-example", from: parameter) as? String {
            let lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil),
                SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil)
            ]
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        }

        // Create mixins for HTTP parameter
        var mixins: [String: SymbolKit.Mixin] = [:]

        // Add HTTP parameter source mixin
        let httpParameterSource = SymbolKit.SymbolGraph.Symbol.HTTP.ParameterSource(parameter.in)
        mixins[SymbolKit.SymbolGraph.Symbol.HTTP.parameterSourceMixinKey] = httpParameterSource

        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: operation.pathComponents + [parameter.name],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .property, displayName: "Parameter"),
            mixins: mixins
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
        var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
            SymbolKit.SymbolGraph.LineList.Line(text: response.description, range: nil)
        ]
        // Add examples if present and enabled
        if includeExamples, let example = getVendorExtension(key: "x-example", from: response) as? String {
            lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
            lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
        }
        let docComment = SymbolKit.SymbolGraph.LineList(lines)

        // Create mixins for HTTP response
        var mixins: [String: SymbolKit.Mixin] = [:]

        // Add HTTP media type mixin if content is available
        if let content = response.content?.first {
            let mediaType = SymbolKit.SymbolGraph.Symbol.HTTP.MediaType(content.key)
            mixins[SymbolKit.SymbolGraph.Symbol.HTTP.mediaTypeMixinKey] = mediaType
        }

        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: operation.pathComponents + [statusCode],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            kind: .init(parsedIdentifier: .struct, displayName: "Response"),
            mixins: mixins
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
            var lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            ]
            // Add examples if present and enabled
            if includeExamples, let example = getVendorExtension(key: "x-example", from: schema) as? String {
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil))
                lines.append(SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil))
            }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        } else if includeExamples, let example = getVendorExtension(key: "x-example", from: schema) as? String {
            let lines: [SymbolKit.SymbolGraph.LineList.Line] = [
                SymbolKit.SymbolGraph.LineList.Line(text: "Example:", range: nil),
                SymbolKit.SymbolGraph.LineList.Line(text: example, range: nil)
            ]
            docComment = SymbolKit.SymbolGraph.LineList(lines)
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
