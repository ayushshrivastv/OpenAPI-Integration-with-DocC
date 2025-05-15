import Foundation
import OpenAPI
import DocC
import Integration
import SymbolKit

/// A generator for DocC catalog files from OpenAPI documents
public struct DocCCatalogGenerator {
    /// The name to use for the module
    private let moduleName: String?
    /// Base URL for the API
    private let baseURL: URL?
    /// Output directory where the .docc catalog will be created
    private let outputDirectory: URL

    /// Creates a new DocC catalog generator
    /// - Parameters:
    ///   - moduleName: The name to use for the module. If nil, the info.title from the OpenAPI document will be used
    ///   - baseURL: The base URL to use for the API
    ///   - outputDirectory: The directory where the .docc catalog will be created
    public init(moduleName: String? = nil, baseURL: URL? = nil, outputDirectory: URL) {
        self.moduleName = moduleName
        self.baseURL = baseURL
        self.outputDirectory = outputDirectory
    }

    /// Generates a DocC catalog from an OpenAPI document
    /// - Parameters:
    ///   - document: The OpenAPI document to generate documentation from
    ///   - overwrite: Whether to overwrite existing files
    /// - Returns: The path to the generated .docc catalog
    /// - Throws: An error if the generation fails
    public func generateCatalog(from document: Document, overwrite: Bool = false) throws -> URL {
        // Create the catalog directory
        let catalogName = (moduleName ?? document.info.title)
            .replacingOccurrences(of: " ", with: "")
        let catalogDirectory = outputDirectory.appendingPathComponent("\(catalogName).docc")

        // Check if the catalog already exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: catalogDirectory.path) {
            if overwrite {
                try fileManager.removeItem(at: catalogDirectory)
            } else {
                throw CatalogGenerationError.catalogAlreadyExists(catalogDirectory.path)
            }
        }

        // Create the catalog directory
        try fileManager.createDirectory(at: catalogDirectory, withIntermediateDirectories: true)

        // Generate the root documentation file (ModuleName.md)
        try generateRootDocumentationFile(document: document, catalogDirectory: catalogDirectory)

        // Generate the symbol graph file
        try generateSymbolGraphFile(document: document, catalogDirectory: catalogDirectory)

        // Generate documentation files for endpoints
        try generateEndpointDocumentationFiles(document: document, catalogDirectory: catalogDirectory)

        // Generate documentation files for schemas
        try generateSchemaDocumentationFiles(document: document, catalogDirectory: catalogDirectory)

