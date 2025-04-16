import Foundation

/// Represents a JSON schema in OpenAPI
public indirect enum JSONSchema {
    /// A string schema
    case string(StringSchema)
    
    /// A number schema
    case number(NumberSchema)
    
    /// An integer schema
    case integer(IntegerSchema)
    
    /// A boolean schema
    case boolean(BooleanSchema)
    
    /// An array schema
    case array(ArraySchema)
    
    /// An object schema
    case object(ObjectSchema)
    
    /// A reference to another schema
    case reference(Reference)
    
    /// A schema that must match all of the given schemas
    case allOf([JSONSchema])
    
    /// A schema that must match any of the given schemas
    case anyOf([JSONSchema])
    
    /// A schema that must match exactly one of the given schemas
    case oneOf([JSONSchema])
    
    /// A schema that must not match the given schema
    case not(JSONSchema)
}

/// Represents a string schema
public struct StringSchema {
    /// The format of the string
    public let format: StringFormat?
    
    /// The minimum length of the string
    public let minLength: Int?
    
    /// The maximum length of the string
    public let maxLength: Int?
    
    /// The pattern the string must match
    public let pattern: String?
    
    /// Creates a new string schema
    /// - Parameters:
    ///   - format: The format of the string
    ///   - minLength: The minimum length of the string
    ///   - maxLength: The maximum length of the string
    ///   - pattern: The pattern the string must match
    public init(
        format: StringFormat? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) {
        self.format = format
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }
}

/// The format of a string
public enum StringFormat: String {
    /// A date in ISO 8601 format
    case date
    
    /// A date-time in ISO 8601 format
    case dateTime = "date-time"
    
    /// A password
    case password
    
    /// A byte sequence
    case byte
    
    /// A binary sequence
    case binary
    
    /// An email address
    case email
    
    /// A UUID
    case uuid
    
    /// A URI
    case uri
    
    /// A hostname
    case hostname
    
    /// An IPv4 address
    case ipv4
    
    /// An IPv6 address
    case ipv6
}

/// Represents a number schema
public struct NumberSchema {
    /// The minimum value
    public let minimum: Double?
    
    /// Whether the minimum value is exclusive
    public let exclusiveMinimum: Bool?
    
    /// The maximum value
    public let maximum: Double?
    
    /// Whether the maximum value is exclusive
    public let exclusiveMaximum: Bool?
    
    /// The multiple of value
    public let multipleOf: Double?
    
    /// Creates a new number schema
    /// - Parameters:
    ///   - minimum: The minimum value
    ///   - exclusiveMinimum: Whether the minimum value is exclusive
    ///   - maximum: The maximum value
    ///   - exclusiveMaximum: Whether the maximum value is exclusive
    ///   - multipleOf: The multiple of value
    public init(
        minimum: Double? = nil,
        exclusiveMinimum: Bool? = nil,
        maximum: Double? = nil,
        exclusiveMaximum: Bool? = nil,
        multipleOf: Double? = nil
    ) {
        self.minimum = minimum
        self.exclusiveMinimum = exclusiveMinimum
        self.maximum = maximum
        self.exclusiveMaximum = exclusiveMaximum
        self.multipleOf = multipleOf
    }
}

/// Represents an integer schema
public struct IntegerSchema {
    /// The minimum value
    public let minimum: Int?
    
    /// Whether the minimum value is exclusive
    public let exclusiveMinimum: Bool?
    
    /// The maximum value
    public let maximum: Int?
    
    /// Whether the maximum value is exclusive
    public let exclusiveMaximum: Bool?
    
    /// The multiple of value
    public let multipleOf: Int?
    
    /// Creates a new integer schema
    /// - Parameters:
    ///   - minimum: The minimum value
    ///   - exclusiveMinimum: Whether the minimum value is exclusive
    ///   - maximum: The maximum value
    ///   - exclusiveMaximum: Whether the maximum value is exclusive
    ///   - multipleOf: The multiple of value
    public init(
        minimum: Int? = nil,
        exclusiveMinimum: Bool? = nil,
        maximum: Int? = nil,
        exclusiveMaximum: Bool? = nil,
        multipleOf: Int? = nil
    ) {
        self.minimum = minimum
        self.exclusiveMinimum = exclusiveMinimum
        self.maximum = maximum
        self.exclusiveMaximum = exclusiveMaximum
        self.multipleOf = multipleOf
    }
}

/// Represents a boolean schema
public struct BooleanSchema {
    /// Creates a new boolean schema
    public init() {}
}

/// Represents an array schema
public struct ArraySchema {
    /// The schema of the items in the array
    public let items: JSONSchema
    
    /// The minimum number of items
    public let minItems: Int?
    
    /// The maximum number of items
    public let maxItems: Int?
    
    /// Whether items must be unique
    public let uniqueItems: Bool?
    
    /// Creates a new array schema
    /// - Parameters:
    ///   - items: The schema of the items in the array
    ///   - minItems: The minimum number of items
    ///   - maxItems: The maximum number of items
    ///   - uniqueItems: Whether items must be unique
    public init(
        items: JSONSchema,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil
    ) {
        self.items = items
        self.minItems = minItems
        self.maxItems = maxItems
        self.uniqueItems = uniqueItems
    }
}

/// Represents an object schema
public struct ObjectSchema {
    /// The required properties
    public let required: [String]
    
    /// The properties of the object
    public let properties: [String: JSONSchema]
    
    /// The additional properties schema
    public let additionalProperties: JSONSchema?
    
    /// Creates a new object schema
    /// - Parameters:
    ///   - required: The required properties
    ///   - properties: The properties of the object
    ///   - additionalProperties: The additional properties schema
    public init(
        required: [String] = [],
        properties: [String: JSONSchema] = [:],
        additionalProperties: JSONSchema? = nil
    ) {
        self.required = required
        self.properties = properties
        self.additionalProperties = additionalProperties
    }
}

/// Represents a reference to another schema
public struct Reference {
    /// The reference path
    public let ref: String
    
    /// Creates a new reference
    /// - Parameter ref: The reference path
    public init(ref: String) {
        self.ref = ref
    }
} 
