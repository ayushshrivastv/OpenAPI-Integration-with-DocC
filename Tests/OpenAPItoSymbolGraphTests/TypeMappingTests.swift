import XCTest
import OpenAPIKit
@testable import OpenAPItoSymbolGraph

final class TypeMappingTests: XCTestCase {
    func testStringTypeMapping() {
        // Test basic string
        let basicString = OpenAPIKit.JSONSchema.string
        let (basicType, basicDocs) = SymbolMapper.mapSchemaType(basicString)
        XCTAssertEqual(basicType, "String")
        XCTAssertTrue(basicDocs.isEmpty)
        
        // Test string with format
        let dateString = OpenAPIKit.JSONSchema.string(format: .date)
        let (dateType, dateDocs) = SymbolMapper.mapSchemaType(dateString)
        XCTAssertEqual(dateType, "Date")
        XCTAssertTrue(dateDocs.contains("Format: date"))
        
        // Test string with constraints
        let constrainedString = OpenAPIKit.JSONSchema.string(
            .init(
                minLength: 1,
                maxLength: 100,
                pattern: "^[a-zA-Z]+$"
            )
        )
        let (constrainedType, constrainedDocs) = SymbolMapper.mapSchemaType(constrainedString)
        XCTAssertEqual(constrainedType, "String")
        XCTAssertTrue(constrainedDocs.contains("Minimum length: 1"))
        XCTAssertTrue(constrainedDocs.contains("Maximum length: 100"))
        XCTAssertTrue(constrainedDocs.contains("Pattern: ^[a-zA-Z]+$"))
        
        // Test string with enum values
        let enumString = OpenAPIKit.JSONSchema.string(
            .init(allowedValues: ["A", "B", "C"])
        )
        let (enumType, enumDocs) = SymbolMapper.mapSchemaType(enumString)
        XCTAssertEqual(enumType, "String")
        XCTAssertTrue(enumDocs.contains("Allowed values: A, B, C"))
    }
    
    func testNumericTypeMapping() {
        // Test integer
        let basicInt = OpenAPIKit.JSONSchema.integer
        let (basicType, basicDocs) = SymbolMapper.mapSchemaType(basicInt)
        XCTAssertEqual(basicType, "Int")
        XCTAssertTrue(basicDocs.isEmpty)
        
        // Test integer with format
        let int32 = OpenAPIKit.JSONSchema.integer(format: .int32)
        let (int32Type, int32Docs) = SymbolMapper.mapSchemaType(int32)
        XCTAssertEqual(int32Type, "Int32")
        XCTAssertTrue(int32Docs.isEmpty) // Assuming format doesn't add docs itself
        
        // Test number with constraints
        let constrainedNumber = OpenAPIKit.JSONSchema.number(
            .init(
                minimum: (0, exclusive: false),
                maximum: (100, exclusive: false),
                multipleOf: 2
            )
        )
        let (constrainedType, constrainedDocs) = SymbolMapper.mapSchemaType(constrainedNumber)
        XCTAssertEqual(constrainedType, "Double")
        XCTAssertTrue(constrainedDocs.contains("Minimum value: 0"))
        XCTAssertTrue(constrainedDocs.contains("Maximum value: 100"))
        XCTAssertTrue(constrainedDocs.contains("Must be multiple of: 2"))
    }
    
    func testArrayTypeMapping() {
        // Test array of strings
        let stringArray = OpenAPIKit.JSONSchema.array(
            .init(items: .string)
        )
        let (arrayType, arrayDocs) = SymbolMapper.mapSchemaType(stringArray)
        XCTAssertEqual(arrayType, "[String]")
        XCTAssertTrue(arrayDocs.isEmpty) // Assuming basic array doesn't add docs
        
        // Test array with constraints
        let constrainedArray = OpenAPIKit.JSONSchema.array(
            .init(
                items: .string,
                minItems: 1,
                maxItems: 10
            )
        )
        let (constrainedType, constrainedDocs) = SymbolMapper.mapSchemaType(constrainedArray)
        XCTAssertEqual(constrainedType, "[String]")
        XCTAssertTrue(constrainedDocs.contains("Minimum items: 1"))
        XCTAssertTrue(constrainedDocs.contains("Maximum items: 10"))
    }
    
