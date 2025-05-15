import XCTest
import Foundation
import OpenAPI
@testable import OpenAPItoSymbolGraph

final class DocCCatalogGeneratorTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Create a temporary directory for test output
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("DocCCatalogGeneratorTests-\(UUID().uuidString)")

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up temporary directory
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
        super.tearDown()
    }

    func testGenerateCatalogWithReferenceHandling() throws {
        // Create a document with schemas that reference each other
        let document = createTestDocument()

        // Create a generator
        let generator = DocCCatalogGenerator(moduleName: "TestAPI", outputDirectory: tempDir)

        // Generate a catalog
        let catalogDir = try generator.generateCatalog(from: document, overwrite: true)

        // Verify that the catalog was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalogDir.path))

        // Verify that the schemas directory was created
        let schemasDir = catalogDir.appendingPathComponent("Schemas")
        XCTAssertTrue(FileManager.default.fileExists(atPath: schemasDir.path))

        // Verify that the schema documentation files were created
        let petSchemaPath = schemasDir.appendingPathComponent("Pet.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: petSchemaPath.path))

        let tagSchemaPath = schemasDir.appendingPathComponent("Tag.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tagSchemaPath.path))

        // Verify the relationship graph was created
        let relationshipsPath = catalogDir.appendingPathComponent("SchemaRelationships.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: relationshipsPath.path))

        // Check pet schema file content for proper reference handling
        let petSchemaContent = try String(contentsOf: petSchemaPath, encoding: .utf8)

        // Check if the reference to Category is properly linked
        XCTAssertTrue(petSchemaContent.contains("- Type: ``Category``"))

        // Check if the array of Tag references is properly documented
        XCTAssertTrue(petSchemaContent.contains("array") && petSchemaContent.contains("``Tag``"))

        // Check if the related objects section is present
        XCTAssertTrue(petSchemaContent.contains("## Related Objects"))
    }

    func testGenerateCatalogWithComplexTypes() throws {
        // Create a document with complex types (arrays, maps, oneOf)
        let document = createDocumentWithComplexTypes()

        // Create a generator
        let generator = DocCCatalogGenerator(moduleName: "ComplexAPI", outputDirectory: tempDir)

        // Generate a catalog
        let catalogDir = try generator.generateCatalog(from: document, overwrite: true)

        // Verify the schemas directory was created
        let schemasDir = catalogDir.appendingPathComponent("Schemas")

        // Verify the complex type schema was created
        let complexSchemaPath = schemasDir.appendingPathComponent("ComplexObject.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: complexSchemaPath.path))

        // Check complex schema file content for proper handling of complex types
        let complexSchemaContent = try String(contentsOf: complexSchemaPath, encoding: .utf8)

        // Check if array property is properly documented
        XCTAssertTrue(complexSchemaContent.contains("- Type: array"))

        // Check if oneOf property is documented
        XCTAssertTrue(complexSchemaContent.contains("oneOf") || complexSchemaContent.contains("complex type"))
    }

    // MARK: - Helper Methods

    private func createTestDocument() -> Document {
        // Create schema objects with references
        let categorySchema = JSONSchema.object(
            ObjectSchema(
                properties: [
                    "id": .integer(IntegerSchema(description: "Category ID")),
                    "name": .string(StringSchema(description: "Category name"))
                ],
                description: "A category for a pet"
            )
        )

        let tagSchema = JSONSchema.object(
            ObjectSchema(
                properties: [
                    "id": .integer(IntegerSchema(description: "Tag ID")),
                    "name": .string(StringSchema(description: "Tag name"))
                ],
                description: "A tag for a pet"
            )
        )

        // Create a pet schema that references category and tag
        let petSchema = JSONSchema.object(
            ObjectSchema(
                required: ["name", "photoUrls"],
                properties: [
                    "id": .integer(IntegerSchema(description: "Pet ID")),
                    "name": .string(StringSchema(description: "Pet name")),
                    "category": .reference(Reference(ref: "#/components/schemas/Category")),
                    "photoUrls": .array(ArraySchema(
                        items: .string(StringSchema()),
                        description: "URLs to pet photos"
                    )),
                    "tags": .array(ArraySchema(
                        items: .reference(Reference(ref: "#/components/schemas/Tag")),
                        description: "Tags for the pet"
                    )),
                    "status": .string(StringSchema(description: "Pet status in the store"))
                ],
                description: "A pet in the store"
            )
        )

        // Create a store schema that references Pet
        let storeSchema = JSONSchema.object(
            ObjectSchema(
                properties: [
                    "id": .integer(IntegerSchema(description: "Store ID")),
                    "petsSold": .array(ArraySchema(
                        items: .reference(Reference(ref: "#/components/schemas/Pet")),
                        description: "Pets sold in this store"
                    ))
                ],
                description: "A store selling pets"
            )
        )

        // Create components with the schemas
        let components = Components(
            schemas: [
                "Pet": petSchema,
                "Category": categorySchema,
                "Tag": tagSchema,
                "Store": storeSchema
            ]
        )

        // Create a simple path for testing
        let getPets = Operation(
            responses: [
                "200": Response(
                    description: "An array of pets",
                    content: [
                        "application/json": MediaType(
                            schema: .array(ArraySchema(items: .reference(Reference(ref: "#/components/schemas/Pet"))))
                        )
                    ]
                )
            ],
            operationId: "getPets",
            summary: "Returns all pets",
            description: "Returns all pets from the system that the user has access to"
        )

        let pathItem = PathItem(get: getPets)

        // Create the document
        return Document(
            openapi: "3.0.0",
            info: Info(
                title: "Pet Store API",
                version: "1.0.0",
                description: "A sample API for testing the DocCCatalogGenerator"
            ),
            paths: ["/pets": pathItem],
            components: components
        )
    }

    private func createDocumentWithComplexTypes() -> Document {
        // Create a complex object schema with various types
        let complexSchema = JSONSchema.object(
            ObjectSchema(
                properties: [
                    "stringArray": .array(ArraySchema(
                        items: .string(StringSchema()),
                        description: "Array of strings"
                    )),
                    "numberMap": .object(ObjectSchema(
                        additionalProperties: .number(NumberSchema()),
                        description: "Map of string to number"
                    )),
                    "oneOfProperty": .oneOf([
                        .string(StringSchema()),
                        .integer(IntegerSchema())
                    ]),
                    "anyOfProperty": .anyOf([
                        .reference(Reference(ref: "#/components/schemas/SimpleObject")),
                        .string(StringSchema())
                    ]),
                    "allOfProperty": .allOf([
                        .object(ObjectSchema(
                            properties: ["name": .string(StringSchema())]
                        )),
                        .object(ObjectSchema(
                            properties: ["id": .integer(IntegerSchema())]
                        ))
                    ]),
                    "nestedArray": .array(ArraySchema(
                        items: .array(ArraySchema(items: .string(StringSchema()))),
                        description: "Nested array of strings"
                    ))
                ],
                description: "A complex object with various types"
            )
        )

        // Create a simple object for reference
        let simpleSchema = JSONSchema.object(
            ObjectSchema(
                properties: [
                    "id": .integer(IntegerSchema()),
                    "name": .string(StringSchema())
                ],
                description: "A simple object"
            )
        )

        // Create components with the schemas
        let components = Components(
            schemas: [
                "ComplexObject": complexSchema,
                "SimpleObject": simpleSchema
            ]
        )

        // Create a simple path for testing
        let getComplex = Operation(
            responses: [
                "200": Response(
                    description: "A complex object",
                    content: [
                        "application/json": MediaType(
                            schema: .reference(Reference(ref: "#/components/schemas/ComplexObject"))
                        )
                    ]
                )
            ],
            operationId: "getComplex",
            summary: "Returns a complex object",
            description: "Returns a complex object for testing"
        )

        let pathItem = PathItem(get: getComplex)

        // Create the document
        return Document(
            openapi: "3.0.0",
            info: Info(
                title: "Complex API",
                version: "1.0.0",
                description: "A sample API for testing complex type handling"
            ),
            paths: ["/complex": pathItem],
            components: components
        )
    }
}
