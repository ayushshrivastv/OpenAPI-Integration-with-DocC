import Foundation
import OpenAPI
import SymbolKit

/// A generator that converts OpenAPI documents to DocC symbol graphs
public struct SymbolGraphGenerator {
    /// The name to use for the module
    public var moduleName: String?
    /// Base URL for the API
    public var baseURL: URL?
    
    /// Creates a new symbol graph generator
    public init(moduleName: String? = nil, baseURL: URL? = nil) {
        self.moduleName = moduleName
        self.baseURL = baseURL
    }
    
    /// Helper to resolve references in OpenAPI documents
    /// Use a private dictionary to cache resolved references to avoid redundant lookups and infinite loops
    private var resolvedReferences: [String: Any] = [:]
    
    /// A helper function to resolve a reference if the provided value is a reference type
    /// Note: This is a generic approach since we don't know the exact structure of the custom Reference type
    private mutating func resolveReference<T>(_ value: Any, in document: Document) -> T? {
        // First check if it's already a properly typed value (not a reference)
        if let directValue = value as? T {
            return directValue
        }
        
        // Try to handle if it's a reference
        // We have to use reflection or runtime checks since we don't know exact structure
        // This is a simplified approach - would need adjustment based on actual model structure
        // Try to access a 'ref' property or Reference type through mirrors
        let mirror = Mirror(reflecting: value)
        
        // Look for a 'ref' property - common in OpenAPI reference implementations
        // Or check if it conforms to a custom Reference protocol
        if let refProp = mirror.children.first(where: { $0.label == "ref" })?.value as? String {
            // If we've already resolved this reference, return the cached result
            if let cached = resolvedReferences[refProp] as? T {
                return cached
            }
            
            // Parse the reference string - typically in format "#/components/[type]/[name]"
            let parts = refProp.split(separator: "/")
            guard parts.count >= 3, parts[1] == "components" else {
                print("Warning: Invalid reference format: \(refProp)")
                return nil
            }
            
            let componentType = String(parts[2])
            let componentName = String(parts[3])
            
            // Get the appropriate component collection based on type
            var component: Any?
            switch componentType {
            case "schemas":
                component = document.components?.schemas?[componentName]
            case "parameters":
                component = document.components?.parameters?[componentName]
            // Note: The custom Components structure might not have all standard OpenAPI components
            // Let's simplify and only include what we've seen in the model so far
            case "responses", "requestBodies", "examples", "headers", "securitySchemes", "links", "callbacks":
                // Custom OpenAPI model might not have all standard components
                // Skip these for now, or implement when needed
                print("Warning: Component type '\(componentType)' might not be supported yet")
            default:
                print("Warning: Unsupported component type: \(componentType)")
                return nil
            }
            
            // Recursively resolve the component if it's also a reference
            if let resolvedComponent = component {
                if let result = self.resolveReference(resolvedComponent, in: document) as T? {
                    // Cache the result to avoid redundant resolutions
                    self.resolvedReferences[refProp] = result
                    return result
                }
            }
        }
        
        // If we can't determine it's a reference or can't resolve it
        print("Warning: Could not resolve reference")
        return nil
    }
    
