import Foundation

/// Represents a security scheme in OpenAPI
public enum SecurityScheme {
    /// HTTP authentication
    case http(HTTPSecurityScheme)
    /// API key authentication
    case apiKey(APIKeySecurityScheme)
    /// OAuth2 authentication
    case oauth2(OAuth2SecurityScheme)
    /// OpenID Connect authentication
    case openIdConnect(OpenIDConnectSecurityScheme)
}

/// Represents an HTTP authentication security scheme
public struct HTTPSecurityScheme {
    /// The HTTP authentication scheme
    public let scheme: String
    /// The format used for the bearer token
    public let bearerFormat: String?
    /// The description of the security scheme
    public let description: String?

    /// Creates a new HTTP security scheme
    /// - Parameters:
    ///   - scheme: The HTTP authentication scheme
    ///   - bearerFormat: The format used for the bearer token
    ///   - description: The description of the security scheme
    public init(scheme: String, bearerFormat: String? = nil, description: String? = nil) {
        self.scheme = scheme
        self.bearerFormat = bearerFormat
        self.description = description
    }
}

/// Represents an API key security scheme
public struct APIKeySecurityScheme {
    /// The name of the API key parameter
    public let name: String
    /// The location of the API key
    public let location: APIKeyLocation
    /// The description of the security scheme
    public let description: String?

    /// Creates a new API key security scheme
    /// - Parameters:
    ///   - name: The name of the API key parameter
    ///   - location: The location of the API key
    ///   - description: The description of the security scheme
    public init(name: String, location: APIKeyLocation, description: String? = nil) {
        self.name = name
        self.location = location
        self.description = description
    }
}

/// The location of an API key
public enum APIKeyLocation: String {
    /// In the query string
    case query
    /// In the headers
    case header
    /// In cookies
    case cookie
}

/// Represents an OAuth2 security scheme
public struct OAuth2SecurityScheme {
    /// The OAuth2 flows
    public let flows: OAuth2Flows?
    /// The description of the security scheme
    public let description: String?

    /// Creates a new OAuth2 security scheme
    /// - Parameters:
    ///   - flows: The OAuth2 flows
    ///   - description: The description of the security scheme
    public init(flows: OAuth2Flows? = nil, description: String? = nil) {
        self.flows = flows
        self.description = description
    }
}

/// Represents the OAuth2 flows
public struct OAuth2Flows {
    /// The implicit flow
    public let implicit: ImplicitFlow?
    /// The password flow
    public let password: PasswordFlow?
    /// The client credentials flow
    public let clientCredentials: ClientCredentialsFlow?
    /// The authorization code flow
    public let authorizationCode: AuthorizationCodeFlow?

    /// Creates a new OAuth2 flows object
    /// - Parameters:
    ///   - implicit: The implicit flow
    ///   - password: The password flow
    ///   - clientCredentials: The client credentials flow
    ///   - authorizationCode: The authorization code flow
    public init(
        implicit: ImplicitFlow? = nil,
        password: PasswordFlow? = nil,
        clientCredentials: ClientCredentialsFlow? = nil,
        authorizationCode: AuthorizationCodeFlow? = nil
    ) {
        self.implicit = implicit
        self.password = password
        self.clientCredentials = clientCredentials
        self.authorizationCode = authorizationCode
    }
}

/// Represents the implicit OAuth2 flow
public struct ImplicitFlow {
    /// The authorization URL
    public let authorizationURL: String
    /// The refresh URL
    public let refreshURL: String?
    /// The available scopes
    public let scopes: [String: String]

    /// Creates a new implicit flow
    /// - Parameters:
    ///   - authorizationURL: The authorization URL
    ///   - refreshURL: The refresh URL
    ///   - scopes: The available scopes
    public init(authorizationURL: String, refreshURL: String? = nil, scopes: [String: String] = [:]) {
        self.authorizationURL = authorizationURL
        self.refreshURL = refreshURL
        self.scopes = scopes
    }
}

/// Represents the password OAuth2 flow
public struct PasswordFlow {
    /// The token URL
    public let tokenURL: String
    /// The refresh URL
    public let refreshURL: String?
    /// The available scopes
    public let scopes: [String: String]

    /// Creates a new password flow
    /// - Parameters:
    ///   - tokenURL: The token URL
    ///   - refreshURL: The refresh URL
    ///   - scopes: The available scopes
    public init(tokenURL: String, refreshURL: String? = nil, scopes: [String: String] = [:]) {
        self.tokenURL = tokenURL
        self.refreshURL = refreshURL
        self.scopes = scopes
    }
}

/// Represents the client credentials OAuth2 flow
public struct ClientCredentialsFlow {
    /// The token URL
    public let tokenURL: String
    /// The refresh URL
    public let refreshURL: String?
    /// The available scopes
    public let scopes: [String: String]

    /// Creates a new client credentials flow
    /// - Parameters:
    ///   - tokenURL: The token URL
    ///   - refreshURL: The refresh URL
    ///   - scopes: The available scopes
    public init(tokenURL: String, refreshURL: String? = nil, scopes: [String: String] = [:]) {
        self.tokenURL = tokenURL
        self.refreshURL = refreshURL
        self.scopes = scopes
    }
}

/// Represents the authorization code OAuth2 flow
public struct AuthorizationCodeFlow {
    /// The authorization URL
    public let authorizationURL: String
    /// The token URL
    public let tokenURL: String
    /// The refresh URL
    public let refreshURL: String?
    /// The available scopes
    public let scopes: [String: String]

    /// Creates a new authorization code flow
    /// - Parameters:
    ///   - authorizationURL: The authorization URL
    ///   - tokenURL: The token URL
    ///   - refreshURL: The refresh URL
    ///   - scopes: The available scopes
    public init(
        authorizationURL: String,
        tokenURL: String,
        refreshURL: String? = nil,
        scopes: [String: String] = [:]
    ) {
        self.authorizationURL = authorizationURL
        self.tokenURL = tokenURL
        self.refreshURL = refreshURL
        self.scopes = scopes
    }
}

/// Represents an OpenID Connect security scheme
public struct OpenIDConnectSecurityScheme {
    /// The OpenID Connect URL
    public let openIdConnectURL: String
    /// The description of the security scheme
    public let description: String?

    /// Creates a new OpenID Connect security scheme
    /// - Parameters:
    ///   - openIdConnectURL: The OpenID Connect URL
    ///   - description: The description of the security scheme
    public init(openIdConnectURL: String, description: String? = nil) {
        self.openIdConnectURL = openIdConnectURL
        self.description = description
    }
}
