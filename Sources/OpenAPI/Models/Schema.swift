import Foundation

/// Represents a JSON schema in OpenAPI
public indirect enum JSONSchema: Equatable {
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

    /// The description of the schema
    public var description: String? {
        switch self {
        case .string(let schema): return schema.description
        case .number(let schema): return schema.description
        case .integer(let schema): return schema.description
        case .boolean(let schema): return schema.description
        case .array(let schema): return schema.description
        case .object(let schema): return schema.description
        case .reference(let ref): return ref.description
        case .allOf(let schemas): return schemas.compactMap { $0.description }.joined(separator: "\n")
        case .anyOf(let schemas): return schemas.compactMap { $0.description }.joined(separator: "\n")
        case .oneOf(let schemas): return schemas.compactMap { $0.description }.joined(separator: "\n")
        case .not(let schema): return schema.description
        }
    }

    // Custom implementation of equality for JSONSchema
    public static func == (lhs: JSONSchema, rhs: JSONSchema) -> Bool {
        switch (lhs, rhs) {
        case (.string, .string):
            return true // Simplified for reference detection
        case (.number, .number):
            return true
        case (.integer, .integer):
            return true
        case (.boolean, .boolean):
            return true
        case (.array, .array):
            return true
        case (.object, .object):
            return true
        case (.reference(let lhsRef), .reference(let rhsRef)):
            return lhsRef.ref == rhsRef.ref
        case (.allOf(let lhsSchemas), .allOf(let rhsSchemas)):
            return lhsSchemas == rhsSchemas
        case (.anyOf(let lhsSchemas), .anyOf(let rhsSchemas)):
            return lhsSchemas == rhsSchemas
        case (.oneOf(let lhsSchemas), .oneOf(let rhsSchemas)):
            return lhsSchemas == rhsSchemas
        case (.not(let lhsSchema), .not(let rhsSchema)):
            return lhsSchema == rhsSchema
        default:
            return false
        }
    }
}

/// Represents a string schema
public struct StringSchema: Equatable {
    /// The format of the string
    public let format: StringFormat?

    /// The minimum length of the string
    public let minLength: Int?

    /// The maximum length of the string
    public let maxLength: Int?

    /// The pattern the string must match
    public let pattern: String?

    /// The description of the schema
    public let description: String?

    /// Enumerated values allowed for this string
    public let enumValues: [String]?

    /// Example value for this string
    public let example: String?

