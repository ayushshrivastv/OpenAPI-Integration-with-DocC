import XCTest
import Foundation
import OpenAPI
import SymbolKit
import Yams
@testable import OpenAPItoSymbolGraph
@testable import OpenAPI
@testable import DocC
@testable import Integration

final class PetstoreTests: XCTestCase {
    func testPetstoreConversion() throws {
        let yamlString = """
        openapi: 3.0.0
        info:
          title: Swagger Petstore
          description: A sample API that uses a petstore as an example to demonstrate features in the OpenAPI specification
          version: 1.0.0
        servers:
          - url: http://petstore.swagger.io/v1
        paths:
          /pets:
            get:
              summary: List all pets
              description: Returns all pets from the system that the user has access to
              operationId: listPets
              tags:
                - pets
              parameters:
                - name: limit
                  in: query
                  description: How many items to return at one time (max 100)
                  required: false
                  schema:
                    type: integer
                    format: int32
              responses:
                '200':
                  description: A paged array of pets
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Pets'
                default:
                  description: unexpected error
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Error'
            post:
              summary: Create a pet
              description: Creates a new pet in the store
              operationId: createPet
              tags:
                - pets
              requestBody:
                required: true
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/NewPet'
              responses:
                '201':
                  description: Null response
                default:
                  description: unexpected error
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Error'
          /pets/{petId}:
            get:
              summary: Info for a specific pet
              description: Returns a pet based on a single ID
              operationId: showPetById
              tags:
                - pets
              parameters:
                - name: petId
                  in: path
                  required: true
                  description: The id of the pet to retrieve
                  schema:
                    type: string
              responses:
                '200':
                  description: Expected response to a valid request
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Pet'
                default:
                  description: unexpected error
                  content:
                    application/json:
                      schema:
                        $ref: '#/components/schemas/Error'
        components:
          schemas:
            Pet:
              type: object
              required:
                - id
                - name
              properties:
                id:
                  type: integer
                  format: int64
                name:
                  type: string
                tag:
                  type: string
            NewPet:
              type: object
              required:
                - name
              properties:
                name:
                  type: string
                tag:
                  type: string
            Pets:
              type: array
              items:
                $ref: '#/components/schemas/Pet'
            Error:
              type: object
              required:
                - code
                - message
              properties:
                code:
                  type: integer
                  format: int32
                message:
                  type: string
        """
        
        let parser = YAMLParser()
        let converter = OpenAPIDocCConverter()
        
        let document = try parser.parse(yamlString)
        let symbolGraph = converter.convert(document)
        
        // MARK: - SymbolGraph Assertions
        XCTAssertEqual(symbolGraph.module.name, "Swagger Petstore")

        // Count specific symbol kinds
        let operationSymbols = symbolGraph.symbols.values.filter { $0.kind.identifier == .method } 
        // Refined schema filter: only count structs with 1 path component (SchemaName)
        let topLevelSchemaSymbols = symbolGraph.symbols.values.filter { $0.kind.identifier == .struct && $0.pathComponents.count == 1 }
        
        XCTAssertEqual(operationSymbols.count, 3, "Incorrect number of operation symbols")
        XCTAssertEqual(topLevelSchemaSymbols.count, 4, "Incorrect number of top-level schema symbols") // Expect 4: Pet, NewPet, Pets, Error
        
        // Check specific symbols
        let listPetsOpIdentifier1 = "operation:listPets"
        let listPetsOpIdentifier2 = "operation:get:/pets"
        let listPetsOp = symbolGraph.symbols.values.first { $0.identifier.precise == listPetsOpIdentifier1 || $0.identifier.precise == listPetsOpIdentifier2 }
        XCTAssertNotNil(listPetsOp, "List pets operation missing")
        
        XCTAssertNotNil(symbolGraph.symbols.values.first { $0.identifier.precise.hasSuffix("schema:Pet") }, "Pet schema missing")
        XCTAssertNotNil(symbolGraph.symbols.values.first { $0.identifier.precise.hasSuffix("schema:NewPet") }, "NewPet schema missing")
        XCTAssertNotNil(symbolGraph.symbols.values.first { $0.identifier.precise.hasSuffix("schema:Pets") }, "Pets schema missing")
        XCTAssertNotNil(symbolGraph.symbols.values.first { $0.identifier.precise.hasSuffix("schema:Error") }, "Error schema missing")
        
        // Check specific doc comments
        XCTAssertEqual(listPetsOp?.docComment?.lines.first?.text, "Returns all pets from the system that the user has access to", "List pets description mismatch")
        
        // Check a relationship (Example: operation -> path)
        let pathPetsSymbol = symbolGraph.symbols.values.first { $0.identifier.precise == "path:/pets" }
        XCTAssertNotNil(pathPetsSymbol, "Path symbol /pets missing")
         
        // Find relationship with OPERATION as source and PATH as target
        let listPetsRelationship = symbolGraph.relationships.first { 
            $0.source == listPetsOp?.identifier.precise && // Source is Operation
            $0.target == pathPetsSymbol?.identifier.precise && // Target is Path
            $0.kind == SymbolKit.SymbolGraph.Relationship.Kind.memberOf 
        }
        XCTAssertNotNil(listPetsRelationship, "Relationship from listPets operation to /pets path missing")
    }
}
