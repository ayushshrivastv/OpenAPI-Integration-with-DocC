import Foundation

/// A parser for OpenAPI documents in JSON format
public struct JSONParser {
    /// Creates a new JSON parser
    public init() {}

    /// Parses a JSON string into an OpenAPI document
    /// - Parameter json: The JSON string to parse
    /// - Returns: The parsed OpenAPI document
    /// - Throws: An error if the JSON is invalid or cannot be parsed
    public func parse(_ json: String) throws -> Document {
        guard let jsonData = json.data(using: .utf8) else {
            throw ParserError.invalidJSON
        }

        return try parse(jsonData)
    }

    /// Parses a JSON file into an OpenAPI document
    /// - Parameter fileURL: The URL of the JSON file to parse
    /// - Returns: The parsed OpenAPI document
    /// - Throws: An error if the file cannot be read or parsed
    public func parse(fileURL: URL) throws -> Document {
        let jsonData = try Data(contentsOf: fileURL)
        return try parse(jsonData)
    }

    /// Parses JSON data into an OpenAPI document
    /// - Parameter data: The JSON data to parse
    /// - Returns: The parsed OpenAPI document
    /// - Throws: An error if the JSON is invalid or cannot be parsed
    public func parse(_ data: Data) throws -> Document {
        guard let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ParserError.invalidJSON
        }

        return try parseDocument(from: jsonDict)
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
        
        // More lenient validation of paths
        var hasValidPath = false
        for (_, pathValue) in pathsDict {
            if let pathDict = pathValue as? [String: Any] {
                for (key, _) in pathDict {
                    if ["get", "post", "put", "delete", "patch", "options", "head", "trace"].contains(key.lowercased()) {
                        hasValidPath = true
                        break
                    }
                }
            }
            if hasValidPath {
                break
            }
        }
        
        if !hasValidPath {
            // Just log a warning instead of throwing an error
            print("Warning: No valid paths with operations found in the document")
        }

        let info = try parseInfo(from: infoDict)
        let paths = try parsePaths(from: pathsDict)
        let components = try parseComponents(from: dict["components"] as? [String: Any])

        return Document(
            openapi: openapi,
            info: info,
            paths: paths,
            components: components
        )
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
            guard let pathDict = pathDict as? [String: Any] else {
                throw ParserError.invalidPathItem(path)
            }

            paths[path] = try parsePathItem(from: pathDict)
        }

        return paths
    }

    private func parsePathItem(from dict: [String: Any]) throws -> PathItem {
        let parameters = try parseParameters(from: dict["parameters"] as? [[String: Any]])

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

        let parameters = try parseParameters(from: dict["parameters"] as? [[String: Any]])
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
                // We can't resolve references during parsing since we don't have access
                // to the full document with components yet. Return a placeholder parameter
                // with the reference for later resolution.
                let refComponents = ref.split(separator: "/")
                
                // Ensure the reference format is correct (e.g., "#/components/parameters/SomeParam")
                guard refComponents.count >= 4,
                      refComponents[1] == "components",
                      refComponents[2] == "parameters" else {
                    throw ParserError.invalidDocument("Invalid parameter reference format: \(ref)")
                }
                
                let refName = String(refComponents[3])
                return Parameter(
                    name: refName, // Use the reference name as a placeholder
                    in: .path,     // Default to path - will be overridden during resolution
                    required: true, // Default to required - will be overridden during resolution
                    schema: .string(StringSchema()) // Default schema - will be overridden during resolution
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

        // Be more flexible with content validation
        guard let contentDict = dict["content"] as? [String: Any] else {
            print("Warning: Request body missing content field. Creating empty content.")
            return RequestBody(
                content: [:],
                required: dict["required"] as? Bool ?? false
            )
        }

        var content: [String: MediaType] = [:]

        for (contentType, mediaTypeDict) in contentDict {
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
            guard let responseDict = responseDict as? [String: Any] else {
                // Use utility method to create a placeholder response
                responses[statusCode] = ParserUtilities.createPlaceholderResponse(for: statusCode)
                continue
            }

            guard let description = responseDict["description"] as? String else {
                throw ParserError.missingRequiredField("description")
            }

            let content = try parseContent(from: responseDict["content"] as? [String: Any])

            responses[statusCode] = Response(
                description: description,
                content: content
            )
        }

        return responses
    }

    private func parseContent(from dict: [String: Any]?) throws -> [String: MediaType]? {
        guard let dict = dict else { return nil }

        var content: [String: MediaType] = [:]

        for (contentType, mediaTypeDict) in dict {
            guard let mediaTypeDict = mediaTypeDict as? [String: Any],
                  let schemaDict = mediaTypeDict["schema"] as? [String: Any] else {
                throw ParserError.invalidMediaType(contentType)
            }

            content[contentType] = MediaType(schema: try parseSchema(from: schemaDict))
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
            // Use utility method to handle unknown schema types
            return ParserUtilities.handleUnknownSchemaType(type)
        }
    }

    private func parseStringSchema(from dict: [String: Any]) throws -> StringSchema {
        let formatString = dict["format"] as? String
        let format: StringFormat?
        if let formatString = formatString {
            format = StringFormat(rawValue: formatString)
        } else {
            format = nil
        }

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
            for (name, schemaDict) in propertiesDict {
                guard let schemaDict = schemaDict as? [String: Any] else {
                    throw ParserError.invalidProperty(name)
                }

                properties[name] = try parseSchema(from: schemaDict)
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

        let required = dict["required"] as? [String] ?? []

        return ObjectSchema(
            required: required,
            properties: properties,
            additionalProperties: additionalProperties
        )
    }
}