        return catalogDirectory
    }

    /// Generates the root documentation file for the catalog
    private func generateRootDocumentationFile(document: Document, catalogDirectory: URL) throws {
        let moduleTitle = moduleName ?? document.info.title
        let fileName = moduleTitle.replacingOccurrences(of: " ", with: "")
        let filePath = catalogDirectory.appendingPathComponent("\(fileName).md")

        var content = "# \(moduleTitle)\n\n"

        if let description = document.info.description {
            content += "\(description)\n\n"
        }

        // Add overview section
        content += "## Overview\n\n"

        // Count endpoints by tag or path
        var endpointsByTag: [String: Int] = [:]
        for (_, pathItem) in document.paths {
            for (method, operation) in pathItem.allOperations() {
                if let tags = operation.tags, !tags.isEmpty {
                    for tag in tags {
                        endpointsByTag[tag, default: 0] += 1
                    }
                } else {
                    endpointsByTag["Other", default: 0] += 1
                }
            }
        }

        // Add endpoint counts by tag
        for (tag, count) in endpointsByTag.sorted(by: { $0.key < $1.key }) {
            content += "- \(tag): \(count) endpoints\n"
        }
        content += "\n"

        // Add schema counts
        if let components = document.components, let schemas = components.schemas {
            content += "- \(schemas.count) data models\n\n"
        }

        // Add topics section with links to endpoints and schemas
        content += "## Topics\n\n"

        // Group endpoints by tag
        var endpointLinksByTag: [String: [String]] = [:]
        for (path, pathItem) in document.paths {
            for (method, operation) in pathItem.allOperations() {
                let operationId = operation.operationId ?? "\(method.rawValue)_\(path)"
                let sanitizedPath = operationId.replacingOccurrences(of: "/", with: "_")
                                            .replacingOccurrences(of: "{", with: "")
                                            .replacingOccurrences(of: "}", with: "")

                if let tags = operation.tags, !tags.isEmpty {
                    for tag in tags {
                        endpointLinksByTag[tag, default: []].append("- ``\(sanitizedPath)``")
                    }
                } else {
                    endpointLinksByTag["Endpoints", default: []].append("- ``\(sanitizedPath)``")
                }
            }
        }

        // Add endpoint links by tag
        for (tag, links) in endpointLinksByTag.sorted(by: { $0.key < $1.key }) {
            content += "### \(tag)\n\n"
            content += links.joined(separator: "\n") + "\n\n"
        }

        // Add schema links
        if let components = document.components, let schemas = components.schemas {
            content += "### Data Models\n\n"
            for (name, _) in schemas.sorted(by: { $0.key < $1.key }) {
                content += "- ``\(name)``\n"
            }
            content += "\n"
        }

        // Add documentation metadata
        if let version = document.info.version {
            content += "## Version\n\n"
            content += "Current version: \(version)\n\n"
        }

        if let contact = document.info.contact {
            content += "## Contact\n\n"
            if let name = contact.name {
                content += "- Name: \(name)\n"
            }
            if let email = contact.email {
                content += "- Email: \(email)\n"
            }
            if let url = contact.url {
                content += "- URL: \(url)\n"
            }
            content += "\n"
        }

        // Write the file
        try content.write(to: filePath, atomically: true, encoding: .utf8)
    }

    /// Generates a symbol graph file from the OpenAPI document
    private func generateSymbolGraphFile(document: Document, catalogDirectory: URL) throws {
        let converter = OpenAPIDocCConverter(moduleName: moduleName, baseURL: baseURL)
        let symbolGraph = converter.convert(document)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(symbolGraph)

        let fileName = (moduleName ?? document.info.title)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
        let filePath = catalogDirectory.appendingPathComponent("\(fileName).symbols.json")
        try jsonData.write(to: filePath)
    }

    /// Generates documentation files for endpoints
    private func generateEndpointDocumentationFiles(document: Document, catalogDirectory: URL) throws {
        // Create the directory for endpoint documentation
        let endpointsDirectory = catalogDirectory.appendingPathComponent("Endpoints")
        try FileManager.default.createDirectory(at: endpointsDirectory, withIntermediateDirectories: true)

        // Generate a file for each endpoint
        for (path, pathItem) in document.paths {
            for (method, operation) in pathItem.allOperations() {
                let operationId = operation.operationId ?? "\(method.rawValue)_\(path)"
                let sanitizedPath = operationId.replacingOccurrences(of: "/", with: "_")
                                            .replacingOccurrences(of: "{", with: "")
                                            .replacingOccurrences(of: "}", with: "")

                let filePath = endpointsDirectory.appendingPathComponent("\(sanitizedPath).md")

                var content = "# \(method.rawValue.uppercased()) \(path)\n\n"

                if let summary = operation.summary {
                    content += "\(summary)\n\n"
                }

                if let description = operation.description {
                    content += "\(description)\n\n"
                }

                // Add parameters section
                if let parameters = operation.parameters, !parameters.isEmpty {
                    content += "## Parameters\n\n"

                    for parameter in parameters {
                        content += "### \(parameter.name)\n\n"

                        if let description = parameter.description {
                            content += "\(description)\n\n"
                        }

                        content += "- In: \(parameter.in)\n"
                        content += "- Required: \(parameter.required ? "Yes" : "No")\n"

                        if let schema = parameter.schema, let type = schema.type {
                            content += "- Type: \(type)\n"

                            if let format = schema.format {
                                content += "- Format: \(format)\n"
                            }

                            if let defaultValue = schema.default {
                                content += "- Default: \(defaultValue)\n"
                            }

                            if let enumValues = schema.enum {
                                content += "- Allowed values: \(enumValues.joined(separator: ", "))\n"
                            }
                        }

                        content += "\n"

                        // Add example if available
                        if let example = parameter.example {
                            content += "#### Example\n\n"
                            content += "```\n\(formatValue(example))\n```\n\n"
                        } else if let schema = parameter.schema, let example = schema.example {
                            content += "#### Example\n\n"
                            content += "```\n\(formatValue(example))\n```\n\n"
                        }

                        // Add examples if available
                        if let examples = parameter.examples, !examples.isEmpty {
                            content += "#### Examples\n\n"
                            for (name, example) in examples {
                                content += "##### \(name)\n\n"

                                if let summary = example.summary {
                                    content += "\(summary)\n\n"
                                }

                                if let description = example.description {
                                    content += "\(description)\n\n"
                                }

                                if let value = example.value {
                                    content += "```\n\(formatValue(value))\n```\n\n"
                                }
                            }
                        }
                    }
                }

                // Add request body section
                if let requestBody = operation.requestBody {
                    content += "## Request Body\n\n"

                    if let description = requestBody.description {
                        content += "\(description)\n\n"
                    }

                    content += "Required: \(requestBody.required ? "Yes" : "No")\n\n"

                    if let contentDict = requestBody.content {
                        for (mediaType, mediaTypeContent) in contentDict {
                            content += "### Media Type: \(mediaType)\n\n"

                            if let schema = mediaTypeContent.schema, let ref = schema.ref {
                                let schemaName = ref.components(separatedBy: "/").last ?? ref
                                content += "Schema: ``\(schemaName)``\n\n"
                            } else if let schema = mediaTypeContent.schema {
                                content += "Schema type: \(schema.type ?? "object")\n\n"
                            }

                            // Add examples if present
                            if let examples = mediaTypeContent.examples {
                                content += formatExamples(examples: examples)
                            } else if let example = mediaTypeContent.example {
                                content += formatExample(example)
                            }
                        }
                    }
                }

                // Add responses section
                if !operation.responses.isEmpty {
                    content += "## Responses\n\n"

                    for (statusCode, response) in operation.responses.sorted(by: { $0.key < $1.key }) {
                        content += "### \(statusCode)\n\n"
                        content += "\(response.description)\n\n"

                        if let contentDict = response.content {
                            for (mediaType, mediaTypeContent) in contentDict {
                                content += "Media Type: \(mediaType)\n\n"

                                if let schema = mediaTypeContent.schema, let ref = schema.ref {
                                    let schemaName = ref.components(separatedBy: "/").last ?? ref
                                    content += "Schema: ``\(schemaName)``\n\n"
                                } else if let schema = mediaTypeContent.schema {
                                    content += "Schema type: \(schema.type ?? "object")\n\n"
                                }

                                // Add examples if present
                                if let examples = mediaTypeContent.examples {
                                    content += formatExamples(examples: examples)
                                } else if let example = mediaTypeContent.example {
                                    content += formatExample(example)
                                }
                            }
                        }
                    }
                }

                // Add security section
                if let security = operation.security, !security.isEmpty {
                    content += "## Security\n\n"

                    for requirement in security {
                        for (scheme, scopes) in requirement {
                            content += "### \(scheme)\n\n"

                            if !scopes.isEmpty {
                                content += "Required scopes:\n\n"
                                for scope in scopes {
                                    content += "- \(scope)\n"
                                }
                                content += "\n"
                            }
                        }
                    }
                }

                // Write the file
                try content.write(to: filePath, atomically: true, encoding: .utf8)
            }
        }
    }

    /// Generates documentation files for schemas
    private func generateSchemaDocumentationFiles(document: Document, catalogDirectory: URL) throws {
        guard let components = document.components, let schemas = components.schemas else {
            return
        }

        // Create the directory for schema documentation
        let schemasDirectory = catalogDirectory.appendingPathComponent("Schemas")
        try FileManager.default.createDirectory(at: schemasDirectory, withIntermediateDirectories: true)

        // Generate a file for each schema
        for (name, schema) in schemas {
            let filePath = schemasDirectory.appendingPathComponent("\(name).md")

            var content = "# \(name)\n\n"

            if let description = schema.description {
                content += "\(description)\n\n"
            }

            // Add schema type information
            content += "## Type Information\n\n"

            if let type = schema.type {
                content += "- Type: \(type)\n"
            } else {
                content += "- Type: object\n"
            }

            if let format = schema.format {
                content += "- Format: \(format)\n"
            }

            if let required = schema.required, !required.isEmpty {
                content += "- Required properties: \(required.joined(separator: ", "))\n"
            }

            content += "\n"

            // Add properties section
            if let properties = schema.properties, !properties.isEmpty {
                content += "## Properties\n\n"

                for (propertyName, propertySchema) in properties.sorted(by: { $0.key < $1.key }) {
                    content += "### \(propertyName)\n\n"

                    if let description = propertySchema.description {
                        content += "\(description)\n\n"
                    }

                    if let type = propertySchema.type {
                        content += "- Type: \(type)\n"
                    } else if let ref = propertySchema.ref {
                        let refName = ref.components(separatedBy: "/").last ?? ref
                        content += "- Type: ``\(refName)``\n"
                    }

                    if let format = propertySchema.format {
                        content += "- Format: \(format)\n"
                    }

                    if let defaultValue = propertySchema.default {
                        content += "- Default: \(defaultValue)\n"
                    }

                    if let enumValues = propertySchema.enum {
                        content += "- Allowed values: \(enumValues.joined(separator: ", "))\n"
                    }

                    content += "\n"

                    // Add example for the property if available
                    if let example = propertySchema.example {
                        content += "Example:\n```\n\(formatValue(example))\n```\n\n"
                    }
                }
            }

            // Add example section if available
            if let example = schema.example {
                content += formatExample(example)
            }

            // Write the file
            try content.write(to: filePath, atomically: true, encoding: .utf8)
        }
    }

    /// Extracts and formats examples for documentation
    private func formatExamples(examples: [String: Example]?) -> String {
        guard let examples = examples, !examples.isEmpty else {
            return ""
        }

        var result = "## Examples\n\n"

        for (name, example) in examples {
            result += "### \(name)\n\n"

            if let summary = example.summary {
                result += "\(summary)\n\n"
            }

            if let description = example.description {
                result += "\(description)\n\n"
            }

            if let externalValue = example.externalValue {
                result += "External value: \(externalValue)\n\n"
            } else if let value = example.value {
                // Format the example value as JSON
                result += "```json\n\(formatValue(value))\n```\n\n"
            }
        }

        return result
    }

    /// Formats a generic value for display in documentation
    private func formatValue(_ value: Any?) -> String {
        guard let value = value else {
            return "null"
        }

        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted]),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        // Fallback if the value is not valid JSON
        return String(describing: value)
    }

    /// Formats a single example for documentation
    private func formatExample(_ example: Any?) -> String {
        guard let example = example else {
            return ""
        }

        return "## Example\n\n```json\n\(formatValue(example))\n```\n\n"
    }
}

/// Errors that can occur during catalog generation
public enum CatalogGenerationError: Error {
    case catalogAlreadyExists(String)
    case failedToCreateDirectory(String)
    case failedToWriteFile(String)
}