    /// Generates a symbol graph from an OpenAPI document
    /// - Parameter document: The OpenAPI document to convert
    /// - Returns: The generated symbol graph
    public mutating func generate(from document: Document) -> SymbolKit.SymbolGraph {
        // Clear the references cache for a fresh generation
        self.resolvedReferences = [:]
        
        var symbols: [SymbolKit.SymbolGraph.Symbol] = []
        var relationships: [SymbolKit.SymbolGraph.Relationship] = []
        
        // Add module symbol
        let moduleSymbol = createModuleSymbol(from: document.info)
        symbols.append(moduleSymbol)
        
        // Process path items
        for (pathString, pathItemValue) in document.paths {
            // Handle potential reference or direct value
            // We can't make assumptions about the exact type, so use our helper
            guard let pathItem = self.resolveReference(pathItemValue, in: document) as PathItem? else {
                print("Warning: Could not process path item at \(pathString) - may be an unresolvable reference")
                continue
            }
            
            // Create path symbol
            let pathSymbol = createPathSymbol(path: pathString, pathItem: pathItem)
            symbols.append(pathSymbol)
            
            // Add relationship from module to path
            relationships.append(SymbolKit.SymbolGraph.Relationship(
                source: pathSymbol.identifier.precise,
                target: moduleSymbol.identifier.precise,
                kind: .memberOf,
                targetFallback: pathString
            ))
            
            // Process operations
            for (method, operation) in pathItem.allOperations() {
                // Create operation symbol
                let operationSymbol = createOperationSymbol(method: method, operation: operation, path: pathString)
                symbols.append(operationSymbol)
                
                // Add relationship from operation to path
                relationships.append(SymbolKit.SymbolGraph.Relationship(
                    source: operationSymbol.identifier.precise,
                    target: pathSymbol.identifier.precise,
                    kind: .memberOf,
                    targetFallback: "\(method.rawValue.uppercased()) \(pathString)"
                ))
                
                // Process parameters
                if let parameters = operation.parameters {
                    for parameterValue in parameters {
                        // Resolve parameter reference if needed
                        guard let parameter = self.resolveReference(parameterValue, in: document) as Parameter? else {
                            print("Warning: Could not process parameter - may be an unresolvable reference")
                            continue
                        }
                        
                        let parameterSymbol = createParameterSymbol(parameter: parameter, operation: operationSymbol)
                        symbols.append(parameterSymbol)
                        
                        // Add relationship from parameter to operation
                        relationships.append(SymbolKit.SymbolGraph.Relationship(
                            source: parameterSymbol.identifier.precise,
                            target: operationSymbol.identifier.precise,
                            kind: .memberOf,
                            targetFallback: parameter.name
                        ))
                        
                        // If parameter has a schema, add a relationship to it
                        self.processSchemaReference(parameter.schema, fromSource: parameterSymbol.identifier.precise, inSymbols: &symbols, inRelationships: &relationships)
                    }
                }
                
                // Process request body if present
                if let requestBody = operation.requestBody {
                    // Handle potential reference
                    if let _: RequestBody = self.resolveReference(requestBody, in: document) {
                        // TODO: Create request body symbol and relationships
                        // For now just print that we'd process it
                        print("Would process request body for \(method.rawValue.uppercased()) \(pathString)")
                    }
                }
                
                // Process responses
                for (statusCode, responseValue) in operation.responses {
                    // Resolve response reference if needed
                    guard let response = self.resolveReference(responseValue, in: document) as Response? else {
                        print("Warning: Could not process response \(statusCode) - may be an unresolvable reference")
                        continue
                    }
                    
                    let responseSymbol = createResponseSymbol(statusCode: statusCode, response: response, operation: operationSymbol)
                    symbols.append(responseSymbol)
                    
                    // Add relationship from response to operation
                    relationships.append(SymbolKit.SymbolGraph.Relationship(
                        source: responseSymbol.identifier.precise,
                        target: operationSymbol.identifier.precise,
                        kind: .memberOf,
                        targetFallback: statusCode
                    ))
                    
                    // If response has content with schemas, add relationships
                    if let content = response.content {
                        for (_, mediaTypeObject) in content {
                            // Process response schema
                            self.processSchemaReference(mediaTypeObject.schema, fromSource: responseSymbol.identifier.precise, inSymbols: &symbols, inRelationships: &relationships)
                        }
                    }
                }
            }
        }
        
        // Process component schemas
        if let components = document.components, let schemaMap = components.schemas {
            for (name, schemaValue) in schemaMap {
                // Resolve schema reference if needed
                guard let schema = self.resolveReference(schemaValue, in: document) as JSONSchema? else {
                    print("Warning: Could not process schema \(name) - may be an unresolvable reference")
                    continue
                }
                
                let schemaSymbol = createSchemaSymbol(name: name, schema: schema)
                symbols.append(schemaSymbol)
                
                // Add relationship from schema to module
                relationships.append(SymbolKit.SymbolGraph.Relationship(
                    source: schemaSymbol.identifier.precise,
                    target: moduleSymbol.identifier.precise,
                    kind: .memberOf,
                    targetFallback: name
                ))
                
                // Process schema properties for object schemas
                if case .object(let objectSchema) = schema {
                    let properties = objectSchema.properties
                    for (_, propSchema) in properties {
                        // Create property symbols and relationships
                        // This would be expanded in a more complete implementation
                        
                        // For now, just check if the property schema references another schema
                        self.processSchemaReference(propSchema, fromSource: schemaSymbol.identifier.precise, inSymbols: &symbols, inRelationships: &relationships)
                    }
                }
            }
        }
        
        return SymbolKit.SymbolGraph(
            metadata: createMetadata(from: document),
            module: createModule(from: document.info),
            symbols: symbols,
            relationships: relationships
        )
    }
    
