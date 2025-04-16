import XCTest
@testable import OpenAPItoSymbolGraph
@testable import Integration
@testable import Core
@testable import OpenAPI

final class OpenAPIDocCConverterTests: XCTestCase {
    var converter: OpenAPIDocCConverter!
    
    override func setUp() {
        super.setUp()
        converter = OpenAPIDocCConverter()
    }
    
    func testConvertSimpleYAML() throws {
        let yaml = """
        openapi: 3.0.0
        info:
          title: Simple API
          version: 1.0.0
          description: A simple API example
        paths:
          /users:
            get:
              summary: Get all users
              description: Returns a list of users
              responses:
                '200':
                  description: A list of users
                  content:
                    application/json:
                      schema:
                        type: array
                        items:
                          $ref: '#/components/schemas/User'
        components:
          schemas:
            User:
              type: object
              properties:
                id:
                  type: integer
                name:
                  type: string
        """
        
        let documentation = try converter.convert(content: yaml, format: Integration.OpenAPIFormat.yaml)
        
        // Basic assertions
        XCTAssertTrue(documentation.contains("Simple API"))
        XCTAssertTrue(documentation.contains("Get all users"))
        XCTAssertTrue(documentation.contains("Returns a list of users"))
        XCTAssertTrue(documentation.contains("200 Response"))
    }
    
    func testConvertSimpleJSON() throws {
        let json = """
        {
          "openapi": "3.0.0",
          "info": {
            "title": "Simple API",
            "version": "1.0.0",
            "description": "A simple API example"
          },
          "paths": {
            "/users": {
              "get": {
                "summary": "Get all users",
                "description": "Returns a list of users",
                "responses": {
                  "200": {
                    "description": "A list of users",
                    "content": {
                      "application/json": {
                        "schema": {
                          "type": "array",
                          "items": {
                            "$ref": "#/components/schemas/User"
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "components": {
            "schemas": {
              "User": {
                "type": "object",
                "properties": {
                  "id": {
                    "type": "integer"
                  },
                  "name": {
                    "type": "string"
                  }
                }
              }
            }
          }
        }
        """
        
        let documentation = try converter.convert(content: json, format: Integration.OpenAPIFormat.json)
        
        // Basic assertions
        XCTAssertTrue(documentation.contains("Simple API"))
        XCTAssertTrue(documentation.contains("Get all users"))
        XCTAssertTrue(documentation.contains("Returns a list of users"))
        XCTAssertTrue(documentation.contains("200 Response"))
    }
    
    func testInvalidYAML() {
        let invalidYAML = """
        openapi: 3.0.0
        info:
          title: Simple API
          version: 1.0.0
        paths:
          /users:
            get:
              responses:
                '200':
                  description: A list of users
        """
        
        XCTAssertThrowsError(try converter.convert(content: invalidYAML, format: Integration.OpenAPIFormat.yaml)) { error in
            XCTAssertTrue(error is OpenAPI.ParserError)
        }
    }
    
    func testInvalidJSON() {
        let invalidJSON = """
        {
          "openapi": "3.0.0",
          "info": {
            "title": "Simple API",
            "version": "1.0.0"
          },
          "paths": {
            "/users": {
              "get": {
                "responses": {
                  "200": {
                    "description": "A list of users"
                  }
                }
              }
            }
          }
        }
        """
        
        XCTAssertThrowsError(try converter.convert(content: invalidJSON, format: Integration.OpenAPIFormat.json)) { error in
            XCTAssertTrue(error is OpenAPI.ParserError)
        }
    }
    
    func testUnsupportedFileType() {
        let fileURL = URL(fileURLWithPath: "test.txt")
        XCTAssertThrowsError(try converter.convert(fileURL: fileURL)) { error in
            XCTAssertTrue(error is Integration.ConversionError)
        }
    }
    
    func testConvertSimpleAPI() throws {
        let yaml = """
        openapi: 3.0.0
        info:
          title: Simple API
          version: 1.0.0
        paths:
          /users:
            get:
              summary: Get all users
              responses:
                '200':
                  description: A list of users
                  content:
                    application/json:
                      schema:
                        type: array
                        items:
                          type: object
                          properties:
                            id:
                              type: integer
                            name:
                              type: string
        """
        
        let output = try converter.convert(content: yaml, format: Integration.OpenAPIFormat.yaml)
        
        XCTAssertTrue(output.contains("Simple API"))
        XCTAssertTrue(output.contains("Get all users"))
        XCTAssertTrue(output.contains("A list of users"))
    }
    
    func testConvertComplexAPI() throws {
        let yaml = """
        openapi: 3.0.0
        info:
          title: Complex API
          version: 1.0.0
          description: A complex API with multiple endpoints
        paths:
          /users:
            get:
              summary: Get all users
              parameters:
                - name: limit
                  in: query
                  schema:
                    type: integer
              responses:
                '200':
                  description: A list of users
                  content:
                    application/json:
                      schema:
                        type: array
                        items:
                          $ref: '#/components/schemas/User'
            post:
              summary: Create a user
              requestBody:
                required: true
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/User'
              responses:
                '201':
                  description: User created
        components:
          schemas:
            User:
              type: object
              properties:
                id:
                  type: integer
                name:
                  type: string
                email:
                  type: string
                  format: email
        """
        
        let output = try converter.convert(content: yaml, format: Integration.OpenAPIFormat.yaml)
        
        XCTAssertTrue(output.contains("Complex API"))
        XCTAssertTrue(output.contains("Get all users"))
        XCTAssertTrue(output.contains("Create a user"))
        XCTAssertTrue(output.contains("User"))
        XCTAssertTrue(output.contains("id"))
        XCTAssertTrue(output.contains("name"))
        XCTAssertTrue(output.contains("email"))
    }
} 
