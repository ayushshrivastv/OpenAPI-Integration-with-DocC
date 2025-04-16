import XCTest
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
        
        // Create parser and converter
        let parser = YAMLParser()
        let converter = OpenAPItoSymbolGraph()
        
        // Parse and convert
        let document = try parser.parse(yamlString)
        let markdown = try converter.convert(document)
        
        // Verify markdown content
        XCTAssertTrue(markdown.contains("# Swagger Petstore"))
        XCTAssertTrue(markdown.contains("## Overview"))
        XCTAssertTrue(markdown.contains("3 Endpoints"))
        XCTAssertTrue(markdown.contains("4 Schemas"))
        
        // Verify specific endpoint
        XCTAssertTrue(markdown.contains("## GET /pets"))
        XCTAssertTrue(markdown.contains("Returns all pets from the system that the user has access to"))
        
        // Verify parameters
        XCTAssertTrue(markdown.contains("limit"))
        XCTAssertTrue(markdown.contains("How many items to return at one time (max 100)"))
        
        // Verify schemas
        XCTAssertTrue(markdown.contains("### Pet"))
        XCTAssertTrue(markdown.contains("### NewPet"))
        XCTAssertTrue(markdown.contains("### Pets"))
        XCTAssertTrue(markdown.contains("### Error"))
    }
}