    /// Helper to extract a schema reference name if this schema is a reference
    private func getSchemaReference(_ schema: JSONSchema) -> String? {
        if case .reference(let reference) = schema {
            // Extract the component name from the reference string
            let refString = reference.ref
            let parts = refString.split(separator: "/")
            guard parts.count >= 4, parts[1] == "components", parts[2] == "schemas" else {
                return nil
            }
            return String(parts[3])
        }
        return nil
    }
    
    /// Process a schema, handling references if found, and creating appropriate relationships
    private func processSchemaReference(_ schema: JSONSchema, fromSource sourceId: String, inSymbols symbols: inout [SymbolKit.SymbolGraph.Symbol], inRelationships relationships: inout [SymbolKit.SymbolGraph.Relationship]) {
        // Try to identify if this is a reference to a component schema
        if let schemaRef = self.getSchemaReference(schema) {
            let schemaId = "schema:\(schemaRef)"
            relationships.append(SymbolKit.SymbolGraph.Relationship(
                source: sourceId,
                target: schemaId,
                kind: .requirementOf, // Standard relationship kind
                targetFallback: schemaRef
            ))
        }
        
        // Could expand this to create inline schema symbols for complex non-reference schemas
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
        let title = operation.summary ?? "\(method.rawValue.uppercased()) \(path)"
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "operation:\(method.rawValue):\(path)",
            interfaceLanguage: "openapi"
        )
        
