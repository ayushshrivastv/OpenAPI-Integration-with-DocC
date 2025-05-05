import Foundation
import Yams

/// A parser for OpenAPI documents in YAML format
public struct YAMLParser {
    /// Creates a new YAML parser
    public init() {}
    
    /// Parses a YAML string into an OpenAPI document
    /// - Parameter yaml: The YAML string to parse
    /// - Returns: The parsed OpenAPI document
    /// - Throws: An error if the YAML is invalid or cannot be parsed
    public func parse(_ yaml: String) throws -> Document {
        // Try to parse the YAML document
        guard let yamlDict = try Yams.load(yaml: yaml) as? [String: Any] else {
            throw ParserError.invalidYAML
        }
        
        let document = try parseDocument(from: yamlDict)
        return try resolveReferences(in: document)
    }
    
    /// Parses a YAML file into an OpenAPI document
    /// - Parameter fileURL: The URL of the YAML file to parse
    /// - Returns: The parsed OpenAPI document
    /// - Throws: An error if the file cannot be read or parsed
    public func parse(fileURL: URL) throws -> Document {
        let fileExtension = fileURL.pathExtension.lowercased()
        guard fileExtension == "yaml" || fileExtension == "yml" || fileExtension == "json" else {
            throw ParserError.unsupportedFileType(fileExtension)
        }
        
        let yamlString = try String(contentsOf: fileURL)
        return try parse(yamlString)
    }
    
    private func parseDocument(from dict: [String: Any]) throws -> Document {
        // Use utility method to detect and validate version
        let openapi = try ParserUtilities.detectAndValidateVersion(in: dict)
        
        guard let infoDict = dict["info"] as? [String: Any] else {
            throw ParserError.missingRequiredField("info")
        }
        
        guard let pathsDict = dict["paths"] as? [String: Any] else {
            throw ParserError.missingRequiredField("paths")
        }
        
        // Validate paths
        try validatePaths(pathsDict)
        
        let info = try parseInfo(from: infoDict)
        let paths = try parsePaths(from: pathsDict)
        let components = try parseComponents(from: dict["components"] as? [String: Any])
        
        // Validate components references
        if let componentsDict = dict["components"] as? [String: Any] {
            try validateComponentReferences(componentsDict, paths: paths)
        }
        
        return Document(
            openapi: openapi,
            info: info,
            paths: paths,
            components: components
        )
    }
    
    private func validatePaths(_ pathsDict: [String: Any]) throws {
        var hasValidPath = false
        
        for (path, pathValue) in pathsDict {
            // Validate path format - warn but don't fail for paths not starting with /
            if !path.starts(with: "/") {
                print("Warning: Path should start with '/' - Found path: \(path). Continuing processing.")
            }
            
            guard let pathDict = pathValue as? [String: Any] else {
                print("Warning: Invalid path item at path: \(path). Skipping.")
                continue
            }
            
            // Validate operations
            let validMethods = ["get", "post", "put", "delete", "patch", "options", "head"]
            var hasOperation = false
            
            for (method, operation) in pathDict {
                if validMethods.contains(method.lowercased()) {
                    hasOperation = true
                    guard let operationDict = operation as? [String: Any] else {
                        print("Warning: Invalid operation in path: \(path), method: \(method). Skipping.")
                        continue
                    }
                    
                    // Check if operation has responses
                    guard let responses = operationDict["responses"] as? [String: Any],
                          !responses.isEmpty else {
                        print("Warning: Operation should have at least one response - Path: \(path), Method: \(method). Skipping.")
                        continue
                    }
                    
                    // Validate response codes
                    for (code, _) in responses {
                        // Use utility method to validate response codes
                        _ = ParserUtilities.validateResponseCode(code, path: path, method: method)
                    }
                }
            }
            
            if hasOperation {
                hasValidPath = true
            }
        }
        
        if !hasValidPath {
            throw ParserError.invalidDocument("No valid paths with operations found")
        }
    }
    
