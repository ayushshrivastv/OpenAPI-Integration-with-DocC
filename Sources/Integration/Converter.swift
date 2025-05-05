import Foundation
import OpenAPI
import SymbolKit
import OpenAPIKit

/// Converts an OpenAPI document into a SymbolKit Symbol Graph.
///
/// - Parameters:
///   - openAPIDocument: The parsed OpenAPI document.
///   - moduleName: The name to use for the documentation module.
///   - baseURL: An optional base URL to associate with the API endpoints.
/// - Returns: A SymbolKit SymbolGraph representing the OpenAPI document.
func convertOpenAPIToSymbolGraph(
    openAPIDocument: OpenAPI.Document,
    moduleName: String,
    baseURL: URL? = nil
) -> SymbolGraph {

    // Create basic metadata and module
    let metadata = SymbolGraph.Metadata(
        formatVersion: .init(major: 1, minor: 0, patch: 0),
        generator: "openapi-to-symbolgraph"
    )

    let module = SymbolGraph.Module(
        name: moduleName,
        platform: .init(architecture: nil, vendor: nil, operatingSystem: nil)
    )

    // Create simplified symbols for API info
    var symbols: [SymbolGraph.Symbol] = []
    var relationships: [SymbolGraph.Relationship] = []

    // Create module symbol
    let moduleUSR = "oapi://\(moduleName)"
    let moduleSymbol = createModuleSymbol(usr: moduleUSR, title: moduleName, description: openAPIDocument.info.description ?? "")
    symbols.append(moduleSymbol)

    // Create basic path symbols - simplified approach
    for (path, _) in openAPIDocument.paths {
        let pathString = path.rawValue
        let pathSymbol = createPathSymbol(
            usr: "oapi://\(moduleName)/paths/\(pathString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? pathString)",
            path: pathString
        )
        symbols.append(pathSymbol)

        // Add path-to-module relationship
        relationships.append(SymbolGraph.Relationship(
            source: pathSymbol.identifier.precise,
            target: moduleUSR,
            kind: .memberOf,
            targetFallback: moduleName
        ))
    }

    return SymbolGraph(
        metadata: metadata,
        module: module,
        symbols: symbols,
        relationships: relationships
    )
}

// MARK: - Helper Methods

private func createModuleSymbol(usr: String, title: String, description: String) -> SymbolGraph.Symbol {
    let docComment: SymbolGraph.LineList?
    if !description.isEmpty {
        let lines = description.split(separator: "\n").map {
            SymbolGraph.LineList.Line(text: String($0), range: nil)
        }
        docComment = SymbolGraph.LineList(lines)
    } else {
        docComment = nil
    }

    return SymbolGraph.Symbol(
        identifier: .init(precise: usr, interfaceLanguage: "OpenAPI"),
        names: SymbolGraph.Symbol.Names(
            title: title,
            navigator: nil,
            subHeading: nil,
            prose: nil
        ),
        pathComponents: [title],
        docComment: docComment,
        accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
        kind: .init(parsedIdentifier: .module, displayName: "API"),
        mixins: [:]
    )
}

private func createPathSymbol(usr: String, path: String) -> SymbolGraph.Symbol {
    return SymbolGraph.Symbol(
        identifier: .init(precise: usr, interfaceLanguage: "OpenAPI"),
        names: SymbolGraph.Symbol.Names(
            title: path,
            navigator: nil,
            subHeading: nil,
            prose: nil
        ),
        pathComponents: [path],
        docComment: nil,
        accessLevel: SymbolGraph.Symbol.AccessControl(rawValue: "public"),
        kind: .init(parsedIdentifier: .protocol, displayName: "Path"),
        mixins: [:]
    )
}
 