        // Create a better navigator display with method + path
        let methodDisplay = method.rawValue.uppercased()
        let navigationText = "\(methodDisplay) \(path)"
        
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: title,
            navigator: [.init(kind: .text, spelling: navigationText, preciseIdentifier: nil)],
            subHeading: [.init(kind: .text, spelling: methodDisplay, preciseIdentifier: nil)],
            prose: nil
        )
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        
        // Improved documentation that includes more details about the operation
        var docLines: [String] = []
        
        // Add description if available
        if let description = operation.description, !description.isEmpty {
            docLines.append(description)
            docLines.append("") // Add empty line after description
        }
        
        // Add parameter summary if available
        if let parameters = operation.parameters, !parameters.isEmpty {
            docLines.append("**Parameters:**")
            for parameter in parameters {
                let required = parameter.required ? "Required" : "Optional"
                // Note: access schema description if parameter description is not available
                let paramDesc = parameter.schema.description ?? ""
                docLines.append("- `\(parameter.name)` (\(parameter.in), \(required)): \(paramDesc)")
            }
            docLines.append("") // Add empty line after parameters
        }
        
        // Add request body summary if available
        if let requestBody = operation.requestBody {
            docLines.append("**Request Body:**")
            // Note: the RequestBody might not have a description property in our custom model
            // Access content-specific information instead
            let content = requestBody.content
            for (mediaType, mediaTypeObject) in content {
                docLines.append("Content Type: `\(mediaType)`")
                docLines.append(mediaTypeObject.schema.description ?? "")
            }
            docLines.append("") // Add empty line after request body
        }
        
        // Add response summary if available
        if !operation.responses.isEmpty {
            docLines.append("**Responses:**")
            for (statusCode, response) in operation.responses {
                docLines.append("- `\(statusCode)`: \(response.description)")
            }
        }
        
        // Add deprecated notice if applicable
        if operation.deprecated {
            docLines.insert("**⚠️ Deprecated**", at: 0)
            docLines.insert("", at: 1) // Empty line after deprecated notice
        }
        
        if !docLines.isEmpty {
            let lines = docLines.map { SymbolKit.SymbolGraph.LineList.Line(text: $0, range: nil) }
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
            mixins[SymbolKit.SymbolGraph.Symbol.HTTP.Endpoint.mixinKey] = httpEndpoint
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [path, method.rawValue],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            // Use method kind for operations since httpRequest might not be available in this version
            kind: .init(parsedIdentifier: .method, displayName: "HTTP \(method.rawValue.uppercased())"),
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
            let line = SymbolKit.SymbolGraph.LineList.Line(text: description, range: nil)
            docComment = SymbolKit.SymbolGraph.LineList([line])
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
        let line = SymbolKit.SymbolGraph.LineList.Line(text: response.description, range: nil)
        let docComment = SymbolKit.SymbolGraph.LineList([line])
        
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
    
    /// Improved method to create schema symbols for OpenAPI schemas
    private func createSchemaSymbol(name: String, schema: JSONSchema) -> SymbolKit.SymbolGraph.Symbol {
        let identifier = SymbolKit.SymbolGraph.Symbol.Identifier(
            precise: "schema:\(name)",
            interfaceLanguage: "openapi"
        )
        
        // Better names with improved navigator and subheading
        let names = SymbolKit.SymbolGraph.Symbol.Names(
            title: name,
            navigator: [.init(kind: .text, spelling: name, preciseIdentifier: nil)],
            subHeading: [.init(kind: .text, spelling: "Schema", preciseIdentifier: nil)],
            prose: nil
        )
        
        // Enhanced documentation that includes schema properties and constraints
        var docLines: [String] = []
        
        // Add description if available
        if let description = schema.description, !description.isEmpty {
            docLines.append(description)
            docLines.append("") // Add empty line after description
        }
        
        // Add schema type information
        var schemaType = "Object"
        // Determine schema type and gather relevant information
        switch schema {
        case .object(let objSchema):
            schemaType = "Object"
            let properties = objSchema.properties
            if !properties.isEmpty {
                docLines.append("**Properties:**")
                
                let requiredProps: [String] = objSchema.required
                for (propName, propSchema) in properties {
                    let required = requiredProps.contains(propName) ? "Required" : "Optional"
                    let propDesc = propSchema.description ?? ""
                    docLines.append("- `\(propName)` (\(required)): \(propDesc)")
                }
            }
        
        case .array(let arraySchema):
            schemaType = "Array"
            let itemType = "Array<\(getDisplayType(for: arraySchema.items))>"
            docLines.append("**Item Type:** \(itemType)")
            
        case .string(let stringSchema):
            schemaType = "String"
            if let format = stringSchema.format {
                docLines.append("**Format:** \(format.rawValue)")
            }
            if let pattern = stringSchema.pattern {
                docLines.append("**Pattern:** `\(pattern)`")
            }
            if let minLength = stringSchema.minLength {
                docLines.append("**Minimum Length:** \(minLength)")
            }
            if let maxLength = stringSchema.maxLength {
                docLines.append("**Maximum Length:** \(maxLength)")
            }
            // Additional string constraints could be added here
            
        case .number(let numSchema):
            schemaType = "Number"
            if let minimum = numSchema.minimum {
                let exclusive = numSchema.exclusiveMinimum ?? false
                docLines.append("**Minimum:** \(minimum)\(exclusive ? " (exclusive)" : "")")
            }
            if let maximum = numSchema.maximum {
                let exclusive = numSchema.exclusiveMaximum ?? false
                docLines.append("**Maximum:** \(maximum)\(exclusive ? " (exclusive)" : "")")
            }
            if let multipleOf = numSchema.multipleOf {
                docLines.append("**Multiple Of:** \(multipleOf)")
            }
            
        case .integer(let intSchema):
            schemaType = "Integer"
            if let minimum = intSchema.minimum {
                let exclusive = intSchema.exclusiveMinimum ?? false
                docLines.append("**Minimum:** \(minimum)\(exclusive ? " (exclusive)" : "")")
            }
            if let maximum = intSchema.maximum {
                let exclusive = intSchema.exclusiveMaximum ?? false
                docLines.append("**Maximum:** \(maximum)\(exclusive ? " (exclusive)" : "")")
            }
            if let multipleOf = intSchema.multipleOf {
                docLines.append("**Multiple Of:** \(multipleOf)")
            }
            
        case .boolean(_):
            schemaType = "Boolean"
            
        case .reference(let ref):
            schemaType = "Reference"
            docLines.append("**References:** `\(ref.ref)`")
            
        case .allOf(let schemas):
            schemaType = "Composite (AllOf)"
            docLines.append("**Combines all of the following schemas:**")
            for (index, subSchema) in schemas.enumerated() {
                let subType = self.getDisplayType(for: subSchema)
                docLines.append("\(index + 1). \(subType)")
            }
            
        case .anyOf(let schemas):
            schemaType = "Composite (AnyOf)"
            docLines.append("**Matches any of the following schemas:**")
            for (index, subSchema) in schemas.enumerated() {
                let subType = self.getDisplayType(for: subSchema)
                docLines.append("\(index + 1). \(subType)")
            }
            
        case .oneOf(let schemas):
            schemaType = "Composite (OneOf)"
            docLines.append("**Matches exactly one of the following schemas:**")
            for (index, subSchema) in schemas.enumerated() {
                let subType = self.getDisplayType(for: subSchema)
                docLines.append("\(index + 1). \(subType)")
            }
            
        case .not(let subSchema):
            schemaType = "Not"
            let negatedType = self.getDisplayType(for: subSchema)
            docLines.append("**Must not match:** \(negatedType)")
        }
        
        var docComment: SymbolKit.SymbolGraph.LineList? = nil
        if !docLines.isEmpty {
            let lines = docLines.map { SymbolKit.SymbolGraph.LineList.Line(text: $0, range: nil) }
            docComment = SymbolKit.SymbolGraph.LineList(lines)
        }
        
        return SymbolKit.SymbolGraph.Symbol(
            identifier: identifier,
            names: names,
            pathComponents: [name],
            docComment: docComment,
            accessLevel: SymbolKit.SymbolGraph.Symbol.AccessControl(rawValue: "public"),
            // Use struct kind for all schemas for simplicity
            kind: .init(parsedIdentifier: .struct, displayName: schemaType),
            mixins: [:]
        )
    }
    
    /// Get a display-friendly type name for a schema
    private func getDisplayType(for schema: JSONSchema) -> String {
        switch schema {
        case .string(_): return "String"
        case .number(_): return "Number"
        case .integer(_): return "Integer"
        case .boolean(_): return "Boolean"
        case .array(let arraySchema):
            return "Array<\(getDisplayType(for: arraySchema.items))>"
        case .object(_): return "Object"
        case .reference(let ref):
            // Extract name from reference
            if let refName = ref.ref.split(separator: "/").last {
                return String(refName)
            }
            return "Reference"
        case .allOf(_): return "AllOf Composite"
        case .anyOf(_): return "AnyOf Composite"
        case .oneOf(_): return "OneOf Composite"
        case .not(let schema): return "Not<\(getDisplayType(for: schema))>"
        }
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