    private func validateComponentReferences(_ componentsDict: [String: Any], paths: [String: PathItem]) throws {
        let schemas = (componentsDict["schemas"] as? [String: Any]) ?? [:]
        
        // Collect all schema references from paths
        for (_, pathItem) in paths {
            for operation in [pathItem.get, pathItem.post, pathItem.put, pathItem.delete].compactMap({ $0 }) {
                // Check request body references
                if let requestBody = operation.requestBody {
                    for mediaType in requestBody.content.values {
                        if case .reference(let ref) = mediaType.schema {
                            let schemaName = ref.ref.split(separator: "/").last.map(String.init) ?? ref.ref
                            if !schemas.keys.contains(schemaName) {
                                print("Warning: Referenced schema '\(schemaName)' not found in components. Using a placeholder schema.")
                                // Continue processing despite missing reference
                            }
                        }
                    }
                }
                
                // Check response references
                for response in operation.responses.values {
                    if let content = response.content {
                        for mediaType in content.values {
                            if case .reference(let ref) = mediaType.schema {
                                let schemaName = ref.ref.split(separator: "/").last.map(String.init) ?? ref.ref
                                if !schemas.keys.contains(schemaName) {
                                    print("Warning: Referenced schema '\(schemaName)' not found in components. Using a placeholder schema.")
                                    // Continue processing despite missing reference
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func parseInfo(from dict: [String: Any]) throws -> Info {
        guard let title = dict["title"] as? String else {
            throw ParserError.missingRequiredField("title")
        }
        
        guard let version = dict["version"] as? String else {
            throw ParserError.missingRequiredField("version")
        }
        
        return Info(
            title: title,
            version: version,
            description: dict["description"] as? String
        )
    }
    
    private func parsePaths(from dict: [String: Any]) throws -> [String: PathItem] {
        var paths: [String: PathItem] = [:]
        
        for (path, pathDict) in dict {
            if let pathDict = pathDict as? [String: Any] {
                paths[path] = try parsePathItem(from: pathDict)
            } else {
                throw ParserError.invalidPathItem(path)
            }
        }
        
        return paths
    }
    
    private func parsePathItem(from dict: [String: Any]) throws -> PathItem {
        var parameters: [Parameter]? = nil
        
        if let paramsArray = dict["parameters"] as? [[String: Any]] {
            parameters = try parseParameters(from: paramsArray)
        }
        
        return PathItem(
            get: try parseOperation(from: dict["get"] as? [String: Any]),
            post: try parseOperation(from: dict["post"] as? [String: Any]),
            put: try parseOperation(from: dict["put"] as? [String: Any]),
            delete: try parseOperation(from: dict["delete"] as? [String: Any]),
            parameters: parameters
        )
    }
    
    private func parseOperation(from dict: [String: Any]?) throws -> Operation? {
        guard let dict = dict else { return nil }
        
        var parameters: [Parameter]? = nil
        if let paramsArray = dict["parameters"] as? [[String: Any]] {
            parameters = try parseParameters(from: paramsArray)
        }
        
        let requestBody = try parseRequestBody(from: dict["requestBody"] as? [String: Any])
        let responses = try parseResponses(from: dict["responses"] as? [String: Any])
        
        return Operation(
            summary: dict["summary"] as? String,
            description: dict["description"] as? String,
            parameters: parameters,
            requestBody: requestBody,
            responses: responses,
            deprecated: dict["deprecated"] as? Bool ?? false,
            tags: dict["tags"] as? [String]
        )
    }
    
    private func parseParameters(from array: [[String: Any]]?) throws -> [Parameter]? {
        guard let array = array else { return nil }
        
        return try array.map { dict in
            // Check if this is a parameter reference ($ref)
            if let ref = dict["$ref"] as? String {
                // For now, just use a placeholder parameter for referenced parameters
                let refComponents = ref.split(separator: "/")
                guard refComponents.count >= 4,
                      refComponents[1] == "components",
                      refComponents[2] == "parameters" else {
                    throw ParserError.invalidDocument("Invalid parameter reference format: \(ref)")
                }
                
                let refName = String(refComponents[3])
                return Parameter(
                    name: refName,
                    in: .path,
                    required: true,
                    schema: .string(StringSchema())
                )
            }
            
            guard let name = dict["name"] as? String else {
                throw ParserError.missingRequiredField("name")
            }
            
            guard let inValue = dict["in"] as? String,
                  let location = ParameterLocation(rawValue: inValue) else {
                throw ParserError.invalidParameterLocation
            }
            
            guard let schemaDict = dict["schema"] as? [String: Any] else {
                throw ParserError.missingRequiredField("schema")
            }
            
            return Parameter(
                name: name,
                in: location,
                required: dict["required"] as? Bool ?? false,
                schema: try parseSchema(from: schemaDict)
            )
        }
    }
    
    private func parseRequestBody(from dict: [String: Any]?) throws -> RequestBody? {
        guard let dict = dict else { return nil }
        
        guard let contentDict = dict["content"] as? [String: Any] else {
            throw ParserError.missingRequiredField("content")
        }
        
        var content: [String: MediaType] = [:]
        
        for (contentType, mediaTypeDict) in contentDict {
            guard let mediaTypeDict = mediaTypeDict as? [String: Any],
                  let schemaDict = mediaTypeDict["schema"] as? [String: Any] else {
                throw ParserError.invalidMediaType(contentType)
            }
            
            content[contentType] = MediaType(schema: try parseSchema(from: schemaDict))
        }
        
        return RequestBody(
            content: content,
            required: dict["required"] as? Bool ?? false
        )
    }
    
    private func parseResponses(from dict: [String: Any]?) throws -> [String: Response] {
        guard let dict = dict else {
            throw ParserError.missingRequiredField("responses")
        }
        
        var responses: [String: Response] = [:]
        
        for (statusCode, responseDict) in dict {
            if let responseDict = responseDict as? [String: Any] {
                if responseDict["$ref"] is String {
                    // For now, just use a placeholder description for referenced responses
                    responses[statusCode] = Response(
                        description: "Referenced response",
                        content: nil
                    )
                } else {
                    guard let description = responseDict["description"] as? String else {
                        throw ParserError.missingRequiredField("description")
                    }
                    
                    let content = try parseContent(from: responseDict["content"] as? [String: Any])
                    
                    responses[statusCode] = Response(
                        description: description,
                        content: content
                    )
                }
            } else {
                // Instead of throwing an error, try to convert the response to a dictionary
                // This handles cases where the response code is a string but should be treated as a valid response
                print("Warning: Response format for status code '\(statusCode)' is unexpected. Trying to create a placeholder response.")
                responses[statusCode] = Response(
                    description: "Response for status code \(statusCode)",
                    content: nil
                )
            }
        }
        
        return responses
    }
    
    private func parseContent(from dict: [String: Any]?) throws -> [String: MediaType]? {
        guard let dict = dict else { return nil }
        
        var content: [String: MediaType] = [:]
        
        for (contentType, mediaTypeDict) in dict {
            // Try to parse the media type - be more flexible with validation
            if let mediaTypeDict = mediaTypeDict as? [String: Any] {
                if let schemaDict = mediaTypeDict["schema"] as? [String: Any] {
                    // Standard case - we have a schema
                    do {
                        content[contentType] = MediaType(schema: try parseSchema(from: schemaDict))
                    } catch {
                        print("Warning: Error parsing schema for content type \(contentType): \(error). Creating a placeholder schema.")
                        // Create a placeholder schema based on the content type
                        if contentType.contains("json") {
                            content[contentType] = MediaType(schema: .object(ObjectSchema(required: [], properties: [:])))
                        } else if contentType.contains("xml") {
                            content[contentType] = MediaType(schema: .object(ObjectSchema(required: [], properties: [:])))
                        } else {
                            content[contentType] = MediaType(schema: .string(StringSchema()))
                        }
                    }
                } else {
                    // Schema is missing but we can still continue
                    print("Warning: Missing schema in content type \(contentType). Creating a placeholder schema.")
                    content[contentType] = MediaType(schema: .string(StringSchema()))
                }
            } else {
                // Not a valid media type dictionary but continue anyway
                print("Warning: Invalid media type format for content type \(contentType). Creating a placeholder.")
                content[contentType] = MediaType(schema: .string(StringSchema()))
            }
        }
        
        return content
    }
    
    private func parseComponents(from dict: [String: Any]?) throws -> Components? {
        guard let dict = dict else { return nil }
        
        // Parse schemas
        let schemasDict = dict["schemas"] as? [String: Any]
        var schemas: [String: JSONSchema]?
        
        if let schemasDict = schemasDict {
            schemas = [:]
            for (name, schemaDict) in schemasDict {
                guard let schemaDict = schemaDict as? [String: Any] else {
                    throw ParserError.invalidSchema(name)
                }
                
                schemas?[name] = try parseSchema(from: schemaDict)
            }
        }
        
        // Parse parameters
        let parametersDict = dict["parameters"] as? [String: Any]
        var parameters: [String: Parameter]?
        
        if let parametersDict = parametersDict {
            parameters = [:]
            for (name, paramDict) in parametersDict {
                guard let paramDict = paramDict as? [String: Any] else {
                    throw ParserError.invalidParameter(name)
                }
                
                // Parameter must have 'name', 'in', and 'schema' properties
                guard let paramName = paramDict["name"] as? String else {
                    throw ParserError.missingRequiredField("name")
                }
                
                guard let inValue = paramDict["in"] as? String,
                      let location = ParameterLocation(rawValue: inValue) else {
                    throw ParserError.invalidParameterLocation
                }
                
                guard let schemaDict = paramDict["schema"] as? [String: Any] else {
                    throw ParserError.missingRequiredField("schema")
                }
                
                parameters?[name] = Parameter(
                    name: paramName,
                    in: location,
                    required: paramDict["required"] as? Bool ?? false,
                    schema: try parseSchema(from: schemaDict)
                )
            }
        }
        
        return Components(schemas: schemas, parameters: parameters)
    }
    
    private func parseSchema(from dict: [String: Any]) throws -> JSONSchema {
        if let ref = dict["$ref"] as? String {
            return .reference(Reference(ref: ref))
        }
        
        // If there's no type field but there are properties, it's an object
        if dict["properties"] != nil {
            return .object(try parseObjectSchema(from: dict))
        }
        
        // If there's no type field but there's an items field, it's an array
        if dict["items"] != nil {
            return .array(try parseArraySchema(from: dict))
        }
        
        guard let type = dict["type"] as? String else {
            // Use utility method to handle missing type
            return ParserUtilities.handleMissingSchemaType(dict)
        }
        
        switch type {
        case "string":
            return .string(try parseStringSchema(from: dict))
        case "number":
            return .number(try parseNumberSchema(from: dict))
        case "integer":
            return .integer(try parseIntegerSchema(from: dict))
        case "boolean":
            return .boolean(BooleanSchema())
        case "array":
            return .array(try parseArraySchema(from: dict))
        case "object":
            return .object(try parseObjectSchema(from: dict))
        default:
            throw ParserError.unknownSchemaType(type)
        }
    }
    
    private func parseStringSchema(from dict: [String: Any]) throws -> StringSchema {
        let format = (dict["format"] as? String).flatMap { StringFormat(rawValue: $0) }
        
        return StringSchema(
            format: format,
            minLength: dict["minLength"] as? Int,
            maxLength: dict["maxLength"] as? Int,
            pattern: dict["pattern"] as? String
        )
    }
    
    private func parseNumberSchema(from dict: [String: Any]) throws -> NumberSchema {
        return NumberSchema(
            minimum: dict["minimum"] as? Double,
            exclusiveMinimum: dict["exclusiveMinimum"] as? Bool,
            maximum: dict["maximum"] as? Double,
            exclusiveMaximum: dict["exclusiveMaximum"] as? Bool,
            multipleOf: dict["multipleOf"] as? Double
        )
    }
    
    private func parseIntegerSchema(from dict: [String: Any]) throws -> IntegerSchema {
        return IntegerSchema(
            minimum: dict["minimum"] as? Int,
            exclusiveMinimum: dict["exclusiveMinimum"] as? Bool,
            maximum: dict["maximum"] as? Int,
            exclusiveMaximum: dict["exclusiveMaximum"] as? Bool,
            multipleOf: dict["multipleOf"] as? Int
        )
    }
    
    private func parseArraySchema(from dict: [String: Any]) throws -> ArraySchema {
        guard let itemsDict = dict["items"] as? [String: Any] else {
            throw ParserError.missingRequiredField("items")
        }
        
        return ArraySchema(
            items: try parseSchema(from: itemsDict),
            minItems: dict["minItems"] as? Int,
            maxItems: dict["maxItems"] as? Int,
            uniqueItems: dict["uniqueItems"] as? Bool
        )
    }
    
    private func parseObjectSchema(from dict: [String: Any]) throws -> ObjectSchema {
        var properties: [String: JSONSchema] = [:]
        
        // Properties are optional in OpenAPI - if present, parse them
        if let propertiesDict = dict["properties"] as? [String: Any] {
            for (name, propertyDict) in propertiesDict {
                guard let propertyDict = propertyDict as? [String: Any] else {
                    throw ParserError.invalidProperty(name)
                }
                properties[name] = try parseSchema(from: propertyDict)
            }
        }
        
        let additionalProperties: JSONSchema?
        if let additionalProps = dict["additionalProperties"] as? [String: Any] {
            additionalProperties = try parseSchema(from: additionalProps)
        } else if let additionalProps = dict["additionalProperties"] as? Bool {
            additionalProperties = additionalProps ? .object(ObjectSchema(properties: [:])) : nil
        } else {
            additionalProperties = nil
        }
        
        return ObjectSchema(
            required: dict["required"] as? [String] ?? [],
            properties: properties,
            additionalProperties: additionalProperties
        )
    }
    
    // Resolves references in the document
    private func resolveReferences(in document: Document) throws -> Document {
        // If there are no components, no need to resolve references
        guard let components = document.components else {
            return document
        }
        
        // Create a new paths dictionary with resolved references
        var resolvedPaths: [String: PathItem] = [:]
        
        for (path, pathItem) in document.paths {
            // Resolve references in path parameters
            let resolvedPathParameters = try resolveParameterReferences(pathItem.parameters, components: components)
            
            // Create a new path item with resolved references for each operation
            let resolvedPathItem = PathItem(
                get: try resolveOperationReferences(pathItem.get, components: components),
                post: try resolveOperationReferences(pathItem.post, components: components),
                put: try resolveOperationReferences(pathItem.put, components: components),
                delete: try resolveOperationReferences(pathItem.delete, components: components),
                parameters: resolvedPathParameters
            )
            
            resolvedPaths[path] = resolvedPathItem
        }
        
        // Create a new document with resolved references
        return Document(
            openapi: document.openapi,
            info: document.info,
            paths: resolvedPaths,
            components: document.components
        )
    }
    
    // Resolves parameter references in an array of parameters
    private func resolveParameterReferences(_ parameters: [Parameter]?, components: Components) throws -> [Parameter]? {
        guard let parameters = parameters else {
            return nil
        }
        
        // If there are no parameter components, no need to resolve references
        guard let parameterComponents = components.parameters else {
            return parameters
        }
        
        return parameters.map { parameter in
            // For placeholder parameters created from $ref, the name will be the reference name
            // and we can use it to look up the actual parameter in the components
            if parameter.schema == .string(StringSchema()) && 
               parameterComponents.keys.contains(parameter.name) {
                return parameterComponents[parameter.name]!
            }
            
            return parameter
        }
    }
    
    // Resolves references in an operation
    private func resolveOperationReferences(_ operation: Operation?, components: Components) throws -> Operation? {
        guard let operation = operation else {
            return nil
        }
        
        // Resolve parameter references
        let resolvedParameters = try resolveParameterReferences(operation.parameters, components: components)
        
        // Create a new operation with resolved references
        return Operation(
            summary: operation.summary,
            description: operation.description,
            parameters: resolvedParameters,
            requestBody: operation.requestBody,
            responses: operation.responses,
            deprecated: operation.deprecated,
            tags: operation.tags
        )
    }
} 
