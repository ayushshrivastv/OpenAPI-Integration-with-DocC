import Foundation
import SymbolKit
import Core

/// DocCGenerator is responsible for generating DocC-compatible documentation from SymbolGraph data.
public struct DocCGenerator {
    /// Configuration for the DocC generator
    public struct Configuration {
        /// The name of the documentation catalog
        public let catalogName: String
        
        /// The output directory for generated documentation
        public let outputDirectory: String
        
        /// The bundle identifier for the documentation
        public let bundleIdentifier: String
        
        /// The version number for the documentation
        public let version: String
        
        /// Creates a new configuration for the DocC generator
        public init(
            catalogName: String,
            outputDirectory: String,
            bundleIdentifier: String = "com.example.api",
            version: String = "1.0.0"
        ) {
            self.catalogName = catalogName
            self.outputDirectory = outputDirectory
            self.bundleIdentifier = bundleIdentifier
            self.version = version
        }
    }
    
    private let configuration: Configuration
    
    /// Creates a new DocC generator with the specified configuration
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Generates a DocC command for converting a symbol graph to documentation
    public func generateDocCCommand(symbolGraphPath: String) -> String {
        return """
        xcrun docc convert \(configuration.catalogName).docc \
        --fallback-display-name \(configuration.catalogName) \
        --fallback-bundle-identifier \(configuration.bundleIdentifier) \
        --fallback-bundle-version \(configuration.version) \
        --additional-symbol-graph-dir \(URL(fileURLWithPath: symbolGraphPath).deletingLastPathComponent().path) \
        --output-path \(configuration.outputDirectory)
        """
    }
    
    /// Creates a catalog directory structure for DocC
    public func createCatalogStructure(title: String, description: String) throws -> URL {
        let catalogURL = URL(fileURLWithPath: "\(configuration.catalogName).docc")
        try FileManager.default.createDirectory(at: catalogURL, withIntermediateDirectories: true)
        
        // Create main API.md file
        let apiMarkdownURL = catalogURL.appendingPathComponent("API.md")
        let apiMarkdown = """
        # \(title)
        
        \(description)
        
        ## Overview
        
        This documentation is generated from an OpenAPI specification, showcasing how REST APIs can be documented using DocC, Apple's documentation compiler.
        
        ## Key Features
        
        - Auto-generated documentation from OpenAPI schemas
        - Integration with DocC's navigation and search
        - Standard format for HTTP endpoints and request/response schemas
        - Consistent developer experience across API documentation
        
        ## Topics
        
        ### Endpoints
        
        - Add your endpoint links here
        
        ### Data Models
        
        - Add your model links here
        
        ### Getting Started
        
        - <doc:Getting-Started>
        """
        try apiMarkdown.write(to: apiMarkdownURL, atomically: true, encoding: .utf8)
        
        // Create Getting-Started.md file
        let gettingStartedURL = catalogURL.appendingPathComponent("Getting-Started.md")
        let gettingStartedMarkdown = """
        # Getting Started
        
        Learn how to use this REST API in your applications.
        
        ## Overview
        
        This documentation provides detailed information about the available endpoints, request parameters, and response formats for the API.
        
        ## Making Your First Request
        
        To make your first API request, follow these steps:
        
        1. Choose an endpoint from the documentation
        2. Prepare your request with the required parameters
        3. Send the request to the API server
        4. Process the response according to the documented format
        
        ## Authentication
        
        Most endpoints require authentication. See the individual endpoint documentation for specific requirements.
        
        ## Examples
        
        ```swift
        import Foundation
        
        let url = URL(string: "https://api.example.com/endpoint")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \\(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)
                print("Response: \\(json)")
            } catch {
                print("JSON parsing error: \\(error)")
            }
        }
        
        task.resume()
        ```
        """
        try gettingStartedMarkdown.write(to: gettingStartedURL, atomically: true, encoding: .utf8)
        
        return catalogURL
    }
} 
