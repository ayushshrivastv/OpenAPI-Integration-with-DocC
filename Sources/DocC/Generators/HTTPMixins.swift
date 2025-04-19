import Foundation
import SymbolKit
import OpenAPI

// Custom HTTP mixins implementation that follows SymbolKit pattern
extension SymbolKit.SymbolGraph.Symbol {
    /// Namespace for HTTP-specific mixins
    public enum HTTP {
        /// Mixin key for HTTP endpoint information
        public static let endpointMixinKey = "httpEndpoint"
        
        /// Mixin key for HTTP parameter source information
        public static let parameterSourceMixinKey = "httpParameterSource"
        
        /// Mixin key for HTTP media type information
        public static let mediaTypeMixinKey = "httpMediaType"
        
        /// The HTTP endpoint for a request.
        public struct Endpoint: Codable, SymbolKit.Mixin {
            public static let mixinKey = endpointMixinKey
            
            /// The HTTP method of the request (e.g., GET, POST, PUT, DELETE).
            /// The value is always uppercased.
            public var method: String
            
            /// The base URL of the request.
            public var baseURL: URL
            
            /// The alternate base URL of the request when used within a test environment.
            public var sandboxURL: URL?
            
            /// The relative path specific to the endpoint.
            public var path: String
            
            public init(method: String, baseURL: URL, sandboxURL: URL? = nil, path: String) {
                self.method = method.uppercased()
                self.baseURL = baseURL
                self.sandboxURL = sandboxURL
                self.path = path
            }
        }
        
        /// The source location of an HTTP parameter.
        public struct ParameterSource: Codable, SymbolKit.Mixin {
            public static let mixinKey = parameterSourceMixinKey
            
            /// The parameter source location (path, query, header, or cookie)
            public var value: String
            
            public init(_ value: String) {
                self.value = value
            }
            
            public init(_ location: ParameterLocation) {
                self.value = location.rawValue
            }
        }
        
        /// The encoding media type for an HTTP payload.
        public struct MediaType: Codable, SymbolKit.Mixin {
            public static let mixinKey = mediaTypeMixinKey
            
            /// The media type (e.g., "application/json")
            public var value: String
            
            public init(_ value: String) {
                self.value = value
            }
        }
    }
}

/// Protocol for SymbolKit mixins to ensure consistency
public protocol Mixin: Encodable {
    /// The key used to identify this mixin in a symbol's mixins dictionary
    static var mixinKey: String { get }
} 