    func testObjectTypeMapping() {
        // Test object with properties
        let userSchema = OpenAPIKit.JSONSchema.object(
            .init(
                properties: [
                    "id": .integer,
                    "name": .string,
                    "email": .string(format: .email)
                ],
                required: ["id", "name"]
            )
        )
        let (objectType, objectDocs) = SymbolMapper.mapSchemaType(userSchema)
        XCTAssertTrue(objectType.contains("id: Int"))
        XCTAssertTrue(objectType.contains("name: String"))
        XCTAssertTrue(objectType.contains("email: String")) // Format doesn't change base Swift type here
        XCTAssertTrue(objectDocs.contains("Required properties: id, name"))
    }
    
    func testSchemaDocumentation() {
        // Create a complex user schema
        let userSchema = OpenAPIKit.JSONSchema.object(
            .init(
                properties: [
                    "id": .integer(format: .int64),
                    "name": .string(
                        .init(
                            minLength: 1,
                            maxLength: 100
                        )
                    ),
                    "email": .string(format: .email),
                    "age": .integer(
                        .init(
                            minimum: (0, exclusive: false),
                            maximum: (120, exclusive: false)
                        )
                    ),
                    "tags": .array(
                        .init(
                            items: .string,
                            minItems: 1,
                            maxItems: 5
                        )
                    )
                ],
                required: ["id", "name", "email"]
            )
        )
        
        // Create symbols for the schema
        let (symbols, relationships) = SymbolMapper.createSchemaSymbol(
            name: "User",
            schema: userSchema
        )
        
        // Verify the main schema symbol
        let schemaSymbol = symbols.first { $0.identifier.precise == "s:API.User" }
        XCTAssertNotNil(schemaSymbol)
        XCTAssertEqual(schemaSymbol?.names.title, "User")
        
        // Verify property symbols
        let propertySymbols = symbols.filter { $0.identifier.precise.hasPrefix("s:API.User.") }
        XCTAssertEqual(propertySymbols.count, 5) // id, name, email, age, tags
        
        // Verify relationships
        XCTAssertEqual(relationships.count, 6) // 1 for schema + 5 for properties
        
        // Verify documentation content
        let schemaDoc = schemaSymbol?.docComment?.lines.map { $0.text }.joined(separator: "
") ?? ""
        XCTAssertTrue(schemaDoc.contains("Type Information:"))
        XCTAssertTrue(schemaDoc.contains("Required properties: id, name, email"))
        
        // Verify property documentation
        let idPropertySymbol = propertySymbols.first { $0.identifier.precise == "s:API.User.id" }
        XCTAssertNotNil(idPropertySymbol)
        let idDoc = idPropertySymbol?.docComment?.lines.map { $0.text }.joined(separator: "
") ?? ""
        XCTAssertTrue(idDoc.contains("Type Information:"))
        XCTAssertTrue(idDoc.contains("Format: int64"))
        
        let namePropertySymbol = propertySymbols.first { $0.identifier.precise == "s:API.User.name" }
        XCTAssertNotNil(namePropertySymbol)
        let nameDoc = namePropertySymbol?.docComment?.lines.map { $0.text }.joined(separator: "
") ?? ""
        XCTAssertTrue(nameDoc.contains("Minimum length: 1"))
        XCTAssertTrue(nameDoc.contains("Maximum length: 100"))
        
        let tagsPropertySymbol = propertySymbols.first { $0.identifier.precise == "s:API.User.tags" }
        XCTAssertNotNil(tagsPropertySymbol)
        let tagsDoc = tagsPropertySymbol?.docComment?.lines.map { $0.text }.joined(separator: "
") ?? ""
        XCTAssertTrue(tagsDoc.contains("Minimum items: 1"))
        XCTAssertTrue(tagsDoc.contains("Maximum items: 5"))
        XCTAssertTrue(tagsDoc.contains("Array items:")) // Check if item documentation is included
        XCTAssertTrue(tagsDoc.contains("type: String")) // Check if item type is mentioned
    }
} 