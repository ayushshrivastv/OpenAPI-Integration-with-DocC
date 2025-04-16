import Foundation
import SymbolKit

/// Renders a symbol graph as Markdown documentation
public struct SymbolGraphRenderer {
    /// Creates a new symbol graph renderer
    public init() {}

    /// Renders a symbol graph as Markdown documentation
    /// - Parameter symbolGraph: The symbol graph to render
    /// - Returns: The Markdown documentation
    public func render(_ symbolGraph: SymbolKit.SymbolGraph) -> String {
        // Get module name (API title)
        let apiTitle = symbolGraph.module.name

        var output = """
        # \(apiTitle)
        
        Platform: \(symbolGraph.module.platform)
        
        ## Overview
        
        \(symbolGraph.symbols.values.filter { $0.kind.identifier == SymbolKit.SymbolGraph.Symbol.KindIdentifier.func }.count) Endpoints
        \(symbolGraph.symbols.values.filter { $0.kind.identifier == SymbolKit.SymbolGraph.Symbol.KindIdentifier.struct }.count) Schemas
        
        """

        // Group endpoints by tags or path components
        let endpoints = symbolGraph.symbols.values.filter { $0.kind.identifier == SymbolKit.SymbolGraph.Symbol.KindIdentifier.func }

        // Render endpoints
        if !endpoints.isEmpty {
            for endpoint in endpoints.sorted(by: { $0.names.title < $1.names.title }) {
                let title = endpoint.names.title
                output += "\n## \(title)\n\n"

                if let docComment = endpoint.docComment {
                    output += "\(docComment)\n\n"
                }

                // Find parameters
                let parameters = symbolGraph.relationships
                    .filter { $0.source == endpoint.identifier.precise && $0.kind == .memberOf }
                    .compactMap { relationship in
                        symbolGraph.symbols.values.first { $0.identifier.precise == relationship.target }
                    }

                if !parameters.isEmpty {
                    output += "**Parameters:**\n\n"
                    for param in parameters {
                        output += "- \(param.names.title)"
                        if let docComment = param.docComment {
                            output += ": \(docComment)"
                        }
                        output += "\n"
                    }
                    output += "\n"
                }

                // Find responses
                let responses = symbolGraph.relationships
                    .filter { $0.source == endpoint.identifier.precise && $0.kind == .memberOf }
                    .compactMap { relationship in
                        symbolGraph.symbols.values.first { $0.identifier.precise == relationship.target }
                    }

                if !responses.isEmpty {
                    for response in responses {
                        let responseTitle = response.names.title
                        output += "### \(responseTitle)\n\n"
                        if let docComment = response.docComment {
                            output += "\(docComment)\n\n"
                        }
                    }
                }
            }
        }

        // Render schemas
        let schemas = symbolGraph.symbols.values.filter { $0.kind.identifier == SymbolKit.SymbolGraph.Symbol.KindIdentifier.struct }
        if !schemas.isEmpty {
            output += "\n## Schemas\n\n"

            for schema in schemas.sorted(by: { $0.names.title < $1.names.title }) {
                output += "### \(schema.names.title)\n\n"

                if let docComment = schema.docComment {
                    output += "\(docComment)\n\n"
                }

                // Find properties through relationships
                let properties = symbolGraph.relationships
                    .filter { $0.source == schema.identifier.precise && $0.kind == .memberOf }
                    .compactMap { relationship in
                        symbolGraph.symbols.values.first { $0.identifier.precise == relationship.target }
                    }

                if !properties.isEmpty {
                    for property in properties.sorted(by: { $0.names.title < $1.names.title }) {
                        output += "- \(property.names.title)"
                        if let docComment = property.docComment {
                            output += ": \(docComment)"
                        }
                        output += "\n"
                    }
                }
            }
        }

        return output
    }
}