    /// Creates a new string schema
    /// - Parameters:
    ///   - format: The format of the string
    ///   - minLength: The minimum length of the string
    ///   - maxLength: The maximum length of the string
    ///   - pattern: The pattern the string must match
    ///   - description: The description of the schema
    ///   - enumValues: Enumerated values allowed for this string
    ///   - example: Example value for this string
    public init(
        format: StringFormat? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        description: String? = nil,
        enumValues: [String]? = nil,
        example: String? = nil
    ) {
        self.format = format
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.description = description
        self.enumValues = enumValues
        self.example = example
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
public struct NumberSchema: Equatable {
    /// The format of the number (float, double, etc.)
    public let format: String?

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

    /// The description of the schema
    public let description: String?

    /// Enumerated values allowed for this number
    public let enumValues: [Double]?

    /// Example value for this number
    public let example: Double?

    /// Creates a new number schema
    /// - Parameters:
    ///   - format: The format of the number (float, double, etc.)
    ///   - minimum: The minimum value
    ///   - exclusiveMinimum: Whether the minimum value is exclusive
    ///   - maximum: The maximum value
    ///   - exclusiveMaximum: Whether the maximum value is exclusive
    ///   - multipleOf: The multiple of value
    ///   - description: The description of the schema
    ///   - enumValues: Enumerated values allowed for this number
    ///   - example: Example value for this number
    public init(
        format: String? = nil,
        minimum: Double? = nil,
        exclusiveMinimum: Bool? = nil,
        maximum: Double? = nil,
        exclusiveMaximum: Bool? = nil,
        multipleOf: Double? = nil,
        description: String? = nil,
        enumValues: [Double]? = nil,
        example: Double? = nil
    ) {
        self.format = format
        self.minimum = minimum
        self.exclusiveMinimum = exclusiveMinimum
        self.maximum = maximum
        self.exclusiveMaximum = exclusiveMaximum
        self.multipleOf = multipleOf
        self.description = description
        self.enumValues = enumValues
        self.example = example
    }
}

/// Represents an integer schema
public struct IntegerSchema: Equatable {
    /// The format of the integer (int32, int64, etc.)
    public let format: String?

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

    /// The description of the schema
    public let description: String?

    /// Enumerated values allowed for this integer
    public let enumValues: [Int]?

    /// Example value for this integer
    public let example: Int?

    /// Creates a new integer schema
    /// - Parameters:
    ///   - format: The format of the integer (int32, int64, etc.)
    ///   - minimum: The minimum value
    ///   - exclusiveMinimum: Whether the minimum value is exclusive
    ///   - maximum: The maximum value
    ///   - exclusiveMaximum: Whether the maximum value is exclusive
    ///   - multipleOf: The multiple of value
    ///   - description: The description of the schema
    ///   - enumValues: Enumerated values allowed for this integer
    ///   - example: Example value for this integer
    public init(
        format: String? = nil,
        minimum: Int? = nil,
        exclusiveMinimum: Bool? = nil,
        maximum: Int? = nil,
        exclusiveMaximum: Bool? = nil,
        multipleOf: Int? = nil,
        description: String? = nil,
        enumValues: [Int]? = nil,
        example: Int? = nil
    ) {
        self.format = format
        self.minimum = minimum
        self.exclusiveMinimum = exclusiveMinimum
        self.maximum = maximum
        self.exclusiveMaximum = exclusiveMaximum
        self.multipleOf = multipleOf
        self.description = description
        self.enumValues = enumValues
        self.example = example
    }
}

/// Represents a boolean schema
public struct BooleanSchema: Equatable {
    /// The description of the schema
    public let description: String?

    /// Example value for this boolean
    public let example: Bool?

    /// Creates a new boolean schema
    /// - Parameters:
    ///   - description: The description of the schema
    ///   - example: Example value for this boolean
    public init(description: String? = nil, example: Bool? = nil) {
        self.description = description
        self.example = example
    }
}

/// Represents an array schema
public struct ArraySchema: Equatable {
    /// The schema of the items in the array
    public let items: JSONSchema

    /// The minimum number of items
    public let minItems: Int?

    /// The maximum number of items
    public let maxItems: Int?

    /// Whether items must be unique
    public let uniqueItems: Bool?

    /// The description of the schema
    public let description: String?

    /// Example value for this array
    public let example: [Any]?

    public static func == (lhs: ArraySchema, rhs: ArraySchema) -> Bool {
        return lhs.items == rhs.items &&
               lhs.minItems == rhs.minItems &&
               lhs.maxItems == rhs.maxItems &&
               lhs.uniqueItems == rhs.uniqueItems &&
               lhs.description == rhs.description
        // We intentionally do not compare 'example' here
    }

    /// Creates a new array schema
    /// - Parameters:
    ///   - items: The schema of the items in the array
    ///   - minItems: The minimum number of items
    ///   - maxItems: The maximum number of items
    ///   - uniqueItems: Whether items must be unique
    ///   - description: The description of the schema
    ///   - example: Example value for this array
    public init(
        items: JSONSchema,
        minItems: Int? = nil,
        maxItems: Int? = nil,
        uniqueItems: Bool? = nil,
        description: String? = nil,
        example: [Any]? = nil
    ) {
        self.items = items
        self.minItems = minItems
        self.maxItems = maxItems
        self.uniqueItems = uniqueItems
        self.description = description
        self.example = example
    }
}

/// Represents an object schema
public struct ObjectSchema: Equatable {
    /// The required properties
    public let required: [String]

    /// The properties of the object
    public let properties: [String: JSONSchema]

    /// The additional properties schema
    public let additionalProperties: JSONSchema?

    /// The description of the schema
    public let description: String?

    /// Example value for this object
    public let example: [String: Any]?

    public static func == (lhs: ObjectSchema, rhs: ObjectSchema) -> Bool {
        return lhs.required == rhs.required &&
               lhs.properties == rhs.properties &&
               lhs.additionalProperties == rhs.additionalProperties &&
               lhs.description == rhs.description
        // We intentionally do not compare 'example' here
    }

    /// Creates a new object schema
    /// - Parameters:
    ///   - required: The required properties
    ///   - properties: The properties of the object
    ///   - additionalProperties: The additional properties schema
    ///   - description: The description of the schema
    ///   - example: Example value for this object
    public init(
        required: [String] = [],
        properties: [String: JSONSchema] = [:],
        additionalProperties: JSONSchema? = nil,
        description: String? = nil,
        example: [String: Any]? = nil
    ) {
        self.required = required
        self.properties = properties
        self.additionalProperties = additionalProperties
        self.description = description
        self.example = example
    }
}

/// Represents a reference to another schema
public struct Reference: Equatable {
    /// The reference path
    public let ref: String

    /// The description of the reference
    public let description: String?

    /// Creates a new reference
    /// - Parameters:
    ///   - ref: The reference path
    ///   - description: The description of the reference
    public init(ref: String, description: String? = nil) {
        self.ref = ref
        self.description = description
    }
}
