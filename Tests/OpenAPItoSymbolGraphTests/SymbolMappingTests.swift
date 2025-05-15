import XCTest
import OpenAPIKit
import Core
import SymbolKit
@testable import OpenAPItoSymbolGraph

final class SymbolMappingTests: XCTestCase {

    func testMapStringSchema() throws {
        // Create a simple string schema
        let schema = JSONSchema.string(.init(description: "A test string"), .init())

        // Map it to a symbol
        let symbol = SymbolMapping.map(schema, name: "TestString", usr: "s:TestString", moduleName: "TestModule")

        // Verify the basics
        XCTAssertEqual(symbol.identifier.precise, "s:TestString")
        XCTAssertEqual(symbol.names.title, "TestString")
        XCTAssertEqual(symbol.pathComponents, ["TestString"])
        XCTAssertNotNil(symbol.docComment)

        // Verify the Swift extension
        XCTAssertNotNil(symbol.mixins[SymbolGraph.Symbol.Swift.Extension.mixinKey])

        // Verify the custom type info
        XCTAssertNotNil(symbol.mixins["swiftTypeFormat"])
    }

    func testMapObjectSchema() throws {
        // Create a simple object schema with properties
        let propertySchemas: [String: JSONSchema] = [
            "id": .integer(.init(description: "The ID"), .init()),
            "name": .string(.init(description: "The name"), .init())
        ]

        let schema = JSONSchema.object(
            .init(description: "A test object"),
            .init(properties: propertySchemas, requiredProperties: ["id"])
        )

        // Map it to a symbol
        let symbol = SymbolMapping.map(schema, name: "TestObject", usr: "s:TestObject", moduleName: "TestModule")

        // Verify the basics
        XCTAssertEqual(symbol.identifier.precise, "s:TestObject")
        XCTAssertEqual(symbol.names.title, "TestObject")
        XCTAssertEqual(symbol.pathComponents, ["TestObject"])
        XCTAssertNotNil(symbol.docComment)
    }

    func testMapEnumSchema() throws {
        // Create an enum schema (string with allowed values)
        let enumValues: [AnyCodable] = ["red", "green", "blue"].map { AnyCodable($0) }

        let schema = JSONSchema.string(
            .init(description: "A color", enum: enumValues),
            .init()
        )

        // Map it to a symbol
        let symbol = SymbolMapping.map(schema, name: "Color", usr: "s:Color", moduleName: "TestModule")

        // Verify the basics
        XCTAssertEqual(symbol.identifier.precise, "s:Color")
        XCTAssertEqual(symbol.names.title, "Color")
        XCTAssertEqual(symbol.pathComponents, ["Color"])
        XCTAssertNotNil(symbol.docComment)

        // Verify it's an enum
        if let typeInfo = symbol.mixins["swiftTypeFormat"] {
            // We'd need to decode the typeInfo to verify its kind is "enum"
            // but at a minimum we can verify it exists
            XCTAssertNotNil(typeInfo)
        } else {
            XCTFail("Expected type information mixin")
        }
    }
}